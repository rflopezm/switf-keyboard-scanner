import SwiftUI
import UIKit

struct ContentView: View {
    @State private var scannedBarcode: String = ""
    @State private var scanTime: Double = 0
    
    var body: some View {
        VStack {
            Text("Scan a barcode 2")
                .font(.title)
            Text("Scanned Barcode: \(scannedBarcode)")
                .font(.title)
            Text("Scan Time: \(scanTime, specifier: "%.2f") seconds")
                .font(.title)
            KeyPressViewRepresentable(scannedBarcode: $scannedBarcode, scanTime: $scanTime)
                .frame(width: 0, height: 0)
        }
    }
}

class KeyPressView: UIView {
    var currentScannedInput: String = ""
    var dispatchTimer: Timer?
    let dispatchDelay: TimeInterval = 0.1 // 100 milliseconds
    
    var barcodeUpdate: ((String, Double) -> Void)?
    var scanStartTime: Date?
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
//    override var keyCommands: [UIKeyCommand]? {
//        let keys = "abcdefghijklmnopqrstuvwxyz1234567890"
//        return keys.map { key in
//            UIKeyCommand(input: String(key), modifierFlags: [], action: #selector(keyPressed(_:)))
//        }
//    }
//    
//    @objc func keyPressed(_ command: UIKeyCommand) {
//        if let input = command.input {
//            addCharacterToCurrentInput(input)
//        }
//    }
//    
//    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
//        if let press = presses.first, let key = press.key {
//            let character = key.charactersIgnoringModifiers
//            if !character.isEmpty {
//                addCharacterToCurrentInput(character)
//            }
//        } else {
//            super.pressesBegan(presses, with: event)
//        }
//    }
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
            if let press = presses.first, let key = press.key {
                let character = key.characters
                if !character.isEmpty {
                    addCharacterToCurrentInput(character)
                }
            } else {
                super.pressesBegan(presses, with: event)
            }
        }
    
    func addCharacterToCurrentInput(_ character: String) {
        // Start the timer at the first character
        if currentScannedInput.isEmpty {
            scanStartTime = Date()
        }
        
        // Reset the timer each time a character is added
        dispatchTimer?.invalidate()
        
        // If the character is empty, dispatch immediately
        if character.isEmpty {
            dispatchInput()
            return
        }
        
        currentScannedInput.append(character)
        
        dispatchTimer = Timer.scheduledTimer(withTimeInterval: dispatchDelay, repeats: false) { [weak self] _ in
            self?.dispatchInput()
        }
    }
    
    func dispatchInput() {
        // Reset the timer
        dispatchTimer?.invalidate()
        dispatchTimer = nil
        
        let scanEndTime = Date()
        let timeElapsed = scanStartTime.flatMap { scanEndTime.timeIntervalSince($0) } ?? 0
        
        // Call the update handler
        barcodeUpdate?(currentScannedInput, timeElapsed)
        
        // Reset the scanned input
        currentScannedInput = ""
    }
}

struct KeyPressViewRepresentable: UIViewRepresentable {
    @Binding var scannedBarcode: String
    @Binding var scanTime: Double
    
    func makeUIView(context: Context) -> KeyPressView {
        let keyPressView = KeyPressView()
        keyPressView.barcodeUpdate = { barcode, time in
            DispatchQueue.main.async {
                self.scannedBarcode = barcode
                self.scanTime = time
            }
        }
        DispatchQueue.main.async {
            keyPressView.becomeFirstResponder()
        }
        return keyPressView
    }
    
    func updateUIView(_ uiView: KeyPressView, context: Context) {
        uiView.barcodeUpdate = { barcode, time in
            DispatchQueue.main.async {
                self.scannedBarcode = barcode
                self.scanTime = time
            }
        }
    }
}
