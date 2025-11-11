import SwiftUI
import RealityKit
import AVKit
import Combine
import ARKit

struct HUDTag: Component {}

final class HUDUpdateSystem: System {
    static let hudQuery = EntityQuery(where: .has(HUDTag.self))
    private let arkitSession = ARKitSession()
    private let worldTrackingProvider = WorldTrackingProvider()
    private var coordinator = FocusCoordinator.shared
    private var lastBucket: Int? = nil
    
    required init(scene: RealityKit.Scene) {
        // Start ARKit Session
        Task {
            do {
                try await arkitSession.run([worldTrackingProvider])
            } catch {
                print("Error: \(error)")
            }
        }
    }

    func update(context: SceneUpdateContext) {
//        guard let hud = context.scene.performQuery(HUDUpdateSystem.hudQuery).first(where: { _ in true }) else { return }
        
        // Check whether the world-tracking provider is running.
        guard worldTrackingProvider.state == .running else { return }
        
        // Query the device anchor at the current time.
        guard let deviceAnchor = worldTrackingProvider.queryDeviceAnchor(atTimestamp: CACurrentMediaTime()) else { return }
        
        // Find the transform of the device.
        let deviceTransform = Transform(matrix: deviceAnchor.originFromAnchorTransform)
        

        // Compute head yaw (rotation about world up) from the head's quaternion
        let q = deviceTransform.rotation
        // Yaw from quaternion (assuming right-handed, y-up): yaw = atan2(2*(w*y + x*z), 1 - 2*(y*y + z*z))
        let siny_cosp = 2 * (q.real * q.imag.y + q.imag.x * q.imag.z)
        let cosy_cosp = 1 - 2 * (q.imag.y * q.imag.y + q.imag.z * q.imag.z)
        let yawRadians = atan2(siny_cosp, cosy_cosp)
        var yawDegrees = yawRadians * 180 / .pi
        // Normalize to [0, 360)
        yawDegrees -= 15
        yawDegrees.formTruncatingRemainder(dividingBy: 360)
        if yawDegrees < 0 { yawDegrees += 360 }
        
        // Determine 30° bucket and alternate color by bucket parity
        let bucket = Int(yawDegrees / 30) // 0..11
        
        
        if lastBucket != bucket {
            Task { @MainActor in
                coordinator.currentWindowID = "anchor.\(bucket)"
            }
            lastBucket = bucket
        }
    }
}

struct ImmersiveHUDView: View {
    var body: some View {
        RealityView { content in
            // Head-locked anchor for a HUD that follows the user's head
            let headAnchor = AnchorEntity(.head)
            content.add(headAnchor)

            // Container entity for the HUD content
            let hud = ViewAttachmentEntity(
                components: ViewAttachmentComponent(
                    rootView: AnyView(Color(.red).frame(width: 5, height: 5))
                )
            )
            hud.name = "hud"
            hud.components.set(HUDTag())
            hud.position = [0, -0.05, -0.85]
            hud.components.set(BillboardComponent())

            // Attach HUD to the anchor so it appears in the scene
            headAnchor.addChild(hud)

            // Capture the current head transform once and place planes relative to it
            let currentHeadTranslation = headAnchor.transform.translation
            let currentHeadRotation = headAnchor.transform.rotation

            // Create a world anchor to hold the planes, positioned at world origin
            let worldAnchor = AnchorEntity(.world(transform: .init(1)))
            content.add(worldAnchor)

            // Compute positions for a ring of planes around the user's initial head pose
            let planeWidth: Float = 0.02
            let planeHeight: Float = 2
            let radius: Float = 1.9
            let baseDegrees: [Float] = [10, 30, 50, 70, 90, 110, 130, 150, 170, 190, 210, 230, 250, 270, 290, 310, 330, 350]
            let planeMesh = MeshResource.generatePlane(width: planeWidth, height: planeHeight)
            let planeMaterial = SimpleMaterial(color: .white.withAlphaComponent(0.6), isMetallic: false)

            // Extract yaw from the current head rotation to orient the ring in world space
            let rotMat = float3x3(currentHeadRotation)
            let sinYaw = rotMat[0][2]
            let cosYaw = rotMat[2][2]
            let headYaw = atan2(sinYaw, cosYaw)

            for deg in baseDegrees {
                let angle = (deg * .pi / 180) + headYaw
                let x = sin(angle) * radius + currentHeadTranslation.x
                let z = -cos(angle) * radius + currentHeadTranslation.z

                let planeEntity = ModelEntity(mesh: planeMesh, materials: [planeMaterial])
                planeEntity.components.set(BillboardComponent())
                var t = Transform()
                t.translation = [x, 0, z]
                planeEntity.transform = t
                worldAnchor.addChild(planeEntity)
            }
            HUDTag.registerComponent()
            HUDUpdateSystem.registerSystem()
        }
        // In immersive spaces, you often want to hide hands/arms near HUDs; adjust as needed
        .upperLimbVisibility(.hidden)
    }
}

