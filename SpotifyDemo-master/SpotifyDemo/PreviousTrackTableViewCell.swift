//
//  PreviousTrackTableViewCell.swift
//  InSync
//
//  Created by Nancy Yao on 7/28/16.
//  Copyright © 2016 Angel Vázquez. All rights reserved.
//

import UIKit

class PreviousTrackTableViewCell: UITableViewCell {

    @IBOutlet weak var songNameLabel: UILabel!
    @IBOutlet weak var artistAlbumLabel: UILabel!
    @IBOutlet weak var litnessLabel: UILabel!
    @IBOutlet weak var addTrackButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
