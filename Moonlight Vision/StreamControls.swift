//
//  StreamControls.swift
//  Moonlight
//
//  Created by tht7 on 24/01/2025.
//  Copyright © 2025 Moonlight Game Streaming Project. All rights reserved.
//

import SwiftUI

struct StreamControls<Additions: View>: View {
    @EnvironmentObject private var viewModel: MainViewModel
    let horizontal: Bool
    @Binding var streamConfig: StreamConfiguration

    @ViewBuilder var additions: () -> Additions

    var body: some View {
        Group {
            if (horizontal) {
                HStack(alignment: .firstTextBaseline) { controls }
            } else {
                VStack(alignment: .leading) { controls }
            }
        }
        .onChange(of: viewModel.vol) { newVal, _ in
            setVolume(Int32(newVal))
        }
        .labelStyle(.iconOnly)
        .padding()
        .hoverEffect { effect, isActive, _ in
            effect.opacity(isActive ? 1 : 0.3)
            //.scaleEffect(isActive ? 1: 0.9)
        }
    }

    var controls: some View {
        Group {
            Button("Toggle Dimming", systemImage: viewModel.dimPassthrough ? "moon.fill" : "moon") {
                viewModel.dimPassthrough.toggle()
            }
            HStack {
                Button("Volume", systemImage: viewModel.vol == 0 || viewModel.mute ? "speaker.slash.fill" : "speaker.fill" ) {
                    viewModel.mute.toggle()
                }
                Slider(value: $viewModel.vol, in: 0...127)
                    .frame(width: 300)
                    .padding([.trailing])
            }
            .hoverEffect { effect, isActive, proxy in
                effect.clipShape(.capsule.size(
                    width: isActive ? proxy.size.width : proxy.size.height,
                    height: proxy.size.height,
                    anchor: .leading
                ))
                //effect.scaleEffect(x: isActive ? 1: 0.5, y: 1, anchor: .leading)
            }
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
           // .help("Adjust window to stream aspect ratio") // Accessibility hint
            additions()
        }
    }
}

struct aspectRatioRectangle: View {
    let aspectRatio: CGFloat

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Rectangle()
                    .fill(Color.primary.opacity(0.0001)) // Invisible fill for interaction
                Rectangle()
                    .stroke(Color.primary, lineWidth: 2)
                    .padding(geometry.size.width * 0.1) // Adjust padding for visual aspect ratio
                    .aspectRatio(aspectRatio, contentMode: .fit)
            }
        }
        .frame(width: 30, height: 20) // Adjust size as needed
    }
}
