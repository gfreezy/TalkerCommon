//
//  ErrorUtils.swift
//  TalkerCommon
//
//  Created by feichao on 2024/12/15.
//

import Combine
import Foundation

public struct ErrorMsg: Identifiable, Sendable, Equatable {
    public var id: String {
        UUID().uuidString
    }
    public let error: Error?
    public let msg: String
    public let file: String
    public let fileId: String
    public let line: Int
    public let column: Int

    init(msg: String, error: Error?, file: String, fileId: String, line: Int, column: Int) {
        self.error = error
        self.msg = msg
        self.file = file
        self.fileId = fileId
        self.line = line
        self.column = column
    }

    public var fileName: String {
        URL(fileURLWithPath: file).deletingPathExtension().lastPathComponent
    }

    public var signature: String {
        #if !DEBUG
            //        "\(fileName):\(line):\(column)"
            return Data("\(fileName):\(line)".utf8).base64EncodedString(
                options: .lineLength64Characters)
        #else
            return "\(fileName):\(line):\(column)"
        #endif
    }

    public static func == (lhs: ErrorMsg, rhs: ErrorMsg) -> Bool {
        lhs.msg == rhs.msg && lhs.file == rhs.file && lhs.line == rhs.line && lhs.column == rhs.column
    }
}

public final class ErrorNotifier: @unchecked Sendable {
    public static let shared = ErrorNotifier()

    public let errorMsgPublisher = PassthroughSubject<ErrorMsg, Never>()

    private init() {}

    public static func postErrorMsg(
        _ errMsg: String, error: Error? = nil, file: String = #file, line: Int = #line, column: Int = #column,
        fileId: String = #fileID
    ) {
        errorLog(errMsg, file: file, line: line, column: column)
        DispatchQueue.main.async {
            Self.shared.errorMsgPublisher.send(
                ErrorMsg(msg: errMsg, error: error, file: file, fileId: fileId, line: line, column: column))
        }
    }

    public static func postMessageError(
        _ error: TalkerError
    ) {
        postErrorMsg(
            error.errorDescription ?? "", error: error, file: error.file, line: error.line, column: error.column)
    }
}


/// 不改变函数签名，只打印错误日志。
@discardableResult
public func logError<T>(
    closure: () throws -> T, file: String = #file, line: Int = #line, column: Int = #column
) throws -> T {
    do {
        return try closure()
    } catch let error as TalkerError {
        errorLog(
            String(describing: error), file: error.file, line: error.line, column: error.column)
        throw error
    } catch {
        errorLog(String(describing: error), file: file, line: line, column: column)
        throw error
    }
}

/// 不改变函数签名，只打印错误日志。async 版本
@discardableResult
public func logError<T: Sendable>(
    closure: @isolated(any) () async throws -> T, file: String = #file, line: Int = #line,
    column: Int = #column, isolation: isolated (any Actor)? = #isolation
) async throws -> T {
    do {
        return try await closure()
    } catch let error as TalkerError {
        errorLog(
            String(describing: error), file: error.file, line: error.line, column: error.column)
        throw error
    } catch {
        errorLog(String(describing: error), file: file, line: line, column: column)
        throw error
    }
}

/// 不改变函数签名，报错的时候发一个 toast 消息。
@discardableResult
public func toastError<T>(
    closure: () throws -> T, file: String = #file, line: Int = #line, column: Int = #column
) throws -> T {
    do {
        return try closure()
    } catch let error as TalkerError {
        ErrorNotifier.postMessageError(error)
        throw error
    } catch let error as CancellationError {
        errorLog(String(describing: error), file: file, line: line, column: column)
        throw error
    } catch {
        ErrorNotifier.postErrorMsg(
            String(describing: error), error: error, file: file, line: line, column: column)
        throw error
    }
}

/// 不改变函数签名，报错的时候发一个 toast 消息。async 版本
@discardableResult
public func toastError<T: Sendable>(
    closure: @isolated(any) () async throws -> T, file: String = #file, line: Int = #line,
    column: Int = #column, isolation: isolated (any Actor)? = #isolation
) async throws -> T {
    do {
        return try await closure()
    } catch let error as TalkerError {
        ErrorNotifier.postMessageError(error)
        throw error
    } catch let error as CancellationError {
        throw error
    } catch {
        ErrorNotifier.postErrorMsg(
            String(describing: error), error: error, file: file, line: line, column: column)
        throw error
    }
}

/// 把 (...) throws -> Void 变成 (...) -> Void，并记录错误日志
public func captureError(
    closure: () throws -> Void, file: String = #file, line: Int = #line, column: Int = #column
) {
    do {
        try closure()
    } catch let error as TalkerError {
        errorLog(
            String(describing: error), file: error.file, line: error.line, column: error.column)
    } catch {
        errorLog(String(describing: error), file: file, line: line, column: column)
    }
}

/// 把 (...) async throws -> Void 变成 (...) async -> Void，并记录错误日志。async 版本
public func captureError(
    closure: @isolated(any) () async throws -> Void, file: String = #file, line: Int = #line,
    column: Int = #column, isolation: isolated (any Actor)? = #isolation
) async {
    do {
        try await closure()
    } catch let error as TalkerError {
        errorLog(
            String(describing: error), file: error.file, line: error.line, column: error.column)
    } catch {
        errorLog(String(describing: error), file: file, line: line, column: column)
    }
}

/// 把 (...) async throws -> Void 变成 (...) -> Task<(), Error>，并记录错误日志。返回 Task
@discardableResult
public func taskCaptureError(
    closure: @escaping @isolated(any) () async throws -> Void, file: String = #file,
    line: Int = #line, column: Int = #column, isolation: isolated (any Actor)? = #isolation
) -> Task<(), Error> {
    Task {
        await captureError(
            closure: closure, file: file, line: line, column: column, isolation: isolation)
    }
}


/// 把 (...) async throws -> Void 变成 (...) -> Task<(), Error>，并记录错误日志，发送 toast 消息。返回 Task
@discardableResult
public func taskToastError(
    closure: @escaping @isolated(any) () async throws -> Void,
    file: String = #file, line: Int = #line, column: Int = #column,
    isolation: isolated (any Actor)? = #isolation
) -> Task<(), Error> {
    return Task {
        await toastCaptureError(
            closure: closure, file: file, line: line, column: column, isolation: isolation)
    }
}

/// 把 (...) async throws -> Void 变成 (...) -> Task<(), Error>，并记录错误日志,发送 toast 消息。返回 Task
public func toastCaptureError(
    closure: @escaping @isolated(any) () async throws -> Void, file: String = #file,
    line: Int = #line, column: Int = #column, isolation: isolated (any Actor)? = #isolation
) async {
    do {
        try await toastError(
            closure: {
                try await closure()
            }, file: file, line: line, column: column, isolation: isolation)
    } catch {}
}

/// 把 (...) throws -> Void 变成 (...) -> Task<(), Error>，并记录错误日志,发送 toast 消息。返回 Task
public func toastCaptureError(
    closure: @escaping @isolated(any) () throws -> Void, file: String = #file,
    line: Int = #line, column: Int = #column, isolation: isolated (any Actor)? = #isolation
) async {
    do {
        try await toastError(
            closure: {
                try await closure()
            }, file: file, line: line, column: column, isolation: isolation)
    } catch {}
}


@available(*, deprecated, renamed: "toastCaptureError", message: "Use toastCaptureError instead.")
public func toastErrorNoThrow<T>(
    closure: () throws -> T, file: String = #file, line: Int = #line, column: Int = #column
) {
    do {
        try toastError(
            closure: {
                let _ = try closure()
            }, file: file, line: line, column: column)
    } catch {

    }
}
