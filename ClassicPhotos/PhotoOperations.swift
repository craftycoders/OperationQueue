import UIKit

// This enum contains all the possible states a photo record can be in
enum PhotoRecordState {
  case new, downloaded, filtered, failed
}

class PhotoRecord {
  let name: String
  let url: URL
  var state = PhotoRecordState.new
  var image = UIImage(named: "Placeholder")
  
  init(name:String, url:URL) {
    self.name = name
    self.url = url
  }
}

class PendingOperations {
  lazy var downloadsInProgress: [IndexPath: Operation] = [:]
  lazy var downloadQueue: OperationQueue = {
    var queue = OperationQueue()
    queue.name = "Download queue"
    queue.maxConcurrentOperationCount = 1
    return queue
  }()
  
  lazy var filtrationsInProgress: [IndexPath: Operation] = [:]
  lazy var filtrationQueue: OperationQueue = {
    var queue = OperationQueue()
    queue.name = "Image Filtration queue"
    queue.maxConcurrentOperationCount = 1
    return queue
  }()
}

class ImageDownloader: Operation {
  let photoRecord: PhotoRecord
  
  init(_ photoRecord: PhotoRecord) {
    self.photoRecord = photoRecord
  }
  
  override func main() {
    if isCancelled {
      return
    }

    guard let imageData = try? Data(contentsOf: photoRecord.url) else { return }
    
    if isCancelled {
      return
    }

    if !imageData.isEmpty {
      photoRecord.image = UIImage(data:imageData)
      photoRecord.state = .downloaded
    } else {
      photoRecord.state = .failed
      photoRecord.image = UIImage(named: "Failed")
    }
  }
}



