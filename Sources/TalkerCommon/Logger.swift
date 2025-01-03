//
//  LoggerExtensions.swift
//  MyCookBook
//
//  Created by feichao on 2022/9/20.
//

import Foundation
import Puppy
import ZIPFoundation

private final class MyLogger: Sendable {
    static let shared = MyLogger(
        logDir: URL.documentsDirectory.appending(path: "logs"))

    let logger: Puppy
    let logDir: URL

    init(logDir: URL) {
        self.logDir = logDir
        logger = try! Self.initLogger(logDir: logDir)
    }

    static func initLogger(logDir: URL) throws -> Puppy {
        // get bundle id
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "default"
        let console = OSLogger(bundleIdentifier, logFormat: LogFormatter())
        try FileManager.default.createDirectory(at: logDir, withIntermediateDirectories: true)
        let fileURL = logDir.appending(path: "\(bundleIdentifier).log").absoluteURL
        print("log path: ", fileURL)
        let rotationConfig = RotationConfig(
            suffixExtension: .date_uuid,
            maxFileSize: 10 * 1024 * 1024,
            maxArchivedFilesCount: 10)
        let fileRotation = try FileRotationLogger(
            "io.allsunday.AiTalker.filerotation",
            logFormat: LogFormatter(),
            fileURL: fileURL,
            rotationConfig: rotationConfig,
            delegate: nil)

        var log = Puppy()
        log.add(console)
        log.add(fileRotation)
        return log
    }

    func exportLogs() async -> URL {
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

public func exportLogs() async -> URL {
    return await MyLogger.shared.exportLogs()
}

public func debugLog(
    _ items: Any...,
    file: String = #file, line: Int = #line, column: Int = #column, function: String = #function,
    separator: String = " ",
    terminator: String = "\n"
) {
    MyLogger.shared.log(
        items, logLevel: .debug, file: file, line: line, column: column, function: function,
        separator: separator, terminator: terminator)
}

public func errorLog(
    _ items: Any...,
    file: String = #file, line: Int = #line, column: Int = #column, function: String = #function,
    separator: String = " ",
    terminator: String = "\n"
) {
    MyLogger.shared.log(
        items, logLevel: .error, file: file, line: line, column: column, function: function,
        separator: separator, terminator: terminator)
}

@discardableResult
public func infoLog(
    _ items: Any...,
    file: String = #file, line: Int = #line, column: Int = #column, function: String = #function,
    separator: String = " ",
    terminator: String = "\n"
) {
    MyLogger.shared.log(
        items, logLevel: .info, file: file, line: line, column: column, function: function,
        separator: separator, terminator: terminator)
}
