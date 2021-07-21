 
import UIKit
import Combine

extension UIViewController {
  
    func alert(title: String, text: String?) -> AnyPublisher<Void, Never> {
      let alertVC = UIAlertController(title: title,
                                      message: text,
                                      preferredStyle: .alert)
        
        return Future { resolve in
          alertVC.addAction(UIAlertAction(title: "Close",
                                          style: .default) { _ in
            // If the user taps the button, you resolve the future with success.
            resolve(.success(()))
          })

          self.present(alertVC, animated: true, completion: nil)
        }
        // in case the subscription gets canceled, you dismiss the alert automatically from within handleEvents(receiveCancel:).
        .handleEvents(receiveCancel: {
          self.dismiss(animated: true)
        })
        .eraseToAnyPublisher()
    }
 
}
