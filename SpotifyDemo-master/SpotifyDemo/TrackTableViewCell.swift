//
//  TrackTableViewCell.swift
//  InSync
//
//  Created by Pedro Sandoval Segura on 7/14/16.
//  Copyright © 2016 Angel Vázquez. All rights reserved.
//

import UIKit

class TrackTableViewCell: UITableViewCell {

    @IBOutlet weak var trackNameLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var albumImageView: UIImageView!
    @IBOutlet weak var durationLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.selectionStyle = UITableViewCellSelectionStyle.None
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
        if selected {
            self.backgroundColor = UIColor(red: 143/255.0, green: 219/255.0, blue: 218/255.0, alpha: 0.4)
        } else {
            self.backgroundColor = UIColor.blackColor()
        }
    }
    

}
