//
//  TripDetailTableViewCell.swift
//  Journy
//
//  Created by Justin Goi on 6/5/2024.
//

import UIKit

class TripDetailTableViewCell: UITableViewCell {


    @IBOutlet weak var tripImage: UIImageView!
    @IBOutlet weak var tripDate: UILabel!
    @IBOutlet weak var tripName: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        tripImage.layer.cornerRadius = 10
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
