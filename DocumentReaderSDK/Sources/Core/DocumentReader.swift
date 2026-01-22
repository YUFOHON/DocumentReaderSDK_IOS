import UIKit
import Foundation

public protocol DocumentReaderDelegate: AnyObject {
    func documentReader(_ reader: DocumentReader, didScanMRZ data: [String: String])
    func documentReader(_ reader: DocumentReader, didReadPassport data: PassportReader.PassportData)
    func documentReader(_ reader: DocumentReader, didReadEEP data: EepDocumentReader.DocumentData)
    func documentReader(_ reader: DocumentReader, didFailWithError error: Error)
}

public class DocumentReader {
    
    // MARK: - Properties
    public weak var delegate: DocumentReaderDelegate?
    private let passportReader = PassportReader()
    private let eepReader = EepDocumentReader()
    
    public init() {}  // ADD THIS LINE

    
    // MARK: - Public Methods
    
    /// Present MRZ Scanner
    public func scanMRZ(from viewController: UIViewController) {
        let cameraVC = CameraViewController()
        cameraVC.delegate = self
        viewController.present(cameraVC, animated: true)
    }
    
    /// Read Passport NFC
    @MainActor public func readPassport(mrzKey: String) {
        print("trigger 1")
        passportReader.readPassport(mrzKey: mrzKey) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let data):
                self.delegate?.documentReader(self, didReadPassport: data)
            case .failure(let error):
                self.delegate?.documentReader(self, didFailWithError: error)
            }
        }
    }
    
    /// Read EEP NFC
    public func readEEP(mrzKey: String) {
//        let authData = EepDocumentReader.AuthData(
//            documentNumber: documentNumber,
//            dateOfBirth: dateOfBirth,
//            dateOfExpiry: expiryDate
//        )
        
        eepReader.readDocument(mrzKey: mrzKey) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let data):
                self.delegate?.documentReader(self, didReadEEP: data)
            case .failure(let error):
                self.delegate?.documentReader(self, didFailWithError: error)
            }
        }
    }
    
    /// Generate MRZ Key
    public static func generateMRZKey(documentNumber: String, dateOfBirth: String, expiryDate: String) -> String {
        // Extract from your ViewController logic
        let paddedDocNum = padDocumentNumber(documentNumber)
        let docCheckDigit = calculateCheckDigit(paddedDocNum)
        let dobCheckDigit = calculateCheckDigit(dateOfBirth)
        let expiryCheckDigit = calculateCheckDigit(expiryDate)
        
        return paddedDocNum + docCheckDigit + dateOfBirth + dobCheckDigit + expiryDate + expiryCheckDigit
    }
    
    // MARK: - Private Helpers (from ViewController)
    private static func calculateCheckDigit(_ input: String) -> String {
        let weights = [7, 3, 1]
        var sum = 0
        
        for (index, char) in input.enumerated() {
            let value: Int
            if char.isNumber {
                value = Int(String(char)) ?? 0
            } else if char == "<" {
                value = 0
            } else {
                let asciiValue = char.uppercased().unicodeScalars.first?.value ?? 0
                value = Int(asciiValue) - 55
            }
            sum += value * weights[index % 3]
        }
        
        return String(sum % 10)
    }
    
    private static func padDocumentNumber(_ docNum: String) -> String {
        var padded = docNum.uppercased()
        while padded.count < 9 {
            padded += "<"
        }
        return String(padded.prefix(9))
    }
}

// MARK: - CameraViewControllerDelegate
extension DocumentReader: CameraViewControllerDelegate {
    public func cameraViewController(_ controller: CameraViewController, didScanMRZ data: [String: String]) {
        delegate?.documentReader(self, didScanMRZ: data)
    }
}
