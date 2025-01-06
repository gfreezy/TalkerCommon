//
//  ErrorUtils.swift
//  TalkerCommon
//
//  Created by feichao on 2024/12/15.
//

import Combine
import Foundation

public struct ErrorMsg: Identifiable, Equatable, Sendable {
    public var id: String {
        UUID().uuidString
    }

    public let msg: String
    public let file: String
    public let fileId: String
    public let line: Int
    public let column: Int

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
}

public final class ErrorNotifier: @unchecked Sendable {
    public static let shared = ErrorNotifier()

    public let errorMsgPublisher = PassthroughSubject<ErrorMsg, Never>()

    private init() {}

    public static func postErrorMsg(
        _ errMsg: String, file: String = #file, line: Int = #line, column: Int = #column,
        fileId: String = #fileID
    ) {
        errorLog(errMsg, file: file, line: line, column: column)
        DispatchQueue.main.async {
            Self.shared.errorMsgPublisher.send(
                ErrorMsg(msg: errMsg, file: file, fileId: fileId, line: line, column: column))
        }
    }

    public static func postMessageError(
        _ error: TalkerError
    ) {
        postErrorMsg(
            error.localizedDescription, file: error.file, line: error.line, column: error.column)
    }
}

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
            error.localizedDescription, file: file, line: line, column: column)
        throw error
    }
}

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
        errorLog(error.localizedDescription, file: file, line: line, column: column)
        throw error
    } catch {
        ErrorNotifier.postErrorMsg(
            error.localizedDescription, file: file, line: line, column: column)
        throw error
    }
}

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

@discardableResult
public func logError<T>(
    closure: () throws -> T, file: String = #file, line: Int = #line, column: Int = #column
) throws -> T {
    do {
        return try closure()
    } catch let error as TalkerError {
        errorLog(
            error.localizedDescription, file: error.file, line: error.line, column: error.column)
        throw error
    } catch {
        errorLog(error.localizedDescription, file: file, line: line, column: column)
        throw error
    }
}

@discardableResult
public func logError<T: Sendable>(
    closure: @isolated(any) () async throws -> T, file: String = #file, line: Int = #line,
    column: Int = #column, isolation: isolated (any Actor)? = #isolation
) async throws -> T {
    do {
        return try await closure()
    } catch let error as TalkerError {
        errorLog(
            error.localizedDescription, file: error.file, line: error.line, column: error.column)
        throw error
    } catch {
        errorLog(error.localizedDescription, file: file, line: line, column: column)
        throw error
    }
}

public func captureError(
    closure: () throws -> Void, file: String = #file, line: Int = #line, column: Int = #column
) {
    do {
        try closure()
    } catch let error as TalkerError {
        errorLog(
            error.localizedDescription, file: error.file, line: error.line, column: error.column)
    } catch {
        errorLog(error.localizedDescription, file: file, line: line, column: column)
    }
}

public func captureError(
    closure: @isolated(any) () async throws -> Void, file: String = #file, line: Int = #line,
    column: Int = #column, isolation: isolated (any Actor)? = #isolation
) async {
    do {
        try await closure()
    } catch let error as TalkerError {
        errorLog(
            error.localizedDescription, file: error.file, line: error.line, column: error.column)
    } catch {
        errorLog(error.localizedDescription, file: file, line: line, column: column)
    }
}

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
