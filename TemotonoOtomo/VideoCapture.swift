//
//  VideoCapture.swift
//  TemotonoOtomo
//
//  Created by Shun on 2022/07/07.
//

import Foundation
import AVFoundation

class VideoCapture: NSObject {
    
    let captureSession = AVCaptureSession()
    var handler: ((CMSampleBuffer) -> Void)?

    override init() {
        super.init()
        setup()
    }

    // 初期設定
    func setup() {
        captureSession.beginConfiguration()
        let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
        guard
            let deviceInput = try? AVCaptureDeviceInput(device: device!),
            captureSession.canAddInput(deviceInput)
            else { return }
        captureSession.addInput(deviceInput)

        let videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "mydispatchqueue"))
        videoDataOutput.alwaysDiscardsLateVideoFrames = true

        guard captureSession.canAddOutput(videoDataOutput) else { return }
        captureSession.addOutput(videoDataOutput)

        // アウトプットの画像を縦向きに変更（標準は横）
        for connection in videoDataOutput.connections {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
        }

        captureSession.commitConfiguration()
    }

    // カメラ映像を出力
    func run(_ handler: @escaping (CMSampleBuffer) -> Void)  {
        if !captureSession.isRunning {
            self.handler = handler
            captureSession.startRunning()
        }
    }

    // カメラ映像を停止
    func stop() {
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }
}

extension VideoCapture: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if let handler = handler {
            handler(sampleBuffer)
        }
    }
}