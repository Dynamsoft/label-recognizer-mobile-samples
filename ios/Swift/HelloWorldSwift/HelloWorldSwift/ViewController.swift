//
//  ViewController.swift
//  HelloWorldSwift
//
//  Created by Dynamsoft's mac on 2022/9/9.
//

import UIKit

class ViewController: BaseViewController, LabelResultListener {

    var labelRecognizer: DynamsoftLabelRecognizer!
    var cameraEnhancer: DynamsoftCameraEnhancer!
    var dceView: DCECameraView!
    
    lazy var dlrResultView: DLRResultView = {
        let dlrResultView = DLRResultView.init(frame: CGRect.init(x: 20, y: self.view.height * 0.55, width: self.view.width - 40, height: self.view.height * 0.45 - 34))
        return dlrResultView
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.tintColor = .white
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
        self.navigationController?.navigationBar.barTintColor = UIColor(red: 59.003 / 255.0, green: 61.9991 / 255.0, blue: 69.0028 / 255.0, alpha: 1)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.view.backgroundColor = .white
        self.title = "DynamsoftLabelRecognizer"
        
        configureDLR()
        setupUI()
    }
    
    func configureDLR() -> Void {
        labelRecognizer = DynamsoftLabelRecognizer.init()
        
        let dlrRuntimeSettings: iDLRRuntimeSettings = try! self.labelRecognizer.getRuntimeSettings()
        dlrRuntimeSettings.textArea = self.handleTextArea()
        try! self.labelRecognizer.updateRuntimeSettings(dlrRuntimeSettings)
        
        dceView = DCECameraView.init(frame: self.view.bounds)
        cameraEnhancer = DynamsoftCameraEnhancer.init(view: self.dceView)
        self.view.addSubview(self.dceView)
        cameraEnhancer.open()
        
        labelRecognizer.setImageSource(self.cameraEnhancer)
        labelRecognizer.setLabelResultListener(self)
        labelRecognizer.startScanning()
        
        let region = iRegionDefinition.init()
        region.regionLeft = 5
        region.regionRight = 95
        region.regionTop = 30
        region.regionBottom = 50
        region.regionMeasuredByPercentage = 1
        try? cameraEnhancer.setScanRegion(region)
      
    }
    
    func setupUI() -> Void {
        self.view.addSubview(dlrResultView)
    }
    
    func handleTextArea() -> iQuadrilateral {
        let qua = iQuadrilateral.init()
        qua.points = [NSNumber(cgPoint: CGPoint(x: 0, y: 100)),
                      NSNumber(cgPoint: CGPoint(x: 0, y: 0)),
                      NSNumber(cgPoint: CGPoint(x: 100, y: 0)),
                      NSNumber(cgPoint: CGPoint(x: 100, y: 100))]
        return qua
    }
    
    // MARK: - LabelResultListener
    func labelResultCallback(_ frameId: Int, imageData: iImageData, results: [iDLRResult]?) {
        if let results = results {
            dlrResultView.updateUI(withResult: results)
        }
    }

}
