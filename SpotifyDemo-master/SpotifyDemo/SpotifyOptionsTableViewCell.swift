//
//  SpotifyOptionsTableViewCell.swift
//  InSync
//
//  Created by Pedro Sandoval Segura on 7/13/16.
//  Copyright © 2016 Angel Vázquez. All rights reserved.
//

import UIKit

class SpotifyOptionsTableViewCell: UITableViewCell {

    @IBOutlet weak var optionLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Initialization code
        self.selectionStyle = UITableViewCellSelectionStyle.None
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
        if selected {
            self.backgroundColor = UIColor(red: 143/255.0, green: 219/255.0, blue: 218/255.0, alpha: 0.5)
        } else {
            UIView.animateWithDuration(0.5, animations: {
                self.backgroundColor = UIColor.blackColor()
            })
            
        }
    }

}
