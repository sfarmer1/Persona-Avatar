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
    private var tickCount: Int = 0
    
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
    
    func printEntityAndAlterCam(_ e: Entity, _ depth: Int, _ deviceTransformMat: simd_float4x4) {
        var s = ""
        for _ in 0..<depth {
            s += "  "
        }
        if depth == 0 {
            //print(e.components)
        }
        //print(s, "`" + e.name + "' id:", e.id, type(of: e), e.position, e.scale)
        for c in e.children {
            printEntityAndAlterCam(c, depth + 1, deviceTransformMat)
        }
        
        if e.name.starts(with: "SpatialProxy:virtualCamera") {
            let p = e.parent!.parent!.parent!.parent!.parent!
            
            var pos = deviceTransformMat.columns.3
            pos -= deviceTransformMat.columns.2 * 1.0
            p.position = simd_float3(pos.x, pos.y, pos.z)
            p.orientation = simd_quatf(deviceTransformMat)
            e.isEnabled = coordinator.cameraFlipper
        }
    }

    static func currentKeyWindow() -> UIWindow? {
        UIApplication.shared.connectedScenes
            .filter({ $0.activationState == .foregroundActive })
            .map({ $0 as? UIWindowScene })
            .compactMap({ $0 })
            .first?.windows
            .filter({ $0.isKeyWindow })
            .first
    }

    func update(context: SceneUpdateContext) {
//        guard let hud = context.scene.performQuery(HUDUpdateSystem.hudQuery).first(where: { _ in true }) else { return }
        
        // Check whether the world-tracking provider is running.
        guard worldTrackingProvider.state == .running else { return }
        
        tickCount += 1
        if tickCount % 2 != 0 {
            coordinator.cameraFlipper = !coordinator.cameraFlipper
        }
        
        // Query the device anchor at the current time.
        guard let deviceAnchor = worldTrackingProvider.queryDeviceAnchor(atTimestamp: CACurrentMediaTime()) else { return }
        
        // Find the transform of the device.
        let deviceTransformMat = deviceAnchor.originFromAnchorTransform
        let deviceTransform = Transform(matrix: deviceTransformMat)
        
        //print(HUDUpdateSystem.currentKeyWindow())
        /*if let window = HUDUpdateSystem.currentKeyWindow() {
            for w in window.windowScene!.windows {
                //w.transform3D.m13 = CGFloat(sin(Float(CACurrentMediaTime())))
                //w.frame = CGRect(x: w.frame.origin.x, y: w.frame.origin.y, width: w.frame.width, height: w.frame.height)
                if (w.description.contains("ViewHosting")) {
                    print(w)
                    w.makeKey()
                }
            }
        }*/

        let query = EntityQuery()
        var roots = [Entity]()
        context.scene.performQuery(query).forEach { entity in
            var e = entity
            var lastId = e.id
            while true {
                if e.parent == nil {
                    break
                }
                e = e.parent!
                if e.id == lastId {
                    break
                }
                lastId = e.id
                
                if e.name.contains("Window Context Entity") {
                    var contains = false
                    for r in roots {
                        if r.id == e.id {
                            contains = true
                            break
                        }
                    }
                    if !contains {
                        roots.append(e)
                    }
                }
            }
        }
        
        //print("Entity tree for scene:")
        for e in roots {
            printEntityAndAlterCam(e, 0, deviceTransformMat)
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
        
        CameraView()
        .cameraAnchor(isActive: true)
    }
}

