import SwiftUI
import UIKit

/// UIKit-backed text field that becomes first responder when `isFirstResponder` is true.
struct AutoFocusTextField: UIViewRepresentable {
    @Binding var text: String
    @Binding var isFirstResponder: Bool
    var onSubmit: () -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> UITextField {
        let tf = UITextField(frame: .zero)
        tf.placeholder = "Search address"
        tf.borderStyle = .roundedRect
        tf.returnKeyType = .search
        tf.delegate = context.coordinator
        tf.addTarget(context.coordinator, action: #selector(Coordinator.textChanged(_:)), for: .editingChanged)
        return tf
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        if isFirstResponder && !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
        } else if !isFirstResponder && uiView.isFirstResponder {
            uiView.resignFirstResponder()
        }
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: AutoFocusTextField
        
        init(_ parent: AutoFocusTextField) {
            self.parent = parent
        }
        
        @objc func textChanged(_ sender: UITextField) {
            parent.text = sender.text ?? ""
        }
        
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            parent.onSubmit()
            return true
        }
    }
}
