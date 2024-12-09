import SwiftUI

@MainActor
public func presentActivityController(items: [Any]) {
    let activityVC = UIActivityViewController(
        activityItems: items, applicationActivities: nil)

    // Get a scene that's showing (iPad can have many instances of the same app, some in the background)
    let activeScene =
        UIApplication.shared.connectedScenes.first(where: {
            $0.activationState == .foregroundActive
        }) as? UIWindowScene

    let rootViewController = (activeScene?.windows ?? []).first(where: { $0.isKeyWindow })?
        .rootViewController

    // iPad stuff (fine to leave this in for all iOS devices, it will be effectively ignored when not needed)
    activityVC.popoverPresentationController?.sourceView = rootViewController?.view
    activityVC.popoverPresentationController?.sourceRect = .zero

    rootViewController?.present(activityVC, animated: true, completion: nil)
}
