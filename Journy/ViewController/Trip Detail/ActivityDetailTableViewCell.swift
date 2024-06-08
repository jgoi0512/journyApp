//
//  ActivityDetailTableViewCell.swift
//  Journy
//
//  Created by Justin Goi on 7/6/2024.
//

import UIKit

class ActivityDetailTableViewCell: UITableViewCell {

    @IBOutlet weak var activityNameLabel: UILabel!
    @IBOutlet weak var activityLocationLabel: UILabel!
    @IBOutlet weak var activityDateLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
