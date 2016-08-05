//
//  FoundPeersCell.swift
//  InSync
//
//  Created by Nancy Yao on 7/11/16.
//  Copyright © 2016 Angel Vázquez. All rights reserved.
//

import UIKit

class FoundPeersCell: UITableViewCell {

    @IBOutlet weak var foundPeersLabel: UILabel!
    @IBOutlet weak var foundPeersImageView: UIImageView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.foundPeersImageView.layer.cornerRadius = self.foundPeersImageView.frame.size.width / 2
        self.foundPeersImageView.layer.masksToBounds = true
        self.foundPeersImageView.layer.borderWidth = 1.0;
        self.foundPeersImageView.layer.borderColor = UIColor.blackColor().CGColor
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
