//
//  DynamsoftLabelRecognizer sample
//
//  Copyright © 2021 Dynamsoft. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import DynamsoftLabelRecognizer

class ViewController: UIViewController, UINavigationControllerDelegate, UIDocumentPickerDelegate, UIImagePickerControllerDelegate, DLRLicenseVerificationDelegate {
    var recognizer:DynamsoftLabelRecognizer!
    var pickFileBtn:UIButton!
    var pickPicBtn:UIButton!
    var sourceType:UIImagePickerControllerSourceType!
    var loadingView:UIActivityIndicatorView!
    
    let session:AVCaptureSession = AVCaptureSession()
    var previewLayer:AVCaptureVideoPreviewLayer?
    var photoOutput:AVCaptureStillImageOutput?
    var sessionQueue:DispatchQueue!
    var photoButton:UIButton! = UIButton()
    var captureView:UIView! = UIView()
    var leadView:UIView! = UIView()
    var subLeadView:UIView! = UIView()
    var orientationNum:Int = 0
    
    let w = UIScreen.main.bounds.size.width
    let h = UIScreen.main.bounds.size.height
    let safeAreaBottomHeight:CGFloat = UIApplication.shared.statusBarFrame.size.height > 20 ? 34 : 0
    let co = UIColor(red: 254.0/255.0, green: 142.0/255.0, blue: 20.0/255.0, alpha: 1.0)
    override func viewDidLoad() {
        super.viewDidLoad()
        // The string "DLS2eyJvcmdhbml6YXRpb25JRCI6IjIwMDAwMSJ9" will grant you a public trial license good for 7 days. After that, please visit: https://www.dynamsoft.com/customer/license/trialLicense?product=dlr&utm_source=code-gallery&package=ios to request for 30 days extension.
        DynamsoftLabelRecognizer.initLicense("DLS2eyJvcmdhbml6YXRpb25JRCI6IjIwMDAwMSJ9", verificationDelegate: self)
        recognizer = DynamsoftLabelRecognizer.init()
        self.DLRSettings()
        self.setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.stopSession()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func DLRSettings() {
        let models = ["NumberUppercase",
                      "NumberUppercase_Assist_1lIJ",
                      "NumberUppercase_Assist_8B",
                      "NumberUppercase_Assist_8BHR",
                      "NumberUppercase_Assist_number",
                      "NumberUppercase_Assist_O0DQ",
                      "NumberUppercase_Assist_upcase",]
        var error:NSError?
        for model in models {
            let prototxt = Bundle.main.url(forResource: model, withExtension: "prototxt")
            let datapro = try! Data.init(contentsOf: prototxt!)
            let txt = Bundle.main.url(forResource: model, withExtension: "txt")
            let datatxt = try! Data.init(contentsOf: txt!)
            let caffemodel = Bundle.main.url(forResource: model, withExtension: "caffemodel")
            let datacaf = try! Data.init(contentsOf: caffemodel!)
            DynamsoftLabelRecognizer.appendCharacterModel(name: model, prototxtBuffer: datapro, txtBuffer: datatxt, characterModelBuffer: datacaf)
        }
        recognizer.appendSettingsFromFile(filePath: Bundle.main.path(forResource: "wholeImgMRZTemplate", ofType: "json")!, error: &error)
        if error?.code != 0 {
            var errMsg:String? = ""
            errMsg = error!.userInfo[NSUnderlyingErrorKey] as? String
            self.showResult("Error", errMsg ?? "") {
            }
        }
    }
    
    func dlrLicenseVerificationCallback(_ isSuccess: Bool, error: Error?) {
            var msg:String? = ""
            var title = "Server license verify failed"
            if(error != nil)
            {
                let err = error as NSError?
                if err?.code == -1009 {
                    msg = "Dynamsoft Label Recognizer is unable to connect to the public Internet to acquire a license. Please connect your device to the Internet or contact support@dynamsoft.com to acquire an offline license."
                    title = "No Internet"
                }else{
                    msg = err!.userInfo[NSUnderlyingErrorKey] as? String
                    if(msg == nil)
                    {
                        msg = err?.localizedDescription
                    }
                }
                self.showResult(title, msg ?? "") {
                    
                }
            }
    }
    
    @objc func handleOrientationDidChange(){
        DispatchQueue.main.async {
            var mainBounds:CGRect = .zero
            let w = UIScreen.main.bounds.size.width
            let h = UIScreen.main.bounds.size.height
            var avOri :AVCaptureVideoOrientation = .portrait
            switch UIApplication.shared.statusBarOrientation {
            case .portrait:
                mainBounds.size.width = min(h, w)
                mainBounds.size.height = max(h, w)
                self.orientationNum = 0
                avOri = .portrait
            case .landscapeRight:
                mainBounds.size.width = max(h, w)
                mainBounds.size.height = min(h, w)
                self.orientationNum = 2
                avOri = .landscapeRight
            case .landscapeLeft:
                mainBounds.size.width = max(h, w)
                mainBounds.size.height = min(h, w)
                self.orientationNum = 1
                avOri = .landscapeLeft
            default:
                mainBounds.size.width = min(h, w)
                mainBounds.size.height = max(h, w)
                self.orientationNum = 0
                avOri = .portrait
            }
            self.previewLayer?.connection?.videoOrientation = avOri
            self.previewLayer?.frame = mainBounds
            self.captureView.frame = mainBounds
            let SafeAreaBottomHeight = UIApplication.shared.statusBarFrame.size.height
            if (mainBounds.size.width > mainBounds.size.height) {
                self.leadView.frame = CGRect(x: 100, y: 50, width: mainBounds.size.width - 200, height: mainBounds.size.height - 100)
                self.photoButton.frame = CGRect(x: mainBounds.size.width - 90, y: mainBounds.size.height / 2 - 39, width: 78, height: 78)
            }else{
                self.leadView.frame = CGRect(x: 5, y: mainBounds.size.height / 3, width: mainBounds.size.width - 10, height: mainBounds.size.height / 3 + 30)
                self.photoButton.frame = CGRect(x: mainBounds.size.width / 2 - 39, y: mainBounds.size.height - 126 - SafeAreaBottomHeight, width: 78, height: 78)
            }
            self.subLeadView.frame = CGRect(x: 0, y: self.leadView.bounds.size.height - 60, width: self.leadView.bounds.size.width, height: 60)
            self.loadingView.frame = CGRect(x: mainBounds.size.width / 2 - 25, y: mainBounds.size.height / 2 - 25, width: 50, height: 50)
            self.pickPicBtn.frame = CGRect(x: mainBounds.size.width / 6, y: mainBounds.size.height / 2 - 40, width: mainBounds.size.width * 2 / 3, height: 50)
            self.pickFileBtn.frame = CGRect(x: mainBounds.size.width / 6, y: mainBounds.size.height / 2 + 40, width: mainBounds.size.width * 2 / 3, height: 50)
        }
    }

    
    func setupUI()
    {
        UIApplication.shared.isIdleTimerDisabled = true
        NotificationCenter.default.addObserver(self, selector: #selector(handleOrientationDidChange), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        sessionQueue = DispatchQueue(label: "mrzQueue", qos: .default, attributes: [.concurrent], autoreleaseFrequency: .inherit, target: nil)
        pickPicBtn = UIButton()
        pickPicBtn.frame = CGRect(x:w / 6, y: h / 2 - 40, width:w * 2 / 3, height:50)
        pickPicBtn.setTitle("Select Picture", for: .normal)
        pickPicBtn.setTitleColor(co, for: .normal)
        pickPicBtn.addTarget(self, action: #selector(pickPicClick), for: .touchUpInside)
        pickPicBtn.layer.borderWidth = 1
        pickPicBtn.layer.borderColor = co.cgColor
        pickPicBtn.layer.cornerRadius = 6
        pickFileBtn = UIButton()
        pickFileBtn.frame = CGRect(x:w / 6, y: h / 2 + 40, width: w * 2 / 3, height: 50)
        pickFileBtn.setTitle("Select File", for: .normal)
        pickFileBtn.setTitleColor(co, for: .normal)
        pickFileBtn.addTarget(self, action: #selector(pickFileClick), for: .touchUpInside)
        pickFileBtn.layer.borderWidth = 1
        pickFileBtn.layer.borderColor = co.cgColor
        pickFileBtn.layer.cornerRadius = 6
        
        loadingView = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        loadingView.center = self.view.center
        loadingView.activityIndicatorViewStyle = .gray
        self.view.addSubview(pickFileBtn)
        self.view.addSubview(pickPicBtn)
        self.view.addSubview(loadingView)
    }
    
    // MARK: - image picker
    @objc func pickPicClick(){
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let photoAlbumAction = UIAlertAction(title: "PhotoLibrary", style: .default) { ac in
            self.getAlertActionType(1)
        }
        let cameraAction = UIAlertAction(title: "Camera", style: .default) { ac in
            self.addCamera()
            self.addBack()
        }
        let cancleAction = UIAlertAction(title: "Cancel", style: .cancel) { ac in
            self.getAlertActionType(0)
        }
        alertController.addAction(photoAlbumAction)
        alertController.addAction(cancleAction)
        UIImagePickerController.isSourceTypeAvailable(.camera) ? alertController.addAction(cameraAction) : nil
        self.present(alertController, animated: true, completion: nil)
    }
    
    func getAlertActionType(_ t:Int){
        var type:UIImagePickerControllerSourceType = .photoLibrary
        if (t == 1) {
            type = .photoLibrary
        }else if (t == 2) {
            type = .camera
        }
        sourceType = type
        let cameragranted:Int = self.AVAuthorizationStatusIsGranted()
        if cameragranted == 0 {
            let alertController = UIAlertController(title: "Tips", message: "Settings-Privacy-Camera/Album-Authorization", preferredStyle: .alert)
            let comfirmAction = UIAlertAction(title: "OK", style: .default) { ac in
                let url:URL = URL(fileURLWithPath: UIApplicationOpenSettingsURLString)
                if UIApplication.shared.canOpenURL(url) { UIApplication.shared.openURL(url) }
            }
            alertController.addAction(comfirmAction)
            self.present(alertController, animated: true, completion: nil)
        }else if cameragranted == 1 {
            self.presentPickerViewController()
        }
    }
    
    func AVAuthorizationStatusIsGranted() -> Int{
        let mediaType:AVMediaType = .video
        let authStatusVideo:AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: mediaType)
        let authStatusAlbm:PHAuthorizationStatus  = .authorized
        let authStatus:Int = sourceType == UIImagePickerControllerSourceType.photoLibrary ? authStatusAlbm.rawValue : authStatusVideo.rawValue
        switch authStatus {
        case 0:
            if sourceType == UIImagePickerControllerSourceType.photoLibrary {
                PHPhotoLibrary.requestAuthorization { status in
                    if status == .authorized {
                        self.presentPickerViewController()
                    }
                }
            }else{
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    if granted {
                        self.presentPickerViewController()
                    }
                }
            }
            return 2
        case 1: return 0
        case 2: return 0
        case 3: return 1
        default:
            return 0
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        self.recoByBuffer(image: image)
        picker.dismiss(animated: true, completion: nil)
    }
    
    func recoByBuffer(image:UIImage){
        let width: Int = Int(image.size.width)
        let height: Int = Int(image.size.height)
        let bpr: Int = image.cgImage!.bytesPerRow
        let buffer = image.cgImage?.dataProvider?.data
        DispatchQueue.main.async {
            self.loadingView.startAnimating()
        }
        DispatchQueue.global().async {
            var error : NSError? = NSError()
            let data : iImageData = iImageData()
            data.bytes = (buffer as Data?)!
            data.width = width
            data.height = height
            data.stride = bpr
            data.format = EnumImagePixelFormat.ARGB_8888
            let ret = self.recognizer.recognizeByBuffer(imageData: data, templateName: "locr", error: &error)
            if error?.code != 0 {
                var errMsg:String? = ""
                errMsg = error!.userInfo[NSUnderlyingErrorKey] as? String
                self.showResult("Error", errMsg ?? "") {
                }
            }else{
                self.handleResults(results: ret, error: error!, image: image)
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - file picker
    @objc func pickFileClick(){
        let types = ["public.content","public.data","public.image","com.adobe.pdf","com.microsoft.word.doc"]
        let vc:UIDocumentPickerViewController = UIDocumentPickerViewController(documentTypes: types, in: .import)
        vc.delegate = self
        self.present(vc, animated: true, completion: nil)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        self.recoByFile(url: url)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if controller.documentPickerMode == .import {
            self.recoByFile(url: urls.last!)
        }
    }
    
    func recoByFile(url:URL){
        let data = NSData(contentsOf: url)
        guard let image = UIImage(data: data! as Data) else { return }
        var error : NSError? = NSError()
        DispatchQueue.main.async {
            self.loadingView.startAnimating()
        }
        let ret = recognizer.recognizeByFile(path: url.path, templateName: "locr", error: &error)
        if error?.code != 0 {
            var errMsg:String? = ""
            errMsg = error!.userInfo[NSUnderlyingErrorKey] as? String
            self.showResult("Error", errMsg ?? "") {
            }
        }else{
            self.handleResults(results: ret, error: error!, image: image)
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func addCamera(){
        self.setVideoSession()
        let tabH = UIApplication.shared.statusBarFrame.size.height
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer!.frame = CGRect(x: 0, y: tabH, width: w, height: h - tabH)
        previewLayer!.videoGravity = .resizeAspectFill
        previewLayer!.connection?.videoOrientation = .portrait
        photoButton = UIButton(frame: CGRect(x:w / 2 - 39, y: h - 126 - safeAreaBottomHeight, width: 78, height: 78))
        photoButton.setImage(UIImage(named: "icon_capture"), for: .normal)
        photoButton.addTarget(self, action: #selector(takePictures), for: .touchUpInside)
        leadView = self.generateView(r: CGRect(x: 5, y: h / 3, width: w - 10, height: h / 3 + 30))
        subLeadView = self.generateView(r: CGRect(x: 0, y: leadView.bounds.size.height - 60, width: leadView.bounds.size.width, height: 60))
        captureView = UIView(frame: CGRect(x: 0, y: tabH, width: w, height: h - tabH))
        DispatchQueue.main.async {
            self.leadView.addSubview(self.subLeadView)
            self.captureView.layer.addSublayer(self.previewLayer!)
            self.view.insertSubview(self.captureView, belowSubview: self.loadingView)
            self.view.insertSubview(self.leadView, belowSubview: self.loadingView)
            self.view.addSubview(self.photoButton)
        }
        AVCaptureDevice.requestAccess(for: .video) { (granted) in
            if granted {
                self.startSession()
            }
        }
    }
    
    func generateView(r:CGRect) -> UIView {
        let v = UIView(frame: r)
        v.backgroundColor = UIColor.clear
        v.layer.cornerRadius = 5
        v.layer.borderWidth = 1
        v.layer.borderColor = co.cgColor
        return v
    }
    
    @objc func takePictures(){
        self.photoButton?.isEnabled = false
        let videoConnection: AVCaptureConnection? = photoOutput!.connection(with: AVMediaType.video)
        if videoConnection == nil {
            self.photoButton?.isEnabled = true
            return
        }
        photoOutput!.captureStillImageAsynchronously(from: videoConnection!, completionHandler: {(_ imageDataSampleBuffer: CMSampleBuffer?, _ error: Error?) -> Void in
            if imageDataSampleBuffer == nil {
                self.photoButton?.isEnabled = true
                return
            }
            let imageData: Data? = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer!)
            var originImage:UIImage? = nil
            if (self.orientationNum == 2) {
                originImage = UIImage(data: imageData!)!
            }else{
                originImage = self.FixOrientation(aImage:UIImage(data: imageData!)!)
            }
            self.recoByBuffer(image: originImage!)
        })
    }
    
    func addBack(){
        self.navigationItem.leftBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .reply, target: self, action: #selector(backToHome))
    }
    
    @objc func backToHome(){
        self.stopSession()
        self.navigationItem.leftBarButtonItem = nil
    }
    
    func setVideoSession() {
        guard !session.isRunning else { return }
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        do
        {
            if(device.isFocusModeSupported(.continuousAutoFocus)){
                try device.lockForConfiguration()
                device.focusMode = .continuousAutoFocus
                device.unlockForConfiguration()
            }
            if(device.isAutoFocusRangeRestrictionSupported){
                try device.lockForConfiguration()
                device.autoFocusRangeRestriction = .near
                device.unlockForConfiguration()
            }
        }catch{
            print(error)
        }
        guard let input = try? AVCaptureDeviceInput(device: device) else { return }
        guard session.canAddInput(input) else { return }
        session.addInput(input)
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        photoOutput = AVCaptureStillImageOutput()
        guard session.canAddOutput(videoOutput) else { return }
        session.addOutput(videoOutput)
        guard session.canAddOutput(photoOutput!) else { return }
        session.addOutput(photoOutput!)
        if(self.session.canSetSessionPreset(.hd1280x720)){
            session.sessionPreset = .hd1280x720
        }
    }
    
    func startSession() {
        #if targetEnvironment(simulator)
        return
        #endif
        sessionQueue.async {
            if !self.session.isRunning { self.session.startRunning() }
        }
    }
    
    func stopSession(){
        #if targetEnvironment(simulator)
        return
        #endif
        sessionQueue.async {
            if self.session.isRunning { self.session.stopRunning() }
            DispatchQueue.main.async {
                if (self.previewLayer != nil) { self.previewLayer!.removeFromSuperlayer() }
                self.photoButton.removeFromSuperview()
                self.leadView.removeFromSuperview()
                self.captureView.removeFromSuperview()
            }
            for input in self.session.inputs {
                self.session.removeInput(input)
            }
            for output in self.session.outputs {
                self.session.removeOutput(output)
            }
        }
    }
    
    // MARK: - handle result
    func handleResults(results:[iDLRResult], error:NSError, image:UIImage) {
        DispatchQueue.main.async {
            self.loadingView.stopAnimating()
            self.photoButton.isEnabled = true
        }
        if (results.count > 0 && results.first?.lineResults?.count == 2) {
            let line1 = (results.first!.lineResults![0].text != nil) ? results.first!.lineResults![0].text : ""
            let line2 = (results.first!.lineResults![1].text != nil) ? results.first!.lineResults![1].text : ""
            self.sendResult(line1: line1!, line2: line2!, img: image)
        }else{
            let msg = error.code == 0 ? "" : error.userInfo[NSUnderlyingErrorKey]
            self.showResult("No result", msg as! String) {
                
            }
        }
    }
    
    func sendResult(line1:String, line2:String, img:UIImage){
        var contentArr:[String] = []
        let substr = line1[2..<5]
        contentArr.append(String(substr))
        let fullN = line1.suffix(39)
        let range = fullN.range(of: "<<")
        let surN = fullN.prefix(upTo: range!.lowerBound).replacingOccurrences(of: "<", with: " ")
        contentArr.append(String(surN))
        let givenN = fullN.suffix(from: range!.upperBound)
        let givArr = givenN.components(separatedBy: "<")
        var tmp:[String] = []
        for item in givArr {
            if !item.elementsEqual("") {
                tmp.append(item)
            }
        }
        contentArr.append(tmp.joined(separator: " "))
        let docNum = line2.prefix(9)
        contentArr.append(String(docNum))
        let issueC = line2[10..<13]
        contentArr.append(String(issueC))
        let birth = line2[13..<19]
        contentArr.append(String(birth))
        let gen = line2[20]
        contentArr.append(String(gen))
        let docDate = line2[21..<27]
        contentArr.append(String(docDate))
        if (contentArr.count < 8) {
            self.showResult("No result", "") {
                self.loadingView.stopAnimating()
            }
            return
        }
        DispatchQueue.main.async {
            let stryBoard = UIStoryboard(name: "Main", bundle: nil)
            let labelVC = stryBoard.instantiateViewController(withIdentifier: "LabelResultView") as! LabelResultView
            labelVC.modalPresentationStyle = .pageSheet
            labelVC.recogImg = img
            labelVC.contentArr = contentArr
            self.present(labelVC, animated: true, completion: nil)
        }
    }
    
    func presentPickerViewController(){
        DispatchQueue.main.async {
            let picker = UIImagePickerController()
            if #available(iOS 11.0, *) {
                UIScrollView.appearance().contentInsetAdjustmentBehavior = .always
            } else {
                // Fallback on earlier versions
            }
            picker.delegate = self
            picker.sourceType = self.sourceType
            self.present(picker, animated: true, completion: nil)
        }
    }
    
    private func showResult(_ title: String, _ msg: String, completion: @escaping () -> Void) {
        DispatchQueue.main.async {
            let ac = UIAlertController(title: title, message: msg, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "Ok", style: .default, handler: { _ in completion() }))
            self.present(ac, animated: true, completion: nil)
        }
    }
    
    override var prefersStatusBarHidden: Bool{
        let w = UIScreen.main.bounds.size.width
        let h = UIScreen.main.bounds.size.height
        if w > h {
            return true
        }
        return false
    }
    
    func FixOrientation(aImage: UIImage) -> UIImage {
        if (aImage.imageOrientation == .up) {
            return aImage
        }
        var transform = CGAffineTransform.identity
        switch (aImage.imageOrientation) {
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: aImage.size.width, y: 0)
            transform = transform.rotated(by: CGFloat(Double.pi / 2))
            break
        case .right, .rightMirrored:
            if orientationNum == 1 {
                transform = transform.translatedBy(x: aImage.size.height, y: aImage.size.width)
                transform = transform.rotated(by: CGFloat(-Double.pi))
            }else{
                transform = transform.translatedBy(x: 0, y: aImage.size.height)
                transform = transform.rotated(by: CGFloat(-Double.pi / 2))
            }
        default:
            break
        }
        switch (aImage.imageOrientation) {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: aImage.size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
            break
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: aImage.size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
            break
        default:
            break
        }
        var ctx:CGContext?
        if orientationNum == 1 {
            ctx = CGContext(data: nil, width: Int(aImage.size.height), height: Int(aImage.size.width),
                                bitsPerComponent: aImage.cgImage!.bitsPerComponent, bytesPerRow: 0,
                                space: aImage.cgImage!.colorSpace!,
                                bitmapInfo: aImage.cgImage!.bitmapInfo.rawValue)
        }else{
            ctx = CGContext(data: nil, width: Int(aImage.size.width), height: Int(aImage.size.height),
                                bitsPerComponent: aImage.cgImage!.bitsPerComponent, bytesPerRow: 0,
                                space: aImage.cgImage!.colorSpace!,
                                bitmapInfo: aImage.cgImage!.bitmapInfo.rawValue)
        }
        ctx!.concatenate(transform)
        switch (aImage.imageOrientation) {
        case .left, .leftMirrored, .right, .rightMirrored:
            ctx?.draw(aImage.cgImage!, in: CGRect(x: 0, y: 0, width: aImage.size.height, height: aImage.size.width))
            break
        default:
            ctx?.draw(aImage.cgImage!, in: CGRect(x: 0, y: 0, width: aImage.size.width, height: aImage.size.height))
            break
        }
        let cgimg = ctx!.makeImage()
        return UIImage(cgImage: cgimg!)
    }
}

extension String {
    subscript (i:Int)->String{
            let startIndex = self.index(self.startIndex, offsetBy: i)
            let endIndex = self.index(startIndex, offsetBy: 1)
            return String(self[startIndex..<endIndex])
    }
    subscript (r: Range<Int>) -> String {
        get {
            let startIndex = self.index(self.startIndex, offsetBy: r.lowerBound)
            let endIndex = self.index(self.startIndex, offsetBy: r.upperBound)
            return String(self[startIndex..<endIndex])
        }
    }
    subscript (index:Int , length:Int) -> String {
        get {
            let startIndex = self.index(self.startIndex, offsetBy: index)
            let endIndex = self.index(startIndex, offsetBy: length)
            return String(self[startIndex..<endIndex])
        }
    }
    func substring(to:Int) -> String{
        return self[0..<to]
    }
    func substring(from:Int) -> String{
        return self[from..<self.count]
    }
}

