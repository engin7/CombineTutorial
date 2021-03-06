import Combine
import UIKit

class MainViewController: UIViewController {
  
  // MARK: - Outlets

  @IBOutlet weak var imagePreview: UIImageView! {
    didSet {
      imagePreview.layer.borderColor = UIColor.gray.cgColor
    }
  }
  @IBOutlet weak var buttonClear: UIButton!
  @IBOutlet weak var buttonSave: UIButton!
  @IBOutlet weak var itemAdd: UIBarButtonItem!

  // MARK: - Private properties
    // 1- subscriptions is the collection where you will store any UI subscriptions tied to the lifecycle of the current view controller. AnyCancellable is a type-erased type to allow storing cancelables of different types in the same collection.
    private var subscriptions = Set<AnyCancellable>()
    private let images = CurrentValueSubject<[UIImage], Never>([])


  // MARK: - View controller
  
  override func viewDidLoad() {
    super.viewDidLoad()
    let collageSize = imagePreview.frame.size
    
    // 1 begin a subscription to the current collection of photos.
    images
        // The handleEvents operator enables you to perform side effects when a publisher emits an event.
        // This will feed the current selection to updateUI(photos:) just before they are converted into a single collage image inside the map operator.
        .handleEvents(receiveOutput: { [weak self] photos in
            // method to change buttons state like not showing for odd
          self?.updateUI(photos: photos)
        })

      // 2 use map to convert them to a single collage
      .map { photos in
        // by calling extension helper method
        UIImage.collage(images: photos, size: collageSize)
      }
      // 3 bind the resulting collage image to imagePreview.image
      .assign(to: \.image, on: imagePreview)
      // 4 store the resulting subscription into subscriptions to tie its lifespan to the view controller if it’s not canceled earlier than the controller.
      .store(in: &subscriptions)

  }
  
  private func updateUI(photos: [UIImage]) {
    buttonSave.isEnabled = photos.count > 0 && photos.count % 2 == 0
    buttonClear.isEnabled = photos.count > 0
    itemAdd.isEnabled = photos.count < 6
    title = photos.count > 0 ? "\(photos.count) photos" : "Collage"
  }
  
  // MARK: - Actions
  
  @IBAction func actionClear() {
    images.send([])

  }
  
  @IBAction func actionSave() {
    guard let image = imagePreview.image else { return }
    
    // 1 subscribe the PhotoWriter.save(_) future by sink
    PhotoWriter.save(image)
      .sink(receiveCompletion: { [unowned self] completion in
        // 2 display alert in case of error
        if case .failure(let error) = completion {
          self.showMessage("Error", description: error.localizedDescription)
        }
        self.actionClear()
      }, receiveValue: { [unowned self] id in
        // In case you get back a value — the new asset id — let the user know their collage is saved successfully.
        self.showMessage("Saved with id: \(id)")
      })
      .store(in: &subscriptions)

  }
  
  @IBAction func actionAdd() {
    
    // add newImages to the current images array value and send that value through the subject, so all subscribers receive it.
//    let newImages = images.value + [UIImage(named: "IMG_1907.jpg")!]
//    images.send(newImages)
    
  
    let photos = storyboard!.instantiateViewController(
      withIdentifier: "PhotosViewController") as! PhotosViewController

    // subscribe photos.$selectedPhotosCount
    photos.$selectedPhotosCount
      .filter { $0 > 0 }
      .map { "Selected \($0) photos" }
    // bind it to the view controller’s title property.
      .assign(to: \.title, on: self)
      .store(in: &subscriptions)

    
    let newPhotos = photos.selectedPhotos
      .prefix(while: { [unowned self] _ in
        // keep the subscription to selectedPhotos alive as long as the total count of images selected is less than six.
        return self.images.value.count < 6
      })
      .share()

    newPhotos
      .map { [unowned self] newImage in
      // 1 Get the current list of selected images and append any new images to it.
        return self.images.value + [newImage]
      }
      // 2 Use assign to send the updated images array through the images subject.
      .assign(to: \.value, on: images)
      // 3 store the new subscription in subscriptions. However, the subscription will end whenever the user dismisses the presented view controller.
      .store(in: &subscriptions)
 
    
    newPhotos
        // ignore emitted values, only providing a completion event to the subscriber.
      .ignoreOutput()
      .delay(for: 2.0, scheduler: DispatchQueue.main)
      .sink(receiveCompletion: { [unowned self] _ in
        // after 2 secs delay in main thread call method to update title with selected number of photos
        self.updateUI(photos: self.images.value)
      }, receiveValue: { _ in })
      .store(in: &subscriptions)

    
    navigationController!.pushViewController(photos, animated: true)
 
  }
  
  private func showMessage(_ title: String, description: String? = nil) {
  
    alert(title: title, text: description)
      .sink(receiveValue: { _ in })
      .store(in: &subscriptions)

  }
}
