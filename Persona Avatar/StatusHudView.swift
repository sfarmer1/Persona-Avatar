//
//  StatusHudView.swift
//  Persona Avatar
//
//  Created by dev on 10/28/25.
//

import SwiftUI

    struct StatusHudView: View {
        var body: some View {
            VStack(spacing: 8) {
                Text("Status").font(.headline)
                Text("All green ✅").font(.subheadline)
            }
            .padding(14)
            .glassBackgroundEffect()
        }
    }
