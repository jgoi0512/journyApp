//
//  AccommodationDetailTableViewCell.swift
//  Journy
//
//  Created by Justin Goi on 6/6/2024.
//

import UIKit

class AccommodationDetailTableViewCell: UITableViewCell {

    @IBOutlet weak var accommodationNameLabel: UILabel!
    @IBOutlet weak var accommodationLocationLabel: UILabel!
    @IBOutlet weak var checkInDateLabel: UILabel!
    @IBOutlet weak var checkOutDateLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
