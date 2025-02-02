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

    // Unique identifier for the window associated with this view
    let streamViewWindowIdentifier = "streamViewWindow"

    var body: some View {
        _UIKitStreamView(streamConfig: $streamConfig, windowIdentifier: streamViewWindowIdentifier) // Pass the identifier
            .ornament(attachmentAnchor: .scene(.top), contentAlignment: .bottom) {
                StreamControls(horizontal: true, streamConfig: $streamConfig) {
                    Button { // New Aspect Ratio Button
                        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
                            print("Could not get window scene")
                            return
                        }

                        let streamWidth = CGFloat(streamConfig.width)
                        let streamHeight = CGFloat(streamConfig.height)
                        let streamAspectRatio = streamWidth / streamHeight

                        print("Stream Width: \(streamWidth)")
                        print("Stream Height: \(streamHeight)")
                        print("Stream AR: \(streamAspectRatio)")

                        let maxWidth: CGFloat = 1000
                        var desiredSize = CGSize.zero

                        for desiredWidthInt in (1...Int(maxWidth)).reversed() { // Iterate downwards from maxWidth to 1
                            let desiredWidth = CGFloat(desiredWidthInt)
                            let desiredHeightFloat = desiredWidth / streamAspectRatio
                            let desiredHeightInt = Int(round(desiredHeightFloat))

                            if desiredHeightInt > 0 { // Ensure height is positive
                                desiredSize = CGSize(width: desiredWidth, height: CGFloat(desiredHeightInt))
                                print("Calculated Desired Size - Width: \(desiredSize.width), Height: \(desiredSize.height)")
                                break // Found the largest width with integer height, exit loop
                            }
                        }


                        let geometryRequest = UIWindowScene.GeometryPreferences.Vision(
                            size: desiredSize,
                            resizingRestrictions: .uniform
                        )

                        print("Applying Geometry Request to window with identifier '\(streamViewWindowIdentifier)':") // Updated log

                        print("Window Information Before Request:")
                        for (index, window) in windowScene.windows.enumerated() {
                            let windowBounds = window.bounds
                            let windowWidth = windowBounds.width
                            let windowHeight = windowBounds.height
                            let windowAspectRatio = windowWidth / windowHeight
                            let identifier = window.accessibilityIdentifier ?? "nil" // Get identifier safely

                            print("\nWindow \(index + 1) Information (Before Geometry Request):")
                            print("Window Width: \(windowWidth)")
                            print("Window Height: \(windowHeight)")
                            print("Window Aspect Ratio: \(windowAspectRatio)")
                            print("Window Accessibility Identifier: \(identifier)") // Log identifier

                            // Print window view names - keeping debug info for now
                            //print("Window Debug Description: \(window.debugDescription)")
                            //print("Window Description: \(window.description)")
                            //print("Window Class Name: \(window.className)")
                        }

                        // Find the window with our identifier and apply the geometry request
                        if let targetWindow = windowScene.windows.first(where: { $0.accessibilityIdentifier == streamViewWindowIdentifier }) {
                            windowScene.requestGeometryUpdate(geometryRequest) // Request update on the scene, targeting the identified window implicitly

                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { // Reduced delay and moved outside loop, for logging after update
                                print("\nWindow Information After Request:")
                                for (index, window) in windowScene.windows.enumerated() {
                                    let updatedBounds = window.bounds
                                    let updatedWidth = updatedBounds.width
                                    let updatedHeight = updatedBounds.height
                                    let updatedAspectRatio = updatedWidth / updatedHeight
                                    let identifier = window.accessibilityIdentifier ?? "nil" // Get identifier safely

                                    print("\nWindow \(index + 1) Size (After Delay):")
                                    print("Updated Window Width: \(updatedWidth)")
                                    print("Updated Window Height: \(updatedHeight)")
                                    print("Updated Aspect Ratio: \(updatedAspectRatio)")
                                    print("Window Accessibility Identifier: \(identifier)") // Log identifier

                                    // Print window view names - keeping debug info for now
                                    //print("Window Debug Description: \(window.debugDescription)")
                                    //print("Window Description: \(window.description)")
                                    //print("Window Class Name: \(window.id)")
                                }
                            }
                        } else {
                            print("Target window with identifier '\(streamViewWindowIdentifier)' not found in scene's windows.")
                        }


                    } label: {
                        Label {
                            Text("Fix Aspect Ratio")
                            } icon: {
                                Image(systemName: "aspectratio")
                            }
                    }
                }
            }
            .onAppear {
                // Removed onAppear guard line
            }
            .onDisappear {
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
                let geometryRequest = UIWindowScene.GeometryPreferences.Vision(resizingRestrictions: .uniform)
                windowScene.requestGeometryUpdate(geometryRequest)
            }
    }
}
struct _UIKitStreamView: UIViewControllerRepresentable {
    typealias UIViewControllerType = StreamFrameViewController

    @Binding var streamConfig: StreamConfiguration
    let windowIdentifier: String // Receive the identifier

    let controllerReference = Reference<UIViewControllerType>()


    func makeUIViewController(context: Context) -> UIViewControllerType {
        let streamView = StreamFrameViewController()
        streamView.streamConfig = streamConfig
        controllerReference.object = streamView

        // Access the window in the next run loop to ensure it's created
        DispatchQueue.main.async {
            streamView.view.window?.accessibilityIdentifier = windowIdentifier // Set the identifier
        }

        return streamView
    }

    func updateUIViewController(_ viewController: UIViewControllerType, context: Context) {
        controllerReference.object = viewController
    }
}

class Reference<T: AnyObject> {
    weak var object: T?
}
