//
//  ImageViewController.swift
//  bigpic
//
//  Created by Cristian Sava on 27.09.20.
//  Copyright © 2020 Cristian Sava. All rights reserved.
//

import UIKit

class ImageViewController: UIViewController, UIScrollViewDelegate {

    var image: Image?
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        scrollView.delegate = self
        
        if image != nil {
            DispatchQueue.global().async { [weak self] in
                let (status, uiImage) = self?.image?.getOriginalImage() ?? (Status.unknown, nil)
                
                DispatchQueue.main.async {
                    self?.loadingIndicator.stopAnimating()
                    
                    if status != .success {
                        var alert: UIAlertController?
                        switch status {
                        case .imageLoadFailed(let errorText):
                            alert = Utils.createAlert(withText: errorText)
                        default:
                            alert = Utils.createAlert(withText: "Unknown error")
                        }
                        
                        self?.present(alert!, animated: true, completion: nil)
                    } else {
                        self?.imageView.image = uiImage
                    }
                }
            }
        }
    }
    
    // MARK: - UIScrollViewDelegate
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

}
