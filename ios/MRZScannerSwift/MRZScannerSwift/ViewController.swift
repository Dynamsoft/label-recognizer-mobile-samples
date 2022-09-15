//
//  ViewController.swift
//  MRZScannerSwift
//
//  Created by Dynamsoft's mac on 2022/9/14.
//

import UIKit

class ViewController: BaseViewController, MRZRessultListener {

    var mrzRecognizer: DynamsoftMRZRecognizer!
    var cameraEnhancer: DynamsoftCameraEnhancer!
    var dceView: DCECameraView!
    
    var currentDeviceOrientation: UIDeviceOrientation = .portrait
    var isOrientationUseful: Bool = true
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.tintColor = .white
        
        mrzRecognizer.startScanning()
        isOrientationUseful = true
        
        switch currentDeviceOrientation {
       
        case .portrait:
            UIDevice.setOrientation(.portrait)
       
        case .landscapeLeft:
            UIDevice.setOrientation(.landscapeRight)
       
        default:
            break
        }
       
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isOrientationUseful = false
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.view.backgroundColor = .white
        self.title = "MRZ Scanner"
        
        // Register Notification.
        NotificationCenter.default.addObserver(self, selector: #selector(orientationChange(_:)), name: UIDevice.orientationDidChangeNotification, object: nil)
        
        configureMRZ()
    }
    
    func configureMRZ() -> Void {
        mrzRecognizer = DynamsoftMRZRecognizer.init()
        
        dceView = DCECameraView.init(frame: self.view.bounds)
        cameraEnhancer = DynamsoftCameraEnhancer.init(view: dceView)
        self.view.addSubview(dceView)
        cameraEnhancer.open()
        
        mrzRecognizer.setImageSource(cameraEnhancer)
        mrzRecognizer.setMRZResultListener(self)
        mrzRecognizer.startScanning()
        mrzRecognizer.update25AlgorithmVerifyState(false)
        
        let region = iRegionDefinition.init()
        region.regionLeft = 5
        region.regionRight = 95
        region.regionTop = 40
        region.regionBottom = 60
        region.regionMeasuredByPercentage = 1
        try? cameraEnhancer.setScanRegion(region)
    }
    
    // MARK: - MRZRessultListener
    func mrzResultCallback(_ frameId: Int, imageData: iImageData, result: iMRZResult?) {
        if let mrzResult = result {
            mrzRecognizer.stopScanning()
            if isOrientationUseful {
                let mrzResultVC = MRZResultViewController.init()
                mrzResultVC.mrzResult = mrzResult
                self.navigationController?.pushViewController(mrzResultVC, animated: true)
            }
        }
    }
    

    // MARK: - Orientation
    @objc func orientationChange(_ noti: NSNotification) -> Void {
        
        guard isOrientationUseful == true else {
            return
        }
        
        let orientation = UIDevice.current.orientation
        currentDeviceOrientation = orientation
        
        let qua: iQuadrilateral = iQuadrilateral.init()
       
        switch orientation {
       
        case .portrait:
            qua.points = [NSNumber.init(cgPoint: CGPoint.init(x: 0, y: 100)),
                          NSNumber.init(cgPoint: CGPoint.init(x: 0, y: 0)),
                          NSNumber.init(cgPoint: CGPoint.init(x: 100, y: 0)),
                          NSNumber.init(cgPoint: CGPoint.init(x: 100, y: 100))
            ]
        case .landscapeLeft:
            qua.points = [NSNumber.init(cgPoint: CGPoint.init(x: 0, y: 0)),
                          NSNumber.init(cgPoint: CGPoint.init(x: 100, y: 0)),
                          NSNumber.init(cgPoint: CGPoint.init(x: 100, y: 100)),
                          NSNumber.init(cgPoint: CGPoint.init(x: 0, y: 100))
            ]
        default:
            qua.points = [NSNumber.init(cgPoint: CGPoint.init(x: 0, y: 100)),
                          NSNumber.init(cgPoint: CGPoint.init(x: 0, y: 0)),
                          NSNumber.init(cgPoint: CGPoint.init(x: 100, y: 0)),
                          NSNumber.init(cgPoint: CGPoint.init(x: 100, y: 100))
            ]
        }
          
        let dlrRuntimeSetting = try! mrzRecognizer.getRuntimeSettings()
        dlrRuntimeSetting.textArea = qua
        try? mrzRecognizer.updateRuntimeSettings(dlrRuntimeSetting)
                          
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [.portrait, .landscapeRight]
    }
    
    override var shouldAutorotate: Bool {
        get {true}
    }

}

