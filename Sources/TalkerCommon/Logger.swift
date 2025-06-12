//
//  LoggerExtensions.swift
//  MyCookBook
//
//  Created by feichao on 2022/9/20.
//

import Foundation
import Puppy
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
