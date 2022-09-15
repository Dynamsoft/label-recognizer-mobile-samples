//
//  DLRResultView.swift
//  HelloWorldSwift
//
//  Created by Dynamsoft's mac on 2022/9/9.
//

import UIKit

class DLRResultView: UIView, UITableViewDelegate, UITableViewDataSource {

    lazy var resultTableView: UITableView = {
        let tableView = UITableView.init(frame: self.bounds, style: UITableView.Style.plain)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()
    
    var resultDataArray: [String] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func setupUI() -> Void {
        self.backgroundColor = .clear
        self.layer.borderColor = UIColor.white.cgColor
        self.layer.borderWidth = 2.0
        self.addSubview(resultTableView)
    }
    
    func updateUI(withResult results: [iDLRResult]) -> Void {
        resultDataArray.removeAll()
        var index = 0
        for dlrResult in results {
            if let dlrResultLineArr = dlrResult.lineResults {
                for dlrLineResult in dlrResultLineArr {
                    index+=1
                    resultDataArray.append(String(format: "Result %d:%@", index, dlrLineResult.text ?? ""))
                }
            }
        }
        resultTableView.reloadData()
    }
    
    // MARK: - TableViewDelegate
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resultDataArray.count
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return DLRResultTableViewCell.getcellHeight(WithString: resultDataArray[indexPath.row])
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: self.width, height: 40))
        let resultLabel = UILabel.init(frame: CGRect.init(x: kComponentLeftMargin, y: 0, width: headerView.width - kComponentLeftMargin, height: 40))
        resultLabel.backgroundColor = .clear
        resultLabel.text = "Results"
        resultLabel.textColor = .white
        resultLabel.font = UIFont.systemFont(ofSize: 20)
        headerView.addSubview(resultLabel)
        return headerView
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "DLRResultCell"
        var cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? DLRResultTableViewCell
        if cell == nil {
            cell = DLRResultTableViewCell.init(style: .default, reuseIdentifier: identifier)
        }
        cell?.updateUI(withString: resultDataArray[indexPath.row])
        return cell ?? UITableViewCell.init()
    }

}
