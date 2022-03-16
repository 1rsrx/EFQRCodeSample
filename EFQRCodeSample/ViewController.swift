//
//  ViewController.swift
//  EFQRCodeSample
//
//  Created by kbp052 on 2022/03/16.
//

import UIKit
import EFQRCode
import AVFoundation

class ViewController: UIViewController {
    
    private let session = AVCaptureSession()
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    
    @IBOutlet weak var captureView: UIImageView!
    @IBOutlet weak var resultLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.overrideUserInterfaceStyle = .light
        setupCamera()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.session.startRunning()
    }
    
    private func setupCamera() {
        guard let caputureDevice = AVCaptureDevice.default(for: .video) else { return }
        
        //FPSの設定
        caputureDevice.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: 30)
        
        do {
            let input = try AVCaptureDeviceInput(device: caputureDevice)
            let output = AVCaptureVideoDataOutput()
            output.videoSettings = [kCVPixelBufferPixelFormatTypeKey : kCVPixelFormatType_32BGRA] as [String : Any]
            output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            output.alwaysDiscardsLateVideoFrames = true
            self.session.sessionPreset = .hd1280x720
            
            if self.session.canAddInput(input) && self.session.canAddOutput(output) {
                self.session.addInput(input)
                self.session.addOutput(output)
                
                self.setupPreview()
            }
        } catch _ {
            print("input作成エラー")
        }
    }
    
    private func setupPreview() {
        self.videoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.session)
        self.videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.videoPreviewLayer.connection?.videoOrientation = .portrait
        self.videoPreviewLayer.frame = self.captureView.bounds
        captureView.layer.addSublayer(videoPreviewLayer)
    }
    
    func convert(from cmSampleBuffer: CMSampleBuffer) -> CGImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(cmSampleBuffer) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return cgImage
    }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let cgImage = convert(from: sampleBuffer) else { return }
        
        //複数のQRを読み取るため配列
        let codes = EFQRCode.recognize(cgImage)
        DispatchQueue.main.async {
            self.resultLabel.text = codes.joined(separator: "\n")
        }
    }
}

