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
    }
    
    func configureDLR() -> Void {
        labelRecognizer = DynamsoftLabelRecognizer.init()
        
        let dlrRuntimeSettings: iDLRRuntimeSettings = try! self.labelRecognizer.getRuntimeSettings()
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
    
    // MARK: - LabelResultListener
    func labelResultCallback(_ frameId: Int, imageData: iImageData, results: [iDLRResult]?) {
        if let results = results {
            guard results.count > 0 else {
                return
            }
            labelRecognizer.stopScanning()
            
            var msgString = ""
            var index = 0
            for dlrResult in results {
                if let dlrLineResults = dlrResult.lineResults {
                    for lineResult in dlrLineResults {
                        index+=1
                        msgString += String(format: "Result %d:%@\n", index, lineResult.text ?? "")
  
                    }
                }
            }
            let alertVC = UIAlertController.init(title: "Results", message: msgString, preferredStyle: .alert)
            let okAction = UIAlertAction.init(title: "OK", style: .default) { _ in
                self.labelRecognizer.startScanning()
            }
            alertVC.addAction(okAction)
            DispatchQueue.main.async {
                self.present(alertVC, animated: true, completion: nil)
            }
        }
    }
}
