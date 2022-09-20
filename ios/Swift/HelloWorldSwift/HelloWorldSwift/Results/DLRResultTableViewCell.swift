//
//  DLRResultTableViewCell.swift
//  HelloWorldSwift
//
//  Created by Dynamsoft's mac on 2022/9/9.
//

import UIKit

class DLRResultTableViewCell: UITableViewCell {

    lazy var resultLabel: UILabel = {
        let resultLabel = UILabel.init(frame: CGRect.init(x: kComponentLeftMargin, y: 0, width: KDLRResultTextWidth, height: 0))
        resultLabel.textColor = .white
        resultLabel.font = UIFont.systemFont(ofSize: KDLRResultTextFont)
        resultLabel.numberOfLines = 0
        return resultLabel
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func setupUI() -> Void {
        self.selectionStyle = .none
        self.backgroundColor = .clear
        self.contentView.addSubview(resultLabel)
    }
    
    class func getcellHeight(WithString resultString: String) -> CGFloat {
        return DynamsoftToolsManager.shared.calculateHeight(withText: resultString, font: UIFont.systemFont(ofSize: KDLRResultTextFont), componentWidth: KDLRResultTextWidth) + 10
    }
    
    func updateUI(withString resultString: String) -> Void {
        resultLabel.text = resultString
        resultLabel.height = DynamsoftToolsManager.shared.calculateHeight(withText: resultString, font: UIFont.systemFont(ofSize: KDLRResultTextFont), componentWidth: KDLRResultTextWidth)
    }
    
}
