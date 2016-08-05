//
//  ArtistTableViewCell.swift
//  InSync
//
//  Created by Pedro Sandoval Segura on 7/16/16.
//  Copyright © 2016 Angel Vázquez. All rights reserved.
//

import UIKit

class ArtistTableViewCell: UITableViewCell {
    
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var artistProfileImage: UIImageView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        // Create circular profile picture views
        self.artistProfileImage.layer.cornerRadius = self.artistProfileImage.frame.size.width / 2
        artistProfileImage.clipsToBounds = true
        
        //Set up the clock picture
        artistProfileImage.image = UIImage(named: "Spotify_Icon_RGB_Black")
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}