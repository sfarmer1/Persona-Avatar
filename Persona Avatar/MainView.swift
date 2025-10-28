//
//  MainView.swift
//  Persona Avatar
//
//  Created by dev on 10/28/25.
//


import SwiftUI


struct MainView: View {
    /// The environment value to get the instance of the `OpenImmersiveSpaceAction` instance.
    @Environment(\.openImmersiveSpace) var openImmersiveSpace


    var body: some View {
        // Display a line of text and
        // open a new immersive space environment.
        CameraView()
        .onAppear {
            Task {
                await openImmersiveSpace(id: "ImmersiveHUD")
            }
        }
    }
}
