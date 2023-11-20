/*
 * This is the sample of Dynamsoft Label Recognizer.
 *
 * Copyright © Dynamsoft Corporation.  All rights reserved.
 */

import UIKit
import DynamsoftCaptureVisionRouter
import DynamsoftLabelRecognizer
import DynamsoftCameraEnhancer

typealias ConfirmCompletion = () -> Void

class ViewController: UIViewController, CapturedResultReceiver {

    private var cvr: CaptureVisionRouter!
    private var dce: CameraEnhancer!
    private var dceView: CameraView!
    
    lazy var resultView: UITextView = {
        let left = 0.0
        let width = self.view.bounds.size.width
        let height = self.view.bounds.size.height / 2.5
        let top = self.view.bounds.size.height - height
        
        resultView = UITextView(frame: CGRect(x: left, y: top , width: width, height: height))
        resultView.layer.backgroundColor = UIColor.clear.cgColor
        resultView.layoutManager.allowsNonContiguousLayout = false
        resultView.isEditable = false
        resultView.isSelectable = false
        resultView.font = UIFont.systemFont(ofSize: 14.0, weight: .medium)
        resultView.textColor = UIColor.white
        resultView.textAlignment = .center
        return resultView
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        cvr.startCapturing(PresetTemplate.recognizeTextLines.rawValue) {
            [unowned self] isSuccess, error in
            if let error = error {
                self.displayError(msg: error.localizedDescription)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.view.backgroundColor = .white
        
        configureCVR()
        configureDCE()
        setupUI()
    }
    
    private func configureCVR() -> Void {
        cvr = CaptureVisionRouter()
        cvr.addResultReceiver(self)
    }
    
    private func configureDCE() -> Void {
        dceView = CameraView(frame: self.view.bounds)
        dceView.scanLaserVisible = true
        self.view.addSubview(dceView)

        let dlrDrawingLayer = dceView.getDrawingLayer(DrawingLayerId.DLR.rawValue)
        dlrDrawingLayer?.visible = true

        dce = CameraEnhancer(view: dceView)
        dce.open()
        // ScanRegion.
        let region = Rect()
        region.top = 0.4
        region.bottom = 0.6
        region.left = 0.1
        region.right = 0.9
        region.measuredInPercentage = true
        try? dce.setScanRegion(region)

        //  CVR link DCE.
        try? cvr.setInput(dce)
    }
    
    private func setupUI() -> Void {
        self.view.addSubview(resultView)
    }
    
    // MARK: - CapturedResultReceiver
    func onRecognizedTextLinesReceived(_ result: RecognizedTextLinesResult) {
        guard let items = result.items else { return }
        
        // Parse Results.
        var resultText = ""
        var index = 0
        for dlrLineResults in items {
            index+=1
            resultText += String(format: "Result %d:%@\n", index, dlrLineResults.text ?? "")
        }
        
        DispatchQueue.main.async {
            self.resultView.text = String(format: "Results(%d)\n", items.count) + resultText
        }
    }
    
    private func displayError(_ title: String = "", msg: String, _ acTitle: String = "OK", completion: ConfirmCompletion? = nil) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: acTitle, style: .default, handler: { _ in completion?() }))
            self.present(alert, animated: true, completion: nil)
        }
    }
}

