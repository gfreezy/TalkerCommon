//
//  File.swift
//
//
//  Created by feichao on 2024/6/26.
//

import Foundation

public struct TalkerError: LocalizedError {
    /// A localized message describing what error occurred.
    public var errorDescription: String?

    public let file: String
    public let line: Int
    public let column: Int

    public init(
        _ errorDescription: String? = nil,
        file: String = #file, line: Int = #line, column: Int = #column
    ) {
        self.errorDescription = errorDescription
        self.file = file
        self.line = line
        self.column = column
    }
}
