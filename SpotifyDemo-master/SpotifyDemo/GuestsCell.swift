//
//  GuestsCell.swift
//  InSync
//
//  Created by Nancy Yao on 7/30/16.
//  Copyright © 2016 Angel Vázquez. All rights reserved.
//

import UIKit

class GuestsCell: UITableViewCell {

    @IBOutlet weak var guestImageView: UIImageView!
    @IBOutlet weak var guestNameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
