//
//  CameraView.swift
//  Persona Avatar
//
//  Created by dev on 10/28/25.
//

import SwiftUI
import Combine
import AVFoundation
import CoreImage

struct CameraView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var model = CameraModel()

    var body: some View {
        ZStack {
            switch model.authorizationStatus {
            case .authorized:
                ZStack {
                    if let image = model.currentFrameImage {
                        Image(image, scale: 1.0, orientation: .up, label: Text("Camera frame"))
                            .resizable()
                            .scaledToFill()
                            .ignoresSafeArea()
                    } else {
                        Color.black.ignoresSafeArea()
                        ProgressView()
                            .tint(.white)
                    }
                }
            case .notDetermined:
                ProgressView("Requesting Camera Access…")
            case .denied, .restricted:
                VStack(spacing: 12) {
                    Text("Camera Access Needed")
                        .font(.title2).bold()
                    Text("Please enable camera access in Settings to use the front camera.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                    Button("Open Settings") { model.openSettings() }
                        .buttonStyle(.borderedProminent)
                }
                .padding()
            @unknown default:
                Text("Camera unavailable")
                    .foregroundStyle(.secondary)
            }
        }
        .task { await model.prepare() }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                model.start()
            case .inactive, .background:
                model.stop()
            @unknown default:
                break
            }
        }
    }
}

final class CameraModel: NSObject, ObservableObject {
    
    @Published var authorizationStatus: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @Published var currentFrameImage: CGImage?

    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let videoOutput = AVCaptureVideoDataOutput()
    private let videoOutputQueue = DispatchQueue(label: "camera.video.output.queue")
    private let ciContext = CIContext()

    override init() {
        super.init()
    }

    @MainActor
    func prepare() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .notDetermined {
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            self.authorizationStatus = granted ? .authorized : .denied
            if granted { configureSession() }
        } else {
            self.authorizationStatus = status
            if status == .authorized { configureSession() }
        }
    }

    @MainActor private func configureSession() {
        sessionQueue.async {
            self.session.beginConfiguration()
            defer { self.session.commitConfiguration() }

            // Preset
#if !os(visionOS)
            self.session.sessionPreset = .high
#endif

            // Remove existing inputs/outputs
            for input in self.session.inputs { self.session.removeInput(input) }
            for output in self.session.outputs { self.session.removeOutput(output) }

            // Front wide-angle camera
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
            guard let camera = device, let input = try? AVCaptureDeviceInput(device: camera) else { return }

            if self.session.canAddInput(input) {
                self.session.addInput(input)
            }

            // Configure video data output
            self.videoOutput.alwaysDiscardsLateVideoFrames = true
            self.videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            if self.session.canAddOutput(self.videoOutput) {
                self.session.addOutput(self.videoOutput)
            }

            // Set delegate
            self.videoOutput.setSampleBufferDelegate(self, queue: self.videoOutputQueue)
        }
    }

    @MainActor func start() {
        sessionQueue.async {
            guard !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }

    @MainActor func stop() {
        sessionQueue.async {
            guard self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    func openSettings() {
#if canImport(UIKit)
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
#else
        // Not supported on this platform
#endif
    }
}

nonisolated extension CameraModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        // Convert to CGImage
        if let cgImage = self.ciContext.createCGImage(ciImage, from: ciImage.extent) {
            Task { @MainActor in
                self.currentFrameImage = cgImage
            }
        }
    }
}
