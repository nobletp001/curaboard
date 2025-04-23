import UIKit
import WebKit

// MARK: - WKNavigationDelegate
extension ActionViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        extractHighlightedText(from: webView)
    }

    private func extractHighlightedText(from webView: WKWebView) {
        let jsGetSelection = "window.getSelection().toString().trim()"

        webView.evaluateJavaScript(jsGetSelection) { [weak self] (result, error) in
            guard let self = self else { return }

            if let error = error {
                print("⚠️ JavaScript error: \(error.localizedDescription)")
            }

            if let selectedText = result as? String, !selectedText.isEmpty {
                print("✅ Extracted selected text: \(selectedText)")
                DispatchQueue.main.async {
                    self.showSwiftUIView(with: selectedText)
                }
            } else {
                self.extractFallbackContent(from: webView)
            }
        }
    }

    private func extractFallbackContent(from webView: WKWebView) {
        let jsFallback = """
            (function() {
                var selected = window.getSelection().toString().trim();
                if (selected) return selected;

                var meta = document.querySelector('meta[name="description"]');
                if (meta && meta.content) return meta.content;

                var h1 = document.querySelector('h1');
                if (h1) return h1.innerText;

                var p = document.querySelector('p');
                if (p) return p.innerText;

                var text = document.body ? document.body.innerText : '';
                return text.substring(0, 500) + '...';
            })();
        """

        webView.evaluateJavaScript(jsFallback) { [weak self] (result, error) in
            guard let self = self else { return }

            var fallbackText = "No text could be extracted."

            if let error = error {
                fallbackText = "⚠️ Fallback JS error: \(error.localizedDescription)"
                print(fallbackText)
            } else if let result = result as? String, !result.isEmpty {
                fallbackText = result
                print("🧠 Fallback extracted text: \(fallbackText)")
            }

            DispatchQueue.main.async {
                self.showSwiftUIView(with: fallbackText)
            }
        }
    }
}

