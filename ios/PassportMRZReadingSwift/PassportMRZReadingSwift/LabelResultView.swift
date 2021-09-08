//
//  LabelResultView.swift
//  PassportMRZReadingSwift
//
//  Copyright © 2021 Dynamsoft. All rights reserved.
//

import UIKit

class LabelResultView: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var recogImg:UIImage!
    var contentArr:[String] = []
    
    var resTableview:UITableView!
    var resImageview:UIImageView!
    var tipsImage:UILabel!
    var titleLabel:UILabel!
    var backView:UIView!
    
    let w = UIScreen.main.bounds.size.width
    let h = UIScreen.main.bounds.size.height
    let tabH = UIApplication.shared.statusBarFrame.size.height + 64
    override func viewDidLoad() {
        super.viewDidLoad()
        resImageview = UIImageView(frame: CGRect(x:w / 6, y: tabH, width: w * 2 / 3, height: h/3))
        resImageview.image = recogImg
        if (recogImg.imageOrientation == .right) {
            let transform = CGAffineTransform.identity
            resImageview.transform = transform.rotated(by: CGFloat(-Double.pi / 2))
            resImageview.frame = CGRect(x:w / 6, y: tabH, width: w * 2 / 3, height: h/3)
        }
        
        titleLabel = UILabel(frame: CGRect(x:0, y: tabH - 40, width: w * 2 / 3, height: 40))
        titleLabel.text = "PassportMRZReading"
        titleLabel.textColor = UIColor.black
        titleLabel.font = .boldSystemFont(ofSize: 20)
        backView = UIView(frame: CGRect(x:w - 60, y: tabH - 40, width: 40, height: 40))
        let bg = UIImage(named: "close")
        backView.layer.contents = bg?.cgImage
        let gr = UITapGestureRecognizer(target: self, action: #selector(back))
        backView.addGestureRecognizer(gr)
        tipsImage = UILabel(frame: CGRect(x:0, y: h / 3 + tabH, width: w, height: 30))
        tipsImage.textColor = UIColor.black
        tipsImage.text = "Capture passport Image"
        tipsImage.textAlignment = .center
        resTableview = UITableView(frame: CGRect(x:5, y: h / 3 + tabH + 60, width: w - 10, height: h / 2 - 64), style: .plain)
        resTableview.delegate = self
        resTableview.dataSource = self
        resTableview.separatorColor = UIColor.gray
        resTableview.isUserInteractionEnabled = true
        
        self.view.addSubview(titleLabel)
        self.view.addSubview(backView)
        self.view.addSubview(resImageview)
        self.view.addSubview(tipsImage)
        self.view.addSubview(resTableview)
    }
    
    @objc func back(){
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    func addCell(cell:UITableViewCell, txt:String){
        let size = CGSize(width: 100, height: 40)
        let tablex = resTableview.frame.origin.x + resTableview.frame.size.width
        let lb = UILabel(frame: CGRect(x:tablex - size.width, y: 40 - size.height / 2, width: 100, height: 40))
        lb.textColor = UIColor.gray
        lb.text = txt
        lb.font = .boldSystemFont(ofSize: 18)
        lb.textAlignment = .center
        let str:NSString = lb.text! as NSString
        let sizeNew = str.size(withAttributes: [NSAttributedStringKey.font:UIFont.boldSystemFont(ofSize: 18)])
        lb.frame = CGRect(x:tablex - sizeNew.width - 15, y:40 - sizeNew.height / 2, width: sizeNew.width, height:sizeNew.height)
        cell.contentView.addSubview(lb)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "mrz")
        if cell != nil {
            for v in cell!.contentView.subviews {
                v.removeFromSuperview()
            }
        }
        
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "mrz")
        }
        var title = ""
        switch indexPath.row {
        case 0:
            title = "SURNAME"
            self.addCell(cell: cell!, txt: contentArr[1])
        case 1:
            title = "GIVEN NAMES"
            self.addCell(cell: cell!, txt: contentArr[2])
        case 2:
            title = "NATIONALITY"
            self.addCell(cell: cell!, txt: contentArr[0])
        case 3:
            title = "SEX/GENDER"
            self.addCell(cell: cell!, txt: contentArr[6])
        case 4:
            title = "DATE OF BIRTH"
            self.addCell(cell: cell!, txt: self.getDate(str: contentArr[5]))
        case 5:
            title = "ISSUING COUNTRY"
            self.addCell(cell: cell!, txt: contentArr[4])
        case 6:
            title = "PASSPORT NUMBER"
            self.addCell(cell: cell!, txt: contentArr[3])
        case 7:
            title = "PASSPORT EXPIRATION"
            self.addCell(cell: cell!, txt: self.getDate(str: contentArr[7]))
        default:
            title = ""
        }
        cell?.textLabel?.text = title
        cell?.textLabel?.font = .italicSystemFont(ofSize: 16)
        return cell!
    }
    
    func getDate(str: String) -> String {
        let mm:Int = Int(str[2..<4])!
        let vals = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
        let year = str[0..<2]
        let day = str[4..<6]
        let mo = vals[mm - 1]
        let ret = day.appending(" \(String(describing: mo)) \(year)")
        return ret
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 7
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override var prefersStatusBarHidden: Bool{
        return true
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        let w = size.width
        let h = size.height
        resImageview.frame = CGRect(x:w / 6, y: tabH, width: w * 2 / 3, height: h/3)
        if (recogImg.imageOrientation == .right) {
            let transform = CGAffineTransform.identity
            resImageview.transform = transform.rotated(by: CGFloat(-Double.pi / 2))
            resImageview.frame = CGRect(x:w / 6, y: tabH, width: w * 2 / 3, height: h/3)
        }
        titleLabel.frame = CGRect(x:0, y: tabH - 40, width: w * 2 / 3, height: 40)
        backView.frame = CGRect(x:w - 60, y: tabH - 40, width: 40, height: 40)
        tipsImage.frame = CGRect(x:0, y: h / 3 + tabH, width: w, height: 30)
        resTableview.frame = CGRect(x:5, y: h / 3 + tabH + 60, width: w - 10, height: h / 2 - 64)
        resTableview.reloadData()
    }
}
