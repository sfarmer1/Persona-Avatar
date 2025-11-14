import SwiftUI
import Combine
import AVKit
import RealityKit


struct CameraLauncherView: View {
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @State private var didLaunch = false
    @FocusState private var isFocused: Bool

    var body: some View {
        
        EmptyView()
            .focusable(true)
            .focused($isFocused)
            .onAppear {
                guard !didLaunch else { return }
                didLaunch = true
                isFocused = true
                DispatchQueue.main.async {
                    Task { await openImmersiveSpace(id: immersiveSceneID) }
                }
            }
    }
}


let cameraID = "anchor.0"
let immersiveSceneID = "headtracker.immersive"

@main
struct Persona_AvatarApp: App {
    var body: some SwiftUI.Scene {
        
        Window("CameraKiller", id: cameraID) {
            CameraLauncherView()
            .task({
                WindowCameraKillerSystem.registerSystem()
            })
        }
        .defaultSize(width: 825, height: 500)
        
        ImmersiveSpace(id: immersiveSceneID) {
            ImmersiveHUDView()
        }
    }
}

