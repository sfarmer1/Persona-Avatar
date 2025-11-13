import SwiftUI
import RealityKit
import AVKit
import Combine
import ARKit

final class WindowCameraKillerSystem: System {
    required init(scene: RealityKit.Scene) {
    }
    
    func printEntityAndAlterCam(_ e: Entity, _ depth: Int) {
        var s = ""
        for _ in 0..<depth {
            s += "  "
        }
        if depth == 0 {
            //print(e.components)
        }
        //print(s, "`" + e.name + "' id:", e.id, type(of: e), e.position, e.scale)
        for c in e.children {
            printEntityAndAlterCam(c, depth + 1)
        }
        
        if e.name.starts(with: "SpatialProxy:virtualCamera") {
            e.isEnabled = false
        }
    }

    func update(context: SceneUpdateContext) {
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
            printEntityAndAlterCam(e, 0)
        }
    }
}
