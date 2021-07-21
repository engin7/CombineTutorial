
import Foundation
import UIKit
import Photos

import Combine

class PhotoWriter {
  enum Error: Swift.Error {
    case couldNotSavePhoto
    case generic(Swift.Error)
  }
    
    // This function will try to asynchronously store the given image on disk and return a future that this API’s consumers will subscribe to.
    static func save(_ image: UIImage) -> Future<String, PhotoWriter.Error> {
      return Future { resolve in
        
        do {
            
            try PHPhotoLibrary.shared().performChangesAndWait {
              // 1  create a request to store image.
              let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
              
              // 2 attempt to get the newly-created asset’s identifier via request.placeholderForCreatedAsset?.localIdentifier
              guard let savedAssetID =
                request.placeholderForCreatedAsset?.localIdentifier else {
                // 3 If the creation has failed and you didn’t get an asset id back, you resolve the future with an error.
                return resolve(.failure(.couldNotSavePhoto))
              }

              // 4  in case you got back a savedAssetID, you resolve the future with success.
              resolve(.success(savedAssetID))
            }

            
        } catch {
          resolve(.failure(.generic(error)))
        }

        
      }
    }

    
  
}
