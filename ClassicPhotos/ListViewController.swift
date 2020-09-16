import UIKit
import CoreImage

let dataSourceURL = URL(string:"http://www.raywenderlich.com/downloads/ClassicPhotosDictionary.plist")!

class ListViewController: UITableViewController {
  lazy var photos = NSDictionary(contentsOf: dataSourceURL)!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.title = "Classic Photos"
  }
  
  // MARK: - Table view data source

  override func tableView(_ tableView: UITableView?, numberOfRowsInSection section: Int) -> Int {
    return photos.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "CellIdentifier", for: indexPath) 
    let rowKey = photos.allKeys[indexPath.row] as! String
    
    var image : UIImage?

    guard let imageURL = URL(string:photos[rowKey] as! String),
      let imageData = try? Data(contentsOf: imageURL) else {
        return cell
    }

    //1
    let unfilteredImage = UIImage(data:imageData)
    //2
    image = self.applySepiaFilter(unfilteredImage!)

    // Configure the cell...
    cell.textLabel?.text = rowKey
    if image != nil {
      cell.imageView?.image = image!
    }
    
    return cell
  }
  
  // MARK: - image processing

  func applySepiaFilter(_ image:UIImage) -> UIImage? {
    let inputImage = CIImage(data:UIImagePNGRepresentation(image)!)
    let context = CIContext(options:nil)
    let filter = CIFilter(name:"CISepiaTone")
    filter?.setValue(inputImage, forKey: kCIInputImageKey)
    filter!.setValue(0.8, forKey: "inputIntensity")

    guard let outputImage = filter!.outputImage,
      let outImage = context.createCGImage(outputImage, from: outputImage.extent) else {
        return nil
    }
    return UIImage(cgImage: outImage)
  }
}
