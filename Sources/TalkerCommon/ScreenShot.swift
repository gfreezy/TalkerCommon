//
//  File.swift
//  
//
//  Created by feichao on 2024/7/15.
//

import UIKit


public func captureScreenShot() -> UIImage? {
    if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene, let window = scene.windows.first {
        UIGraphicsBeginImageContextWithOptions(window.frame.size, false, UIScreen.main.scale)
        window.drawHierarchy(in: window.frame, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    return nil
}
