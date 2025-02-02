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
                    Button { // New Aspect Ratio Button
                        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
                            print("Could not get window scene")
                            return
                        }

                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { // Reduced delay for button press
                            let streamWidth = CGFloat(streamConfig.width)
                            let streamHeight = CGFloat(streamConfig.height)
                            let streamAspectRatio = streamWidth / streamHeight

                            print("Stream Width: \(streamWidth)")
                            print("Stream Height: \(streamHeight)")
                            print("Stream AR: \(streamAspectRatio)")

                            let maxWidth: CGFloat = 2800
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

                            print("Applying Geometry Request to ALL windows in the scene:")

                            for (index, window) in windowScene.windows.enumerated() {
                                let windowBounds = window.bounds
                                let windowWidth = windowBounds.width
                                let windowHeight = windowBounds.height
                                let windowAspectRatio = windowWidth / windowHeight

                                print("\nWindow \(index + 1) Size (Before Geometry Request):")
                                print("Window Width: \(windowWidth)")
                                print("Window Height: \(windowHeight)")
                                print("Window Aspect Ratio: \(windowAspectRatio)")


                                windowScene.requestGeometryUpdate(geometryRequest)

                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { // Reduced delay for faster feedback
                                    let currentWindow = window
                                    let updatedBounds = currentWindow.bounds
                                    let updatedWidth = updatedBounds.width
                                    let updatedHeight = updatedBounds.height
                                    let updatedAspectRatio = updatedWidth / updatedHeight
                                    print("\nWindow \(index + 1) Size (After Delay):")
                                    print("Updated Window Width: \(updatedWidth)")
                                    print("Updated Window Height: \(updatedHeight)")
                                    print("Updated Window Aspect Ratio: \(updatedAspectRatio)")
                                }
                            }
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
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
                let geometryRequest = UIWindowScene.GeometryPreferences.Vision(resizingRestrictions: .uniform)
                windowScene.requestGeometryUpdate(geometryRequest)
            }
            .onDisappear {
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
                let geometryRequest = UIWindowScene.GeometryPreferences.Vision(resizingRestrictions: .freeform)
                windowScene.requestGeometryUpdate(geometryRequest)
//                        pushWindow(id: "mainView")
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
        controllerReference.object = viewController
    }
}

class Reference<T: AnyObject> {
    weak var object: T?
}

//#Preview {
////    StreamView(streamConfig: StreamConfiguration())
//}
