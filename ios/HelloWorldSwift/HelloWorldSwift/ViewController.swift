//
//  ViewController.swift
//  HelloWorldSwift
//
//  Created by dynamsoft on 2021/7/1.
//

import UIKit
import DynamsoftLabelRecognizer

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, DLRLicenseVerificationDelegate {
    
    var dlr: DynamsoftLabelRecognizer!
    var img: UIImage!

    @IBOutlet weak var imgView: UIImageView!
    
    var imagePickerController: UIImagePickerController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // 1.Initialize license.
        // The string "DLS2eyJvcmdhbml6YXRpb25JRCI6IjIwMDAwMSJ9" here is a 7-day free license. Note that network connection is required for this license to work.
        // If you want to use an offline license, please contact Dynamsoft Support: https://www.dynamsoft.com/company/contact/
        // You can also request a 30-day trial license in the customer portal: https://www.dynamsoft.com/customer/license/trialLicense?product=dlr&utm_source=github&package=ios
        DynamsoftLabelRecognizer.initLicense("DLS2eyJvcmdhbml6YXRpb25JRCI6IjIwMDAwMSJ9", verificationDelegate: self)
        
        // 2.Create an instance of Label Recognizer.
        dlr = DynamsoftLabelRecognizer.init()
    }

    @IBAction func onTakePhoto(_ sender: Any) {
        imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = .camera
        imagePickerController.cameraDevice = .rear
        imagePickerController.delegate = self
        
        present(imagePickerController, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        img = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        imgView.image = img
        
        self.dismiss(animated: true, completion: nil)
        
    }
    
    @IBAction func onRecognizeText(_ sender: Any) {
        DispatchQueue.global().async {
            self.recognizeText()
        }
    }
    
    private func recognizeText() {
        
        var error : NSError? = NSError()
        
        // 3.Recognize text from an image.
        let results = self.dlr.recognizeByImage(image: img, templateName: "", error: &error)
        
        if error?.code != 0 {
            var errMsg:String? = ""
            errMsg = error!.userInfo[NSUnderlyingErrorKey] as? String
            self.showResults(title: "Error", msgText: errMsg ?? "")
        }else{
            var msgText:String = ""
            
            // 4. Get all recognized results.
            for item in results
            {
                if item.lineResults!.count > 0 {
                    for lineResult in item.lineResults! {
                        msgText = "\(msgText)\nValue: \(lineResult.text ?? "nil")\n"
                    }
                }else{
                    msgText = "No data detected."
                }
            }
            self.showResults(title: "Results", msgText: msgText)
        }
    }
    
    private func showResults(title:String,msgText:String) {
        DispatchQueue.main.async {
            let ac = UIAlertController(title: title, message: msgText, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(ac, animated: true, completion: nil)
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
                self.showResults(title: title, msgText: msg ?? "")
            }
    }
    
}

