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

    /// A localized message describing the reason for the failure.
    public var failureReason: String?

    /// A localized message describing how one might recover from the failure.
    public var recoverySuggestion: String?

    /// A localized message providing "help" text if the user requests help.
    public var helpAnchor: String?
    
    let file: String
    let line: Int
    let column: Int

    public init(_ errorDescription: String? = nil, failureReason: String? = nil, recoverySuggestion: String? = nil, helpAnchor: String? = nil, file: String = #file, line: Int = #line, column: Int = #column) {
        self.errorDescription = "\(file):\(line):\(column)\n\(errorDescription ?? "")"
        self.failureReason = failureReason
        self.recoverySuggestion = recoverySuggestion
        self.helpAnchor = helpAnchor
        self.file = file
        self.line = line
        self.column = column
    }
}
