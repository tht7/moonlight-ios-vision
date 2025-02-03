//
//  UIKitStreamView.swift
//  Moonlight Vision
//
//  Created by Alex Haugland on 1/27/24.
//  Copyright © 2024 Moonlight Game Streaming Project. All rights reserved.
//

import SwiftUI

struct UIKitStreamView: View {
    @Binding var streamConfig: StreamConfiguration

    var body: some View {
        _UIKitStreamView(streamConfig: $streamConfig)
            .ornament(attachmentAnchor: .scene(.top), contentAlignment: .bottom) {
                StreamControls(horizontal: true, streamConfig: $streamConfig) {
                    Button {
                        applyAspectRatioLock(streamConfig: streamConfig) // Call aspect ratio lock function
                    } label: {
                        Label {
                            Text("Fix Aspect Ratio")
                        } icon: {
                            Image(systemName: "aspectratio")
                        }
                    }
                }
            }
    }
}

struct _UIKitStreamView: UIViewControllerRepresentable {
    typealias UIViewControllerType = StreamFrameViewController

    @Binding var streamConfig: StreamConfiguration
    let controllerReference = Reference<UIViewControllerType>()

    func makeUIViewController(context: Context) -> UIViewControllerType {
        let streamView = StreamFrameViewController()
        streamView.streamConfig = streamConfig
        controllerReference.object = streamView
        return streamView
    }

    func updateUIViewController(_ viewController: UIViewControllerType, context: Context) {
        viewController.streamConfig = streamConfig // Ensure streamConfig updates
        controllerReference.object = viewController
    }
}

class Reference<T: AnyObject> {
    weak var object: T?
}

// MARK: - Helper Functions

func applyAspectRatioLock(streamConfig: StreamConfiguration) {
    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
        print("Could not get window scene to apply aspect ratio lock.")
        return
    }

    let streamWidth = CGFloat(streamConfig.width)
    let streamHeight = CGFloat(streamConfig.height)
    let streamAspectRatio = streamWidth / streamHeight

    print("Applying Aspect Ratio Lock - Stream Width: \(streamWidth), Stream Height: \(streamHeight), Stream AR: \(streamAspectRatio)")

    let maxWidth: CGFloat = 2000 // Increased maxWidth for potentially larger screens
    var desiredSize = CGSize.zero

    for desiredWidthInt in (1...Int(maxWidth)).reversed() {
        let desiredWidth = CGFloat(desiredWidthInt)
        let desiredHeightFloat = desiredWidth / streamAspectRatio
        let desiredHeightInt = Int(round(desiredHeightFloat))

        if desiredHeightInt > 0 {
            desiredSize = CGSize(width: desiredWidth, height: CGFloat(desiredHeightInt))
            print("Calculated Desired Size - Width: \(desiredSize.width), Height: \(desiredSize.height)")
            break
        }
    }

    let geometryRequest = UIWindowScene.GeometryPreferences.Vision(
        size: desiredSize,
        resizingRestrictions: .uniform
    )

    print("Applying Geometry Request for Aspect Ratio Lock.")

    // Apply to the first window of the scene, which is typically the main window.
    if let window = windowScene.windows.first {
        print("Applying to the first window in the scene.")

        print("Window Information Before Request:")
        let windowBounds = window.bounds
        let windowWidth = windowBounds.width
        let windowHeight = windowBounds.height
        let windowAspectRatio = windowWidth / windowHeight
        let identifier = window.accessibilityIdentifier ?? "nil"
        let rootViewControllerClassName = String(describing: window.rootViewController?.classForCoder)

        print("\nWindow Information (Before Geometry Request):")
        print("Window Width: \(windowWidth)")
        print("Window Height: \(windowHeight)")
        print("Window Aspect Ratio: \(windowAspectRatio)")
        print("Window Accessibility Identifier: \(identifier)")
        print("Window Root View Controller Class: \(rootViewControllerClassName)")

        windowScene.requestGeometryUpdate(geometryRequest)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { // Short delay for logging
            print("\nWindow Information After Request:")
            let updatedBounds = window.bounds
            let updatedWidth = updatedBounds.width
            let updatedHeight = updatedBounds.height
            let updatedAspectRatio = updatedWidth / updatedHeight
            let identifier = window.accessibilityIdentifier ?? "nil"
            let rootViewControllerClassName = String(describing: window.rootViewController?.classForCoder)

            print("\nWindow Size (After Delay):")
            print("Updated Window Width: \(updatedWidth)")
            print("Updated Window Height: \(updatedHeight)")
            print("Updated Aspect Ratio: \(updatedAspectRatio)")
            print("Window Accessibility Identifier: \(identifier)")
            print("Window Root View Controller Class: \(rootViewControllerClassName)")
        }


    } else {
        print("No window found in the scene to apply aspect ratio lock.")
    }
}
