import SwiftUI
import UIKit

@MainActor
extension CADisplayLink {
    public static func timestamps() -> AsyncStream<Timestamps> {
        AsyncStream { continuation in
            let displayLink = DisplayLink { displayLink in
                continuation.yield(.init(displayLink: displayLink))
            }

            continuation.onTermination = { _ in
                Task { await displayLink.stop() }
            }
        }
    }
}

extension CADisplayLink {
    public struct Timestamps: Sendable {
        public let timestamp: CFTimeInterval
        public let targetTimestamp: CFTimeInterval

        init(displayLink: CADisplayLink) {
            timestamp = displayLink.timestamp
            targetTimestamp = displayLink.targetTimestamp
        }
    }
}

// There is no need to expose this, so let's put it in a private extension

private extension CADisplayLink {
    @MainActor
    private class DisplayLink: NSObject {
        private var displayLink: CADisplayLink!
        private let handler: (CADisplayLink) -> Void

        init(mode: RunLoop.Mode = .default, handler: @escaping (CADisplayLink) -> Void) {
            self.handler = handler
            super.init()

            displayLink = CADisplayLink(target: self, selector: #selector(handle(displayLink:)))
            displayLink.add(to: .main, forMode: mode)
        }

        func stop() {
            displayLink.invalidate()
        }

        @objc func handle(displayLink: CADisplayLink) {
            handler(displayLink)
        }
    }
}
