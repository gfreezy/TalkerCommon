//
//  File.swift
//  
//
//  Created by feichao on 2024/5/23.
//

import Foundation

public func isInPreview() -> Bool {
#if !DEBUG
    false
#else
    ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
#endif
}


public func kebabCaseToCamelCase(_ input: String) -> String {
    let components = input.components(separatedBy: "-")
    var camelCaseString = ""
    
    for (index, component) in components.enumerated() {
        if index == 0 {
            camelCaseString += component.lowercased()
        } else {
            camelCaseString += component.capitalized
        }
    }
    
    return camelCaseString
}


public func formatLocalized(_ format: String, _ arguments: CVarArg...) -> String {
    let localizedFormat = NSLocalizedString(format, comment: "")
    return String.localizedStringWithFormat(localizedFormat, arguments)
}
