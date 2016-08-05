//
//  QueueSwipeTableCell.swift
//  InSync
//
//  Created by Nancy Yao on 7/24/16.
//  Copyright © 2016 Angel Vázquez. All rights reserved.
//

import UIKit
import MGSwipeTableCell

class QueueSwipeTableCell: MGSwipeTableCell {

    @IBOutlet weak var songNameLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var albumCoverImageView: UIImageView!
    @IBOutlet weak var votesCountLabel: UILabel!
    @IBOutlet weak var upvoteButton: UIButton!
    @IBOutlet weak var downvoteButton: UIButton!
        
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: false)
        
        // Configure the view for the selected state
    }

}
