//
//  Color.swift
//  TalkerCommon
//
//  Created by feichao on 2024/8/21.
//
import SwiftUI


extension Color {
    public func toHex() -> String {
        let uic = UIColor(self)
        return uic.toHex()
    }
    
    public init(hex: Int) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255,
            opacity: 1
        )
    }
    
    public init(hex: String) {
        var hex = hex
        if hex.hasPrefix("#") {
            hex.removeFirst()
        }
        if hex.count == 6 {
            self.init(hex: Int(hex, radix: 16) ?? 0)
        } else {
            self.init(hex: 0)
        }
    }
    
    public var uiColor: UIColor {
        UIColor(self)
    }
    
    public static let neutral50 = Color(hex: "#fafafa")
    public static let neutral100 = Color(hex: "#f5f5f5")
    public static let neutral200 = Color(hex: "#e5e5e5")
    public static let neutral300 = Color(hex: "#d4d4d4")
    public static let neutral400 = Color(hex: "#a3a3a3")
    public static let neutral500 = Color(hex: "#737373")
    public static let neutral600 = Color(hex: "#525252")
    public static let neutral700 = Color(hex: "#404040")
    public static let neutral800 = Color(hex: "#262626")
    public static let neutral900 = Color(hex: "#171717")
    public static let neutral950 = Color(hex: "#0a0a0a")
}


extension UIColor {
    public convenience init(hex: Int) {
        self.init(
            red: CGFloat((hex >> 16) & 0xff) / 255,
            green: CGFloat((hex >> 8) & 0xff) / 255,
            blue: CGFloat(hex & 0xff) / 255,
            alpha: 1
        )
    }
    
    public convenience init(hex: String) {
        var hex = hex
        if hex.hasPrefix("#") {
            hex.removeFirst()
        }
        if hex.count == 6 {
            self.init(hex: Int(hex, radix: 16) ?? 0)
        } else {
            self.init(hex: 0)
        }
    }
    
    public func toHex() -> String {
        guard let components = cgColor.components, components.count >= 3 else {
            return "#000000"
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        var a = Float(1.0)
        
        if components.count >= 4 {
            a = Float(components[3])
        }
        
        if a != Float(1.0) {
            return String(format: "#%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lroundf(a * 255))
        } else {
            return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        }
    }

}
