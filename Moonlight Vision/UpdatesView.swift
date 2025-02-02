//
//  UpdatesView.swift
//  Moonlight
//
//  Created by camy on 2/2/25.
//  Copyright © 2025 Moonlight Game Streaming Project. All rights reserved.
//

import SwiftUI

struct UpdatesView: View {
    var body: some View {
        GeometryReader { geometry in // 1. GeometryReader to get screen width
            let screenWidth = geometry.size.width
            let screenHeight = geometry.size.height
            let horizontalPadding = screenWidth * 0.30 // 20% horizontal padding
            let verticalPaddingForForm = screenHeight * 0.20 // 20% top padding for Form

            Form {
                Section { // Section for the title (no header)
                    HStack { // 2. HStack to apply padding to title
                        Spacer() // Push title to center if needed
                        Text("Changelog")
                            .font(.largeTitle)
                            .multilineTextAlignment(.center) // Ensure title text is centered within its area
                        Spacer() // Push title to center if needed
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, 20.0) // Corrected and kept top padding for the title section
                }
                .listRowBackground(Color.clear) // Remove background from this section


                Section(header: Text("Latest Updates")) { // Section for latest updates
                    VStack(alignment: .leading) { // Original VStack for text alignment
                        Text("Version 11.0.0 (February, 2025)")
                            .font(.headline)
                        Text("- Initial support for Reality Kit Volume (for curved screens) thanks to https://www.reddit.com/user/tht7/ for his hard work on the new feature for Moonlight XrOS!")
                            .font(.body)
                        Text("- UIKit has a new aspect ratio button, so if you have a weird window aspect ratio, just click the button and it should fix it, if it doesn't work, try making your window really small before pressing it, then resizing after, or try to close the stream and opening again then clicking button, i'm not quite sure why its so finicky, we're still working on stablity hence the testflight.")
                            .font(.body)
                        Text("- RealityKit mode DOES NOT SUPPORT mouse and keyboard, only controllers.")
                            .font(.body)
                        Text("- Realitykit is unstable past 50mbs, please set your bandwidth to 50mbs or lower for performance, we are working on optimizing this.")
                            .font(.body)
                        Text("- Changelog tab added to track updates.")
                            .font(.body)
                    }
                    .padding(.vertical) // Keep vertical padding
                    .frame(maxWidth: .infinity, alignment: .leading) // Ensure VStack takes full width and aligns content to leading
                }

                Section(header: Text("Noted Bugs")) { // Section for older updates
                    VStack(alignment: .leading) {
                        Text("- There is a large delay on first launch, this has to do with the dedplication and it having to process network discovery, I am working on this.")
                            .font(.body)
                            .foregroundColor(.white)
                        Text("- Sometimes selecting a differing computer host doesn't load the app data, you may have to go back to the settings tab and back to refresh it.")
                            .font(.body)
                            .foregroundColor(.white)
                        Text("- HDR is noteably broken on both UiKit and RealityKit since vision OS 2.0, we're not really sure why so we're rewriting how we process HDR.")
                            .font(.body)
                            .foregroundColor(.white)
                        Text("- Deleting a PC causes a crash, after deleting a computer (for example if you need to repair after installing Apollo or Sunshine) just force quit and re-open and you will be fine")
                            .font(.body)
                            .foregroundColor(.white)
                        Text("- Even though you've already paired a computer, you may see the same computer host again with .local in the name")
                            .font(.body)
                            .foregroundColor(.white)
                        Text("- Depending on how long you've waited before clicking a new host that isn't paired, it might show a default message and you have to go to settings and back to fix it.")
                            .font(.body)
                            .foregroundColor(.white)
                        Text("- Moonlight XrOS does not know when a computer is ONLINE, only that it's been saved and paired or it hasn't been paired yet..")
                            .font(.body)
                            .foregroundColor(.white)
                        Text("- If a connection fails in UIKit, you are not able to close the window, you have to forcequit.")
                            .font(.body)
                            .foregroundColor(.white)
                        Text("- According to user reports, PS4 touch pad does not work, we added a 'home' button in reality kit but it's not in reality kit yet. This is an SDL issue, Moonlight uses SDL2 but the latest version is SDL3, would take some large effort to update everything to be SDL3 compliant.")
                            .font(.body)
                            .foregroundColor(.white)

                    }
                    .padding(.vertical)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Section(header: Text("Feature Requests")) { // Section for older updates
                    VStack(alignment: .leading) {
                        Text("- Microphone Support.")
                            .font(.body)
                            .foregroundColor(.white)
                        Text("- SBS 3D Support")
                            .font(.body)
                            .foregroundColor(.white)
                        Text("- 7.1 Audio + Ability to turn on and off immersive audio, we're working on this")
                            .font(.body)
                            .foregroundColor(.white)
                        Text("- According to user reports, PS4 touch pad does not work, we added a 'home' button in reality kit but it's not in reality kit yet. This is an SDL issue, Moonlight uses SDL2 but the latest version is SDL3, would take some large effort to update everything to be SDL3 compliant.")
                            .font(.body)
                            .foregroundColor(.white)

                    }
                    .padding(.vertical)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Section(header: Text("More Information")) { // Optional section for more links etc.
                    VStack(alignment: .leading) {
                        Text("Official Website:")
                            .font(.body)
                        Link("Moonlight Game Streaming Project Website", destination: URL(string: "https://moonlight-stream.org/")!)
                            .font(.body)
                        Link("Moonlight XrOS Github", destination: URL(string: "https://github.com/RikuKunMS2/moonlight-ios-vision/tree/vision-testflight")!)
                            .font(.body)
                        Link("Regular Updates", destination: URL(string: "http://ko-fi.com/lumanaire")!)
                            .font(.body)
                        Link("Moonlight Discord (use channel #ios-appletv-help)", destination: URL(string: "https://moonlight-stream.org/discord")!)
                            .font(.body)

                    }
                    .padding(.vertical)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .glassBackgroundEffect()
            .padding(.top, 20.0) // Corrected and kept top padding for the title section
        }
    }
}


#Preview {
    UpdatesView()
}
