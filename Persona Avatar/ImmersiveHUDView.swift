import SwiftUI
import RealityKit

struct ImmersiveHUDView: View {
    var body: some View {
        RealityView { content in
            // Head-locked anchor for a HUD that follows the user's head
            let anchor = AnchorEntity(.head)
            content.add(anchor)

            // Container entity for the HUD content
            let hud = ViewAttachmentEntity(
                components: ViewAttachmentComponent(
                rootView: VStack(spacing: 8) {
                    Text("Status").font(.headline)
                    Text("All green ✅").font(.subheadline)
                }
                .padding(14)
                .glassBackgroundEffect()))
            hud.position = [0, -0.05, -0.85]
            hud.components.set(BillboardComponent())

            // Attach HUD to the anchor so it appears in the scene
            anchor.addChild(hud)
        }
        // In immersive spaces, you often want to hide hands/arms near HUDs; adjust as needed
        .upperLimbVisibility(.hidden)
    }
}
