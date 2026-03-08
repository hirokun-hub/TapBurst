import Foundation
import Photos
import UIKit

@MainActor
final class ShareService {
    enum PhotoLibraryError: Error {
        case permissionDenied
        case imageEncodingFailed
    }

    private static let tempFilePrefix = "TapBurst_"
    private static let tempFileExtension = "png"

    func shareScorecard(image: UIImage, score: Int, from presentingViewController: UIViewController? = nil) {
        guard let presentingViewController = presentingViewController ?? Self.topViewController(),
              let imageData = image.pngData() else {
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

    func saveToPhotoLibrary(image: UIImage) async throws {
        guard let imageData = image.pngData() else {
            throw PhotoLibraryError.imageEncodingFailed
        }

        let authorizationStatus = await requestPhotoLibraryPermission()
        guard authorizationStatus == .authorized else {
            throw PhotoLibraryError.permissionDenied
        }

        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetCreationRequest.forAsset()
            request.addResource(with: .photo, data: imageData, options: nil)
        }
    }

    func requestPhotoLibraryPermission() async -> PHAuthorizationStatus {
        let currentStatus = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        guard currentStatus == .notDetermined else {
            return currentStatus
        }

        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                continuation.resume(returning: status)
            }
        }
    }

    func presentPhotoLibraryDeniedAlert(from presentingViewController: UIViewController? = nil) {
        guard let presentingViewController = presentingViewController ?? Self.topViewController() else {
            return
        }

        let alertController = UIAlertController(
            title: String(localized: "photo_library.denied_title"),
            message: String(localized: "photo_library.denied_message"),
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: String(localized: "common.cancel"), style: .cancel))
        alertController.addAction(UIAlertAction(title: String(localized: "settings.open"), style: .default) { _ in
            guard let settingsURL = URL(string: UIApplication.openSettingsURLString),
                  UIApplication.shared.canOpenURL(settingsURL) else {
                return
            }
            UIApplication.shared.open(settingsURL)
        })
        presentingViewController.present(alertController, animated: true)
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
