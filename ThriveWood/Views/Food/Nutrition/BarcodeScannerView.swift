//
//  BarcodeScannerView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 02.05.26.
//
import SwiftUI
import AVFoundation

struct BarcodeScannerView: UIViewControllerRepresentable {
    @Binding var scannedCode: String?
    @Binding var isPresented: Bool

    func makeUIViewController(context: Context) -> ScannerViewController {
        let vc = ScannerViewController()
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, ScannerViewControllerDelegate {
        let parent: BarcodeScannerView

        init(_ parent: BarcodeScannerView) { self.parent = parent }

        func didFindCode(_ code: String) {
            parent.scannedCode = code
            parent.isPresented = false
        }

        func didFail(error: Error) {
            parent.isPresented = false
        }
    }
}

protocol ScannerViewControllerDelegate: AnyObject {
    func didFindCode(_ code: String)
    func didFail(error: Error)
}

final class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    weak var delegate: ScannerViewControllerDelegate?
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var hasFoundCode = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        hasFoundCode = false
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.stopRunning()
        }
    }

    private func setupCamera() {
        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            delegate?.didFail(error: NSError(domain: "", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Keine Kamera verfügbar"]))
            return
        }

        guard let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else {
            delegate?.didFail(error: NSError(domain: "", code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Kamera nicht verfügbar"]))
            return
        }

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            delegate?.didFail(error: NSError(domain: "", code: -3,
                userInfo: [NSLocalizedDescriptionKey: "Kamera-Input fehlgeschlagen"]))
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: .main)
            metadataOutput.metadataObjectTypes = [.ean8, .ean13, .upce, .code128, .code39]
        } else {
            delegate?.didFail(error: NSError(domain: "", code: -4,
                userInfo: [NSLocalizedDescriptionKey: "Metadata-Output fehlgeschlagen"]))
            return
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        // Scan-Bereich Overlay
        addScanOverlay()
    }

    private func addScanOverlay() {
        let overlayView = UIView(frame: view.bounds)
        overlayView.backgroundColor = .clear
        view.addSubview(overlayView)

        let scanRect = CGRect(
            x: view.bounds.width * 0.1,
            y: view.bounds.height * 0.35,
            width: view.bounds.width * 0.8,
            height: view.bounds.height * 0.2
        )

        let path = UIBezierPath(rect: view.bounds)
        let scanPath = UIBezierPath(roundedRect: scanRect, cornerRadius: 12)
        path.append(scanPath)
        path.usesEvenOddFillRule = true

        let fillLayer = CAShapeLayer()
        fillLayer.path = path.cgPath
        fillLayer.fillRule = .evenOdd
        fillLayer.fillColor = UIColor.black.withAlphaComponent(0.5).cgColor
        overlayView.layer.addSublayer(fillLayer)

        let borderLayer = CAShapeLayer()
        borderLayer.path = scanPath.cgPath
        borderLayer.strokeColor = UIColor.white.cgColor
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.lineWidth = 3
        overlayView.layer.addSublayer(borderLayer)

        let label = UILabel()
        label.text = "Barcode in den Rahmen halten"
        label.textColor = .white
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        overlayView.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            label.topAnchor.constraint(equalTo: overlayView.topAnchor, constant: scanRect.maxY + 24)
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard !hasFoundCode else { return }

        if let metadataObject = metadataObjects.first,
           let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
           let stringValue = readableObject.stringValue {
            hasFoundCode = true
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            delegate?.didFindCode(stringValue)
        }
    }
}
