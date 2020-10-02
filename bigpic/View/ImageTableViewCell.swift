//
//  ImageTableViewCell.swift
//  bigpic
//
//  Created by Cristian Sava on 23.09.20.
//  Copyright © 2020 Cristian Sava. All rights reserved.
//

import UIKit

class ImageTableViewCell: UITableViewCell {

    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var dimensionsLabel: UILabel!
    @IBOutlet weak var sizeLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func initCell(withImage img: Image) {
        imgView.image = img.data
        nameLabel.text = img.name
        typeLabel.text = img.uti
        dimensionsLabel.text = "\(img.width)x\(img.height) px"
        sizeLabel.text = img.sizeAsString()
    }
}
