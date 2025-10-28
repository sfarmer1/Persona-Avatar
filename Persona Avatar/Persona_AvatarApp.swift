import SwiftUI

@main
struct Persona_AvatarApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
        }
        
        // Immersive space scene with explicit ID for the HUD
        ImmersiveSpace(id: "ImmersiveHUD") {
            ImmersiveHUDView()
        }
    }
}
