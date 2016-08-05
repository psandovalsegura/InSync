//
//  NowPlayingTableViewCell.swift
//  InSync
//
//  Created by Olivia Gregory on 7/13/16.
//  Copyright © 2016 Angel Vázquez. All rights reserved.
//

import UIKit

class NowPlayingTableViewCell: UITableViewCell {

    @IBOutlet weak var albumCoverImageView: UIImageView!
    @IBOutlet weak var songNameLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
    //        self.imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"church-welcome.png"]];
        //        self.imageView.contentMode = UIViewContentModeScaleAspectFill;
        //        self.cachedImageViewSize = self.imageView.frame;
        //        [self.tableView addSubview:self.imageView];
        //        [self.tableView sendSubviewToBack:self.imageView];
        //        self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 170)];
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
