import SwiftUI
import UIKit
import UniformTypeIdentifiers

class ShareViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard
            let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
            let itemProvider = extensionItem.attachments?.first else {
            close()
            return
        }
        
        let textDataType = UTType.plainText.identifier
        
        if itemProvider.hasItemConformingToTypeIdentifier(textDataType) {
            itemProvider.loadItem(forTypeIdentifier: textDataType, options: nil) { (item, error) in
                if let error {
                    print("Error loading item: \(error.localizedDescription)")
                    self.close()
                    return
                }
                
                if let text = item as? NSString {
                    DispatchQueue.main.async {
                        let contentView = UIHostingController(rootView: ShareExtensionView(text: text as String))
                        self.addChild(contentView)
                        self.view.addSubview(contentView.view)
                        
                        contentView.view.translatesAutoresizingMaskIntoConstraints = false
                        NSLayoutConstraint.activate([
                            contentView.view.topAnchor.constraint(equalTo: self.view.topAnchor),
                            contentView.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
                            contentView.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                            contentView.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
                        ])
                    }
                } else {
                    self.close()
                }
            }
        } else {
            close()
        }

        NotificationCenter.default.addObserver(forName: NSNotification.Name("close"), object: nil, queue: .main) { _ in
            self.close()
        }
    }
    
    func close() {
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}
