//
//  MRZResultViewController.swift
//  MRZScannerSwift

import UIKit

class MRZResultViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource {

    var mrzResult: iMRZResult!
    
    var mrzDataArray: [[String:String]] = []
    
    lazy var resultTableView: UITableView = {
        let tableView = UITableView.init(frame: self.view.bounds, style: UITableView.Style.plain)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIDevice.setOrientation(.portrait)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.view.backgroundColor = .white
        self.title = "MRZ Result"
        
        createData()
        setupUI()
    }
    
    private func createData() -> Void {
        
        mrzDataArray.append(["RowPrefix":"Document Type",
                               "Content":mrzResult.docType
                            ])
        mrzDataArray.append(["RowPrefix":"Surname",
                               "Content":mrzResult.surname
                            ])
        mrzDataArray.append(["RowPrefix":"Given Name",
                               "Content":mrzResult.givenName
                            ])
        mrzDataArray.append(["RowPrefix":"Nationality",
                               "Content":mrzResult.nationality
                            ])
        mrzDataArray.append(["RowPrefix":"Date of Birth(YYYY-MM-DD)",
                               "Content":mrzResult.dateOfBirth
                            ])
        mrzDataArray.append(["RowPrefix":"Gender",
                               "Content":mrzResult.gender
                            ])
        mrzDataArray.append(["RowPrefix":"Date of Expiry(YYYY-MM-DD)",
                               "Content":mrzResult.dateOfExpiration
                            ])
        mrzDataArray.append(["RowPrefix":"IsParsed",
                               "Content":mrzResult.isParsed ? "YES" : "NO"
                            ])
        mrzDataArray.append(["RowPrefix":"IsVerified",
                               "Content":mrzResult.isVerified ? "YES" : "NO"
                            ])
        mrzDataArray.append(["RowPrefix":"MRZ String",
                               "Content":"\n" + mrzResult.mrzText
                            ])
    }
    
    private func setupUI() -> Void {
        self.view.addSubview(resultTableView)
    }

    // MARK: - TableViewDelegate
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mrzDataArray.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let mrzLineDic = mrzDataArray[indexPath.row]
        let mrzLineText = mrzLineDic["RowPrefix"]! + ":" + mrzLineDic["Content"]!
        return MRZResultTableViewCell.getcellHeight(WithString: mrzLineText)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "MRZResultCell"
        var cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? MRZResultTableViewCell
        if cell == nil {
            cell = MRZResultTableViewCell.init(style: .default, reuseIdentifier: identifier)
        }
        let mrzLineDic = mrzDataArray[indexPath.row]
        let mrzLineText = mrzLineDic["RowPrefix"]! + ":" + mrzLineDic["Content"]!
        cell?.updateUI(withString: mrzLineText)
        return cell ?? UITableViewCell.init()
    }
    
    // MARK: - Orientation
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [.portrait]
    }
    
    override var shouldAutorotate: Bool {
        get {true}
    }
}
