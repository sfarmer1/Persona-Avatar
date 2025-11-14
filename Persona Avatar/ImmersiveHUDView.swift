import SwiftUI
import RealityKit
import AVKit
import Combine
import ARKit

final class HUDUpdateSystem: System {
    private let arkitSession = ARKitSession()
    private let worldTrackingProvider = WorldTrackingProvider()
    private var cameraFlipper = false
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
            e.isEnabled = cameraFlipper
        }
    }

    func update(context: SceneUpdateContext) {
        
        // Check whether the world-tracking provider is running.
        guard worldTrackingProvider.state == .running else { return }
        
        tickCount += 1
        if tickCount % 2 != 0 {
            cameraFlipper = !cameraFlipper
        }
        
        // Query the device anchor at the current time.
        guard let deviceAnchor = worldTrackingProvider.queryDeviceAnchor(atTimestamp: CACurrentMediaTime()) else { return }
        
        // Find the transform of the device.
        let deviceTransformMat = deviceAnchor.originFromAnchorTransform

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
            HUDUpdateSystem.registerSystem()
        }
        
        CameraView()
            .cameraAnchor(isActive: true)
    }
}

