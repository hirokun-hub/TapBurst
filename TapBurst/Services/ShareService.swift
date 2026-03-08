import Foundation
import UIKit

@MainActor
final class ShareService {
    private static let tempFilePrefix = "TapBurst_"
    private static let tempFileExtension = "jpg"
    private static let jpegCompressionQuality: CGFloat = 0.85

    func shareScorecard(image: UIImage, score: Int, from presentingViewController: UIViewController? = nil) {
        guard let presentingViewController = presentingViewController ?? Self.topViewController(),
              let imageData = image.jpegData(compressionQuality: Self.jpegCompressionQuality) else {
            return
        }

        do {
            try? cleanupTemporaryScorecards()
            let fileURL = try writeTemporaryScorecard(imageData: imageData, score: score)
            let activityViewController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)

            if let popoverPresentationController = activityViewController.popoverPresentationController {
                popoverPresentationController.sourceView = presentingViewController.view
                popoverPresentationController.sourceRect = CGRect(
                    x: presentingViewController.view.bounds.midX,
                    y: presentingViewController.view.bounds.midY,
                    width: 1,
                    height: 1
                )
            }

            presentingViewController.present(activityViewController, animated: true)
        } catch {
            assertionFailure("Failed to prepare scorecard share file: \(error)")
        }
    }

    private func cleanupTemporaryScorecards() throws {
        let tempDirectoryURL = FileManager.default.temporaryDirectory
        let existingFiles = try FileManager.default.contentsOfDirectory(
            at: tempDirectoryURL,
            includingPropertiesForKeys: nil
        )

        for fileURL in existingFiles where fileURL.lastPathComponent.hasPrefix(Self.tempFilePrefix) && fileURL.pathExtension == Self.tempFileExtension {
            try? FileManager.default.removeItem(at: fileURL)
        }
    }

    private func writeTemporaryScorecard(imageData: Data, score: Int) throws -> URL {
        let filename = "\(Self.tempFilePrefix)\(score)_\(UUID().uuidString).\(Self.tempFileExtension)"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try imageData.write(to: fileURL, options: .atomic)
        return fileURL
    }

    private static func topViewController(base: UIViewController? = nil) -> UIViewController? {
        let rootViewController: UIViewController?
        if let base {
            rootViewController = base
        } else {
            let windowScenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            let keyWindow = windowScenes
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }
            rootViewController = keyWindow?.rootViewController
        }

        guard let rootViewController else {
            return nil
        }

        if let navigationController = rootViewController as? UINavigationController {
            return topViewController(base: navigationController.visibleViewController)
        }
        if let tabBarController = rootViewController as? UITabBarController {
            return topViewController(base: tabBarController.selectedViewController)
        }
        if let presentedViewController = rootViewController.presentedViewController {
            return topViewController(base: presentedViewController)
        }
        return rootViewController
    }
}
