//
//  DateUtils.swift
//  TalkerCommon
//
//  Created by feichao on 2024/12/15.
//
import Foundation

extension Date {
    public func isToday() -> Bool {
        return Calendar.current.isDateInToday(self)
    }

    public static func today() -> Date {
        return Date().startOfDay()
    }

    public func startOfDay() -> Date {
        return Calendar.current.startOfDay(for: self)
    }
}
