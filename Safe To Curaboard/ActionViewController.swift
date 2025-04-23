import UIKit
import SwiftUI
import MobileCoreServices
import UniformTypeIdentifiers
import WebKit

class ActionViewController: UIViewController {
    // MARK: - Properties
    @IBOutlet weak var imageView: UIImageView!
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Hide the template's image view since we're using SwiftUI
        imageView.isHidden = true
        
        // Extract text from the input items
        extractTextFromInput()
    }
    
    // MARK: - Helper Methods
    func extractTextFromInput() {
        // Get the input items from the extension context
        let inputItems = self.extensionContext?.inputItems as? [NSExtensionItem]
        
        guard let firstItem = inputItems?.first,
              let attachments = firstItem.attachments else {
            showSwiftUIView(with: "No input received")
            return
        }
        
        // First try to get plain text
        for attachment in attachments {
            if attachment.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                attachment.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] (data, error) in
                    if let error = error {
                        DispatchQueue.main.async {
                            self?.showSwiftUIView(with: "Error: \(error.localizedDescription)")
                        }
                        return
                    }
                    
                    var extractedText = "No text found"
                    
                    if let text = data as? String {
                        extractedText = text
                    } else if let data = data as? Data, let text = String(data: data, encoding: .utf8) {
                        extractedText = text
                    }
                    
                    DispatchQueue.main.async {
                        self?.showSwiftUIView(with: extractedText)
                    }
                }
                return
            }
        }
        
        // If plain text failed, try to get HTML
        for attachment in attachments {
            if attachment.hasItemConformingToTypeIdentifier("public.html") {
                attachment.loadItem(forTypeIdentifier: "public.html", options: nil) { [weak self] (data, error) in
                    if let error = error {
                        DispatchQueue.main.async {
                            self?.showSwiftUIView(with: "Error: \(error.localizedDescription)")
                        }
                        return
                    }
                    
                    var extractedText = "No text found"
                    
                    if let htmlString = data as? String {
                        // Extract text from HTML
                        extractedText = self?.extractTextFromHTML(htmlString) ?? "Failed to extract text from HTML"
                    } else if let data = data as? Data, let htmlString = String(data: data, encoding: .utf8) {
                        extractedText = self?.extractTextFromHTML(htmlString) ?? "Failed to extract text from HTML"
                    }
                    
                    DispatchQueue.main.async {
                        self?.showSwiftUIView(with: extractedText)
                    }
                }
                return
            }
        }
        
        // If we get here, try to get URL and load the webpage to extract the selection
        for attachment in attachments {
            if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                attachment.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] (data, error) in
                    if let url = data as? URL {
                        DispatchQueue.main.async {
                            self?.loadWebPageAndExtractSelection(url)
                        }
                    } else {
                        DispatchQueue.main.async {
                            self?.showSwiftUIView(with: "Could not get URL from selection")
                        }
                    }
                }
                return
            }
        }
        
        // If we get here, we couldn't find text
        showSwiftUIView(with: "No text found in selection. Try selecting some text first.")
    }
    
    func extractTextFromHTML(_ html: String) -> String {
        // Simple HTML to text extraction
        // For a more sophisticated approach, consider using a HTML parser
        var text = html
        // Remove script tags
        text = text.replacingOccurrences(of: "<script[^>]*>[\\s\\S]*?</script>", with: "", options: .regularExpression)
        // Remove style tags
        text = text.replacingOccurrences(of: "<style[^>]*>[\\s\\S]*?</style>", with: "", options: .regularExpression)
        // Replace HTML tags with spaces
        text = text.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
        // Replace multiple spaces with single space
        text = text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        // Decode HTML entities
        text = text.replacingOccurrences(of: "&nbsp;", with: " ")
        text = text.replacingOccurrences(of: "&amp;", with: "&")
        text = text.replacingOccurrences(of: "&lt;", with: "<")
        text = text.replacingOccurrences(of: "&gt;", with: ">")
        text = text.replacingOccurrences(of: "&quot;", with: "\"")
        text = text.replacingOccurrences(of: "&apos;", with: "'")
        
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func loadWebPageAndExtractSelection(_ url: URL) {
        let webView = WKWebView()
        webView.navigationDelegate = self
        
        // Load the web page
        let request = URLRequest(url: url)
        webView.load(request)
        
        // Add webView to view hierarchy (hidden)
        webView.isHidden = true
        view.addSubview(webView)
        
        // Show loading indicator
        showSwiftUIView(with: "Loading webpage to extract text...")
    }
    
    func showSwiftUIView(with text: String) {
        // Create the SwiftUI view
        let curaboardView = CuraboardView(extractedText: text) {
            // On done
            self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        }
        
        // Create and configure a hosting controller
        let hostingController = UIHostingController(rootView: curaboardView)
        addChild(hostingController)
        
        // Add the hosting controller's view to the view hierarchy
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingController.view)
        
        // Setup constraints to fill the view
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        hostingController.didMove(toParent: self)
    }
}
