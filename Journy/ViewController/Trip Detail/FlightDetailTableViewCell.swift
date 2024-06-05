//
//  FlightDetailTableViewCell.swift
//  Journy
//
//  Created by Justin Goi on 3/6/2024.
//

import UIKit

class FlightDetailTableViewCell: UITableViewCell {

    
    @IBOutlet weak var flightImageView: UIImageView!
    @IBOutlet weak var lineView: UIView!
    
    @IBOutlet weak var departureTimeLabel: UILabel!
    @IBOutlet weak var arrivalTimeLabel: UILabel!
    @IBOutlet weak var departureAirportLabel: UILabel!
    @IBOutlet weak var arrivalAirportLabel: UILabel!
    @IBOutlet weak var flightNoLabel: UILabel!
    @IBOutlet weak var terminalLabel: UILabel!
    @IBOutlet weak var boardingGateLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
