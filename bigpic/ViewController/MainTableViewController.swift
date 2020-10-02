//
//  MainTableViewController.swift
//  bigpic
//
//  Created by Cristian Sava on 22.09.20.
//  Copyright © 2020 Cristian Sava. All rights reserved.
//

import UIKit

class MainTableViewController: UITableViewController {

    private var documentsImages = Images(atPath: Utils.documentsPath)
    private var displayedImages = 0
    
    private var directoryMonitor = DirectoryMonitor(URL: NSURL(fileURLWithPath: Utils.documentsPath, isDirectory: true))
    // We consider all files to be images until proven otherwise (at loading time)
    private var currentImages: [String] = []
    private var directoryChangeTimer: Timer?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
        
        documentsImages.delegate = self
        directoryMonitor.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Fake a directory change to load up the initial images
        reactToDirectoryChange()
        
        directoryMonitor.startMonitoring()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        directoryMonitor.stopMonitoring()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayedImages
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ImageCell", for: indexPath) as! ImageTableViewCell

        assert(indexPath.row < documentsImages.count, "Wrong index logic")
        if let image = documentsImages[indexPath.row] {
            cell.initCell(withImage: image)
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "toImage", sender: indexPath)
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toImage", let indexPath = sender as? IndexPath, let image = documentsImages[indexPath.row] {
            let vc = segue.destination as! ImageViewController
            vc.image = image
        }
    }

}

// MARK: - Images Delegate

extension MainTableViewController: ImagesDelegate {
    
    func addedImage(atIndex index: Int) {
        displayedImages += 1
        if index > -1 && index < displayedImages {
            self.tableView.insertRows(at: [IndexPath(row: index, section: 0)], with: .fade)
        }
    }
    
    func removedImage(atIndex index: Int) {
        displayedImages -= 1
        if index > -1 && index <= displayedImages {
            self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .fade)
        }
    }
    
    func getThumbnailSize() -> CGSize {
        return CGSize(width: Image.defThumbnailWidth, height: Image.defThumbnailHeight)
    }
}

// MARK: - DirectoryMonitor

extension MainTableViewController: DirectoryMonitorDelegate {
    
    func directoryMonitorDidObserveChange(directoryMonitor: DirectoryMonitor) {
        Log.debug("Detected a change in Documents folder")
        
        /* These directory change notifications are generated in great numbers, usually one per
           each file. When multiple files are created/deleted as part of the same operation,
           this function is called multiple times in short succession.
           Instead of reacting concurrently to each and one of the notifications and waste resources,
           we will use a timer to detect the last notification and start processing the changes only
           at that time. */
        DispatchQueue.main.async {
            self.directoryChangeTimer?.invalidate()
            self.directoryChangeTimer = nil
            
            /* File operations are quite fast - especially when copying/deleting inside the Documents
               folder, 1s should be enough time to detect the end of the notifications series */
            self.directoryChangeTimer = Timer(timeInterval: 1.0, target: self, selector: #selector(self.reactToDirectoryChange), userInfo: nil, repeats: false)
            self.directoryChangeTimer!.tolerance = 0.5
            RunLoop.current.add(self.directoryChangeTimer!, forMode: RunLoop.Mode.common)
        }
    }
    
    @objc func reactToDirectoryChange() {
        directoryChangeTimer = nil
        
        Log.message("Processing a change in the Documents directory")
        documentsImages.searchForImages { [weak self] status, files in
            if status != .success {
                // Alternatively: this is a good place to use a precondition
                var alert: UIAlertController?
                switch status {
                case .imageSearchFailed(let errorText):
                    alert = Utils.createAlert(withText: "Failed to search for images: \(errorText)")
                default:
                    alert = Utils.createAlert(withText: "Unknown error")
                }
                
                self?.present(alert!, animated: true, completion: nil)
            } else {
                let addedImages = files.filter { !(self?.currentImages.contains($0) ?? false) }
                let removedImages = self?.currentImages.filter { !files.contains($0) }
                
                self?.currentImages = files
                
                // Remove the now missing images
                if let removedImages = removedImages, removedImages.count > 0 {
                    self?.documentsImages.removeImages(fromFiles: removedImages)
                }
                // Load and present the new images
                if addedImages.count > 0 {
                    self?.documentsImages.addImages(fromFiles: addedImages)
                }
            }
        }
    }
}
