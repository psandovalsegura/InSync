//
//  AlbumTableViewCell.swift
//  InSync
//
//  Created by Pedro Sandoval Segura on 7/16/16.
//  Copyright © 2016 Angel Vázquez. All rights reserved.
//

import UIKit

class AlbumTableViewCell: UITableViewCell {
    
    
    @IBOutlet weak var albumImage: UIImageView!
    @IBOutlet weak var albumNameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}