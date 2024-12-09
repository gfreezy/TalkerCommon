//
//  Analytics.swift
//  TalkerCommon
//
//  Created by feichao on 2024/8/20.
//

import Foundation
import OSLog
import StoreKit

public protocol AnalyticsEvent {
    func toPlatformEvent() -> PlatformEvent
}

/// An event that can be tracked an analytics platform
public struct PlatformEvent: AnalyticsEvent {
    /// The name of the event used for tracking
    public let name: String

    /// The properties dictionary associated with the event
    public let properties: [String: Any]

    public init(name: String, properties: [String: Any] = [:]) {
        self.name = name
        self.properties = properties
    }

    public func toPlatformEvent() -> PlatformEvent {
        self
    }
}

public protocol AnalyticsService {
    func track(_ event: any AnalyticsEvent)
}

/// A builder resulting in an array of analytics events
@resultBuilder public struct AnalyticsEventBuilder {

    /// Return an array of analytics events given a closure containing statements of analytics events.
    public static func buildBlock(_ events: any AnalyticsEvent...) -> [any AnalyticsEvent] {
        events
    }
}

extension AnalyticsService {
    public func track(_ event: (String, [String: Any])) {
        track(PlatformEvent(name: event.0, properties: event.1))
    }

    public func track(_ event: String, properties: [String: Any] = [:]) {
        track(PlatformEvent(name: event, properties: properties))
    }

    public func track(@AnalyticsEventBuilder _ events: () -> [any AnalyticsEvent]) {
        let events = events()
        events.forEach { event in
            track(event)
        }
    }
}

open class BaseOneAnalytics: AnalyticsService {
    let presetProperties: Lock<[String: Any]> = Lock([:])

    public init() {

    }

    public func setPresetProperty(key: String, value: Any) {
        presetProperties.withLock { v in
            v[key] = value
        }
    }
    
    open func trackPurchase(_ transaction: Transaction, customerInfo: [String: Any]? = nil) {
        
    }
    
    open func trackPageView(pageName: String, properties: [String: Any] = [:]) {
        
    }
    
    open func track(_ event: any AnalyticsEvent) {
        
    }

    public func track(_ event: String, properties: [String: Any] = [:]) {
        track(PlatformEvent(name: event, properties: properties))
    }
}
