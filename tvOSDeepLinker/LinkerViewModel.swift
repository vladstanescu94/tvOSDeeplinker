import Foundation
import UIKit

class LinkerViewModel: ObservableObject {
    @Published var deeplinks: [Deeplink] = Deeplink.mocked
    @Published var selectedDeeplink: Deeplink = .init(urlString: "", type: .noType)
    @Published var showManual: Bool = false
    @Published var manualLinkFieldValue: String = "mgmplus://"
    
    func openDeeplink() {
        let url = URL(string: showManual ? self.manualLinkFieldValue : self.selectedDeeplink.urlString)
        
        guard let url else {
            print("Invalid url string")
            return
        }
        
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}
