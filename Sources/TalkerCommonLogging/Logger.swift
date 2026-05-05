//
//  LoggerExtensions.swift
//  MyCookBook
//
//  Created by feichao on 2022/9/20.
//

import Foundation
import Puppy
import TalkerCommonSync
import ZIPFoundation

fileprivate final class MyLogger: Sendable {
    fileprivate static let shared = Lock(MyLogger(
        logDir: URL.documentsDirectory.appending(path: "logs")
    ))

    private let logger: Puppy
    private let logDir: URL

    fileprivate init(logDir: URL, logLevel: LogLevel = .debug) {
        self.logDir = logDir
        logger = try! Self.setupLogger(logDir: logDir, logLevel: logLevel)
    }

    fileprivate static func setupLogger(logDir: URL, logLevel: LogLevel) throws -> Puppy {
        // get bundle id
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "default"
        let console = OSLogger(bundleIdentifier, logLevel: logLevel, logFormat: LogFormatter())
        try FileManager.default.createDirectory(at: logDir, withIntermediateDirectories: true)
        let fileURL = logDir.appending(path: "\(bundleIdentifier).log").absoluteURL
        print("log path: ", fileURL)
        let rotationConfig = RotationConfig(
            suffixExtension: .date_uuid,
            maxFileSize: 10 * 1024 * 1024,
            maxArchivedFilesCount: 10)
        let fileRotation = try FileRotationLogger(
            "io.allsunday.AiTalker.filerotation",
            logLevel: logLevel,
            logFormat: LogFormatter(),
            fileURL: fileURL,
            rotationConfig: rotationConfig,
            delegate: nil)

        var log = Puppy()
        log.add(console)
        log.add(fileRotation)
        return log
    }
    
    fileprivate static func initLogger(logDir: URL = URL.documentsDirectory.appending(path: "logs"), logLevel: LogLevel = .debug) {
        Self.shared.setValue(MyLogger(
            logDir: logDir, logLevel: logLevel
        ))
    }

    fileprivate func exportLogs() async -> URL {
        let destinationURL = URL.cachesDirectory.appending(path: "log.zip")
        try? FileManager.default.removeItem(at: destinationURL)
        let t = Task.detached {
            try FileManager.default.zipItem(
                at: self.logDir, to: destinationURL, compressionMethod: .deflate)
        }
        do {
            try await t.value
        } catch {
            errorLog("Creation of ZIP archive failed with error:\(error)")
        }
        return destinationURL
    }

    fileprivate func log(
        _ items: Any...,
        logLevel: LogLevel = .debug,
        file: String = #file, line: Int = #line, column: Int = #column,
        function: String = #function,
        separator: String = " ",
        terminator: String = "\n"
    ) {
        let emojis =
            "🍏 🍎 🍐 🍊 🍋 🍌 🍉 🍇 🍓 🫐 🍈 🍒 🍑 🥭 🍍 🥥 🥝 🍅 🍆 🥑 🥦 🥬 🥒 🌶 🫑 🌽 🥕 🫒 🧄 🧅 🥔 🍠 🥐 🥯 🍞 🥖 🥨 🧀 🥚 🍳 🧈 🥞 🧇 🥓 🥩 🍗 🍖 🦴 🌭 🍔 🍟 🍕 🫓 🥪 🥙 🧆 🌮 🌯 🫔 🥗 🥘 🫕 🥫 🍝 🍜 🍲 🍛 🍣 🍱 🥟 🦪 🍤 🍙 🍚 🍘 🍥 🥠 🥮 🍢 🍡 🍧 🍨 🍦 🥧 🧁 🍰 🎂 🍮 🍭 🍬 🍫 🍿 🍩 🍪 🌰 🥜 🍯 🥛 🍼 🫖 ☕️ 🍵 🧃 🥤 🧋 🍶 🍺 🍻 🥂 🍷 🥃 🍸 🍹 🧉 🍾 🧊 🥄 🍴 🍽 🥣 🥡 🥢 🧂"
            .split(separator: " ")
        let prefix = emojis.randomElement()!
        let prefixMsg = "\(prefix)\(file.split(separator: "/").last ?? ""):\(line):\(column) 👉"
        var msg = ""
        print(items, separator: separator, terminator: terminator, to: &msg)
        let fullMsg = "\(Date()) \(logLevel) \(prefixMsg) \(msg)"
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            print(fullMsg)
        }
        logger.logMessage(
            logLevel, message: msg, tag: "", function: function, file: file, line: UInt(line))
    }
}

private struct LogFormatter: LogFormattable {
    private let dateFormat = DateFormatter()

    init() {
        dateFormat.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZ"
    }

    func formatMessage(
        _ level: LogLevel, message: String, tag: String, function: String,
        file: String, line: UInt, swiftLogInfo: [String: String],
        label: String, date: Date, threadID: UInt64
    ) -> String {
        let date = dateFormatter(date, withFormatter: dateFormat)
        let fileName = fileName(file)
        return "[\(date)\(level.emoji)\(level)]🧵\(threadID)✏️\(fileName)#L\(line) 👉 \(message)"
    }
}

public func setupLogger(
    logDir: URL = URL.documentsDirectory.appending(path: "logs"),
    logLevel: LogLevel = .debug
) {
    MyLogger.initLogger(logDir: logDir, logLevel: logLevel)
}


public func exportLogs() async -> URL {
    return await MyLogger.shared.value().exportLogs()
}

public func debugLog(
    _ items: Any...,
    file: String = #file, line: Int = #line, column: Int = #column, function: String = #function,
    separator: String = " ",
    terminator: String = "\n"
) {
    MyLogger.shared.value().log(
        items, logLevel: .debug, file: file, line: line, column: column, function: function,
        separator: separator, terminator: terminator)
}

public func errorLog(
    _ items: Any...,
    file: String = #file, line: Int = #line, column: Int = #column, function: String = #function,
    separator: String = " ",
    terminator: String = "\n"
) {
    MyLogger.shared.value().log(
        items, logLevel: .error, file: file, line: line, column: column, function: function,
        separator: separator, terminator: terminator)
}

public func infoLog(
    _ items: Any...,
    file: String = #file, line: Int = #line, column: Int = #column, function: String = #function,
    separator: String = " ",
    terminator: String = "\n"
) {
    MyLogger.shared.value().log(
        items, logLevel: .info, file: file, line: line, column: column, function: function,
        separator: separator, terminator: terminator)
}

private func formatElapsed(_ d: Duration) -> String {
    let (seconds, attos) = d.components
    let ms = Double(seconds) * 1000 + Double(attos) / 1_000_000_000_000_000
    if ms < 1 {
        return String(format: "%.3fms", ms)
    } else if ms < 1000 {
        return String(format: "%.1fms", ms)
    } else {
        return String(format: "%.2fs", ms / 1000)
    }
}

@discardableResult
public func timeLog<T>(
    _ label: String,
    logLevel: LogLevel = .debug,
    file: String = #file, line: Int = #line, column: Int = #column, function: String = #function,
    _ block: () throws -> T
) rethrows -> T {
    let start = ContinuousClock.now
    defer {
        let elapsed = ContinuousClock.now - start
        MyLogger.shared.value().log(
            "\(label) ⏱ \(formatElapsed(elapsed))",
            logLevel: logLevel,
            file: file, line: line, column: column, function: function)
    }
    return try block()
}

@discardableResult
public func timeLog<T>(
    _ label: String,
    logLevel: LogLevel = .debug,
    file: String = #file, line: Int = #line, column: Int = #column, function: String = #function,
    _ block: () async throws -> T
) async rethrows -> T {
    let start = ContinuousClock.now
    defer {
        let elapsed = ContinuousClock.now - start
        MyLogger.shared.value().log(
            "\(label) ⏱ \(formatElapsed(elapsed))",
            logLevel: logLevel,
            file: file, line: line, column: column, function: function)
    }
    return try await block()
}

public final class LogTimer: @unchecked Sendable {
    public let label: String
    public let logLevel: LogLevel
    private let start: ContinuousClock.Instant
    private let _lastLap: Lock<ContinuousClock.Instant>

    public init(_ label: String, logLevel: LogLevel = .debug) {
        self.label = label
        self.logLevel = logLevel
        let now = ContinuousClock.now
        self.start = now
        self._lastLap = Lock(now)
    }

    public func lap(
        _ items: Any...,
        file: String = #file, line: Int = #line, column: Int = #column, function: String = #function,
        separator: String = " ",
        terminator: String = "\n"
    ) {
        let now = ContinuousClock.now
        let sinceLast = _lastLap.withLock { last -> Duration in
            let e = now - last
            last = now
            return e
        }
        let total = now - start
        let prefix = "\(label) ⏱ +\(formatElapsed(sinceLast)) total=\(formatElapsed(total))"
        MyLogger.shared.value().log(
            prefix, items, logLevel: logLevel,
            file: file, line: line, column: column, function: function,
            separator: separator, terminator: terminator)
    }

    public func stop(
        _ items: Any...,
        file: String = #file, line: Int = #line, column: Int = #column, function: String = #function,
        separator: String = " ",
        terminator: String = "\n"
    ) {
        let total = ContinuousClock.now - start
        let prefix = "\(label) ⏱ done \(formatElapsed(total))"
        MyLogger.shared.value().log(
            prefix, items, logLevel: logLevel,
            file: file, line: line, column: column, function: function,
            separator: separator, terminator: terminator)
    }
}
