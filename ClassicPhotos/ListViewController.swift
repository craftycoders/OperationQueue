import UIKit
import CoreImage

let dataSourceURL = URL(string:"http://www.raywenderlich.com/downloads/ClassicPhotosDictionary.plist")!

class ListViewController: UITableViewController {
  var photos: [PhotoRecord] = []
  let pendingOperations = PendingOperations()

  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.title = "Classic Photos"
    fetchPhotoDetails()
  }
    
    func fetchPhotoDetails() {
      let request = URLRequest(url: dataSourceURL)
      UIApplication.shared.isNetworkActivityIndicatorVisible = true

      let task = URLSession(configuration: .default).dataTask(with: request) { data, response, error in

        let alertController = UIAlertController(title: "Oops!",
                                                message: "There was an error fetching photo details.",
                                                preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(okAction)

        if let data = data {
          do {
            let datasourceDictionary =
              try PropertyListSerialization.propertyList(from: data,
                                                         options: [],
                                                         format: nil) as! [String: String]

            for (name, value) in datasourceDictionary {
              let url = URL(string: value)
              if let url = url {
                let photoRecord = PhotoRecord(name: name, url: url)
                self.photos.append(photoRecord)
              }
            }

            DispatchQueue.main.async {
              UIApplication.shared.isNetworkActivityIndicatorVisible = false
              self.tableView.reloadData()
            }
          } catch {
            DispatchQueue.main.async {
              self.present(alertController, animated: true, completion: nil)
            }
          }
        }

        if error != nil {
          DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            self.present(alertController, animated: true, completion: nil)
          }
        }
      }
      task.resume()
    }

  
  override func tableView(_ tableView: UITableView?, numberOfRowsInSection section: Int) -> Int {
    return photos.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "CellIdentifier", for: indexPath)
    
    if cell.accessoryView == nil {
      let indicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
      cell.accessoryView = indicator
    }
    let indicator = cell.accessoryView as! UIActivityIndicatorView
    
    let photoDetails = photos[indexPath.row]
    
    cell.textLabel?.text = photoDetails.name
    cell.imageView?.image = photoDetails.image
    
    //4
    switch (photoDetails.state) {
    case .filtered:
      indicator.stopAnimating()
    case .failed:
      indicator.stopAnimating()
      cell.textLabel?.text = "Failed to load"
    case .new, .downloaded:
      indicator.startAnimating()
      startOperations(for: photoDetails, at: indexPath)
    }
    
    return cell
  }
    
    func startOperations(for photoRecord: PhotoRecord, at indexPath: IndexPath) {
        switch (photoRecord.state) {
        case .new:
            startDownload(for: photoRecord, at: indexPath)
        case .downloaded:
            startFiltration(for: photoRecord, at: indexPath)
        default:()
        }
    }
    
    func startDownload(for photoRecord: PhotoRecord, at indexPath: IndexPath) {
     
      guard pendingOperations.downloadsInProgress[indexPath] == nil else {
        return
      }
          
  
      let downloader = ImageDownloader(photoRecord)
      
  
      downloader.completionBlock = {
        if downloader.isCancelled {
          return
        }

        DispatchQueue.main.async {
          self.pendingOperations.downloadsInProgress.removeValue(forKey: indexPath)
          self.tableView.reloadRows(at: [indexPath], with: .fade)
        }
      }
      
   
      pendingOperations.downloadsInProgress[indexPath] = downloader
      
      pendingOperations.downloadQueue.addOperation(downloader)
    }
        
    func startFiltration(for photoRecord: PhotoRecord, at indexPath: IndexPath) {
      guard pendingOperations.filtrationsInProgress[indexPath] == nil else {
          return
      }
          
      let filterer = ImageFiltration(photoRecord)
      filterer.completionBlock = {
        if filterer.isCancelled {
          return
        }
        
        DispatchQueue.main.async {
          self.pendingOperations.filtrationsInProgress.removeValue(forKey: indexPath)
          self.tableView.reloadRows(at: [indexPath], with: .fade)
        }
      }
      
      pendingOperations.filtrationsInProgress[indexPath] = filterer
      pendingOperations.filtrationQueue.addOperation(filterer)
    }


}
