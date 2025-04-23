import SwiftUI

struct CuraboardView: View {
    let extractedText: String
    let onDismiss: () -> Void
    
    @State private var showingSavedConfirmation = false
    @State private var isProcessing = false
    @State private var textPreview: String
    @State private var showingFullTextSheet = false
    
    init(extractedText: String, onDismiss: @escaping () -> Void) {
        self.extractedText = extractedText
        self.onDismiss = onDismiss
        
        // Initialize with a preview of the text (first 100 characters)
        if extractedText.count > 100 {
            let index = extractedText.index(extractedText.startIndex, offsetBy: 100)
            self._textPreview = State(initialValue: String(extractedText[..<index]) + "...")
        } else {
            self._textPreview = State(initialValue: extractedText)
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Preview card that opens the full text sheet when tapped
            VStack(alignment: .leading, spacing: 8) {
                Text("Text Preview")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                Text(textPreview)
                    .lineLimit(3)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .onTapGesture {
                        showingFullTextSheet = true
                    }
                
                Button(action: {
                    showingFullTextSheet = true
                }) {
                    Text("View Full Text")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                .padding(.horizontal)
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Save button at the bottom
            Button(action: saveTosCuraboard) {
                HStack {
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text("Save To Curaboard")
                            .fontWeight(.medium)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(isProcessing)
            .padding(.horizontal)
            .padding(.bottom)
        }
        .navigationBarTitle("Save To Curaboard", displayMode: .inline)
        .navigationBarItems(trailing: Button("Done") {
            onDismiss()
        })
        .alert(isPresented: $showingSavedConfirmation) {
            Alert(
                title: Text("Saved to Curaboard"),
                message: Text("The selected text has been saved to your Curaboard."),
                dismissButton: .default(Text("OK")) {
                    onDismiss()
                }
            )
        }
        .sheet(isPresented: $showingFullTextSheet) {
            FullTextView(text: extractedText)
        }
    }
    
    private func saveTosCuraboard() {
        isProcessing = true
        
        // Simulate networking delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            if let userDefaults = UserDefaults(suiteName: "group.com.yourcompany.curaboard") {
                // Save the current text
                userDefaults.set(extractedText, forKey: "lastSavedText")
                
                // Append to the array of saved texts
                var savedTexts = userDefaults.array(forKey: "savedTexts") as? [String] ?? []
                savedTexts.append(extractedText)
                userDefaults.set(savedTexts, forKey: "savedTexts")
                
                userDefaults.synchronize()
            }
            
            isProcessing = false
            showingSavedConfirmation = true
        }
    }
}

// New view for displaying the full text in a sheet
struct FullTextView: View {
    let text: String
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                Text(text)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationBarTitle("Full Text", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        UIPasteboard.general.string = text
                    }) {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                }
            }
        }
    }
}
