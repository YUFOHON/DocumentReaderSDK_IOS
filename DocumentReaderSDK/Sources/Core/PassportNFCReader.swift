import Foundation
import UIKit
import NFCPassportReader
import CoreNFC

// MARK: - Main Passport Reader Class
public class PassportReader {
    
    // MARK: - Authentication Method Enum
    public enum AuthMethod: String {
        case pace = "PACE"
        case bac = "BAC"
        case none = "NONE"
    }
    
    // MARK: - Comprehensive Passport Data Structure
    public struct PassportData {
        // SOD - Security Object Document
        public var hasValidSignature: Bool = false
        public var signingCountry: String?
        public var documentSignerCertificate: String?
        public var rawSODData: Data?
        public var dataGroupHashes: [DataGroupId: [UInt8]] = [:]
        
        // DG1 - MRZ (Machine Readable Zone) - MANDATORY
        public var documentCode: String?
        public var issuingState: String?
        public var lastName: String?
        public  var firstName: String?
        public var documentNumber: String?
        public var nationality: String?
        public var dateOfBirth: String?
        public var gender: String?
        public var dateOfExpiry: String?
        public var optionalData1: String?
        public var optionalData2: String?
        
        // DG2 - Facial Image - MANDATORY
        public  var faceImages: [UIImage] = []
        public var faceImageMimeTypes: [String] = []
        
        // DG3 - Fingerprints (EAC Protected)
        public var fingerprints: [FingerData] = []
        public var hasFingerprintData: Bool = false
        
        // DG4 - Iris Images (EAC Protected)
        public var irisScans: [IrisData] = []
        public var hasIrisData: Bool = false
        
        // DG5 - Displayed Portrait
        public var displayedPortrait: UIImage?
        
        // DG6 - Reserved for Future Use
        public var dg6Data: Data?
        
        // DG7 - Displayed Signature
        public var signatureImage: UIImage?
        public var signatureImageData: Data?
        
        // DG8 - Data Features (Visual security)
        public var dataFeatures: [DataFeature] = []
        
        // DG9 - Structure Features (Physical security)
        public var structureFeatures: [StructureFeature] = []
        
        // DG10 - Substance Features (Material composition)
        public var substanceFeatures: [SubstanceFeature] = []
        
        // DG11 - Additional Personal Details
        public var fullName: String?
        public var otherNames: [String] = []
        public var personalNumber: String?
        public var placeOfBirth: [String] = []
        public var dateOfBirth_Full: String?
        public var address: [String] = []
        public var telephone: String?
        public var profession: String?
        public var title: String?
        public var personalSummary: String?
        public var proofOfCitizenship: Data?
        public var otherValidTravelDocNumbers: [String] = []
        public var custodyInformation: String?
        
        // DG12 - Additional Document Details
        public var issuingAuthority: String?
        public var dateOfIssue: String?
        public var namesOfOtherPersons: [String] = []
        public var endorsementsAndObservations: String?
        public var taxOrExitRequirements: String?
        public var imageOfFront: Data?
        public var imageOfRear: Data?
        public var dateAndTimeOfPersonalization: String?
        public var personalizationSystemSerialNumber: String?
        
        // DG13 - Optional Details
        public var optionalDetailsData: Data?
        
        // DG14 - Security Options
        public var hasChipAuthentication: Bool = false
        public var hasTerminalAuthentication: Bool = false
        public var chipAuthAlgorithm: String?
        public var supportedSecurityProtocols: [String] = []
        
        // DG15 - Active Authentication
        public var hasActiveAuthentication: Bool = false
        public var activeAuthPublicKey: String?
        public var activeAuthAlgorithm: String?
        
        // DG16 - Emergency Contacts
        public var emergencyContacts: [EmergencyContact] = []
        
        // COM - Available Data Groups
        public var availableDataGroups: [Int] = []
        
        // Metadata
        public var authenticationMethod: AuthMethod = .none
        public var chipAuthenticationPerformed: Bool = false
        public var activeAuthenticationPerformed: Bool = false
        public var passportType: String?
        
    }
    
    // MARK: - Helper Data Structures
    public struct FingerData {
        var fingerImage: UIImage?
        var fingerImageData: Data?
        var position: Int = 0
        var imageFormat: String?
        var width: Int = 0
        var height: Int = 0
    }
    
    public struct IrisData {
        var irisImage: UIImage?
        var irisImageData: Data?
        var eyeLabel: String?
        var imageFormat: String?
    }
    
    public struct EmergencyContact {
        var name: String?
        var telephone: String?
        var address: String?
        var message: String?
    }
    
    public struct DataFeature {
        var featureType: String?
        var featureData: Data?
        var description: String?
    }
    
    public struct StructureFeature {
        var featureType: String?
        var featureData: Data?
        var description: String?
    }
    
    public struct SubstanceFeature {
        var substanceType: String?
        var substanceData: Data?
        var description: String?
    }
    
    // MARK: - Main Read Function
    @MainActor
    public func readPassport(
        mrzKey: String,
        completion: @escaping (Result<PassportData, Error>) -> Void
    ) {
        print("🔊 [PassportReader] START: readPassport called")
        print("🔊 [PassportReader] MRZ Key: \(mrzKey.prefix(10))...")
        print("🔊 [PassportReader] Main Thread: \(Thread.isMainThread)")
        
        guard NFCNDEFReaderSession.readingAvailable else {
            completion(.failure(NSError(domain: "PassportReader", code: 1001, userInfo: [NSLocalizedDescriptionKey: "NFC not available on this device"])))
            return
        }
        
        
        Task {
            print("🔊 [PassportReader] Task started on Main Thread: \(Thread.isMainThread)")

            do {
                print("🔊 [PassportReader] Creating NFCPassportReader instance...")

                let nfcReader = NFCPassportReader.PassportReader()
                
                // Add debug callback
//                NotificationCenter.default.addObserver(
//                    forName: Notification.Name("NFCTagReaderSessionDidBecomeActive"),
//                    object: nil,
//                    queue: .main
//                ) { _ in
//                    print("📱✅ [PassportReader] NFC Session ACTIVE - Ready for passport!")
//                }
//                
//                // Add timeout monitor
//                DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
//                    print("⏱️ [PassportReader] 10 seconds passed - NFC session not started?")
//                }
                
                // Read passport with custom display messages
                let nfcPassport = try await nfcReader.readPassport(
                    mrzKey: mrzKey,
                    tags: [], // Empty array reads all available data groups
                    skipSecureElements: false,
                    customDisplayMessage: { displayMessage in
                        switch displayMessage {
                        case .requestPresentPassport:
                            return "Hold your iPhone near an e-Passport"
                        case .authenticatingWithPassport(let progress):
                            return "Authenticating... \(progress)%"
                        case .readingDataGroupProgress(let tag, let progress):
                            return "Reading \(tag.getName())... (\(progress)%)"
                        case .successfulRead:
                            return "✅ Success!"
                        case .error(let error):
                            return "Error: \(error.localizedDescription)"
                        case .activeAuthentication:
                            return "activeAuthentication"
                        }
                    }
                )
                
                print("✅ Passport read completed successfully")
                
                // Convert to our data structure
                let passportData = self.convertToPassportData(nfcPassport)
                
                await MainActor.run {
                    completion(.success(passportData))
                }
                
            } catch {
                print("❌ [PassportReader] Error in readPassport: \(error)")
                print("❌ [PassportReader] Error type: \(type(of: error))")
                print("❌ [PassportReader] Error code: \((error as NSError).code)")
                print("❌ [PassportReader] Error domain: \((error as NSError).domain)")
                print("❌ [PassportReader] Error userInfo: \((error as NSError).userInfo)")
                
                await MainActor.run {
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Convert NFCPassportModel to PassportData
    private func convertToPassportData(_ passport: NFCPassportModel) -> PassportData {
        var data = PassportData()
        
        print("📖 Converting passport data from all data groups...")
        
        // Determine authentication method
        if passport.isPACESupported {
            data.authenticationMethod = .pace
            data.supportedSecurityProtocols.append("PACE")
        } else if passport.BACStatus == .success {
            data.authenticationMethod = .bac
            data.supportedSecurityProtocols.append("BAC")
        }
        
        // COM - Available Data Groups
        if let com = passport.getDataGroup(.COM) as? COM {
            data.availableDataGroups = com.dataGroupsPresent.compactMap { Int($0) }
            print("✓ COM: Available DGs: \(data.availableDataGroups)")
        }
        
        // Read all data groups
        readSOD(passport: passport, into: &data)
        readDG1(passport: passport, into: &data)
        readDG2(passport: passport, into: &data)
        readDG3(passport: passport, into: &data)
        readDG4(passport: passport, into: &data)
        readDG5(passport: passport, into: &data)
        readDG6(passport: passport, into: &data)
        readDG7(passport: passport, into: &data)
        readDG8(passport: passport, into: &data)
        readDG9(passport: passport, into: &data)
        readDG10(passport: passport, into: &data)
        readDG11(passport: passport, into: &data)
        readDG12(passport: passport, into: &data)
        readDG13(passport: passport, into: &data)
        readDG14(passport: passport, into: &data)
        readDG15(passport: passport, into: &data)
        readDG16(passport: passport, into: &data)
        
        // Authentication status
        data.activeAuthenticationPerformed = passport.activeAuthenticationPassed
        data.chipAuthenticationPerformed = passport.chipAuthenticationStatus == .success
        
        print("✅ Conversion complete - All data groups processed")
        
        return data
    }
    
    // MARK: - Data Group Readers
    
    private func readSOD(passport: NFCPassportModel, into data: inout PassportData) {
        guard let sod = passport.getDataGroup(.SOD) else {
            print("⚠️ SOD not available")
            return
        }
        
        print("🔏 Reading SOD...")
        
        data.rawSODData = Data(sod.body)
        data.hasValidSignature = passport.passportCorrectlySigned
        
        // Store data group hashes
        for (dgId, hash) in passport.dataGroupHashes {
            data.dataGroupHashes[dgId] = hash.computedHash.map { UInt8(String($0), radix: 16) ?? 0 }
        }
        
        // Get certificate info
        if let cert = passport.documentSigningCertificate {
            data.documentSignerCertificate = cert.certToPEM()
            data.signingCountry = cert.getIssuerName()
        }
        
        print("✓ SOD: \(data.rawSODData?.count ?? 0) bytes, Valid: \(data.hasValidSignature)")
    }
    
    private func readDG1(passport: NFCPassportModel, into data: inout PassportData) {
        guard let dg1 = passport.getDataGroup(.DG1) as? DataGroup1 else {
            print("⚠️ DG1 not available")
            return
        }
        
        print("📄 Reading DG1 (MRZ)...")
        
        data.documentCode = passport.documentType
        data.issuingState = passport.issuingAuthority
        data.lastName = passport.lastName
        data.firstName = passport.firstName
        data.documentNumber = passport.documentNumber
        data.nationality = passport.nationality
        data.dateOfBirth = passport.dateOfBirth
        data.gender = passport.gender
        data.dateOfExpiry = passport.documentExpiryDate
        
        // Get optional data from elements dictionary
        data.optionalData1 = dg1.elements["5F1F"]
        data.optionalData2 = dg1.elements["5F1D"]
        
        print("✓ DG1: \(data.firstName ?? "") \(data.lastName ?? "") (\(data.nationality ?? ""))")
    }
    
    private func readDG2(passport: NFCPassportModel, into data: inout PassportData) {
        guard let dg2 = passport.getDataGroup(.DG2) as? DataGroup2 else {
            print("⚠️ DG2 not available")
            return
        }
        
        print("📸 Reading DG2 (Face Image)...")
        
        // Get face image from passport model
        if let faceImage = passport.passportImage {
            data.faceImages.append(faceImage)
            data.faceImageMimeTypes.append("image/jpeg2000")
        }
        
        print("✓ DG2: \(data.faceImages.count) image(s)")
    }
    
    private func readDG3(passport: NFCPassportModel, into data: inout PassportData) {
        guard let dg3 = passport.getDataGroup(.DG3) else {
            print("⚠️ DG3 not available (requires EAC)")
            return
        }
        
        print("👆 Reading DG3 (Fingerprints)...")
        data.hasFingerprintData = true
        print("✓ DG3: Present (requires EAC to read)")
    }
    
    private func readDG4(passport: NFCPassportModel, into data: inout PassportData) {
        guard let dg4 = passport.getDataGroup(.DG4) else {
            print("⚠️ DG4 not available (requires EAC)")
            return
        }
        
        print("👁️ Reading DG4 (Iris)...")
        data.hasIrisData = true
        print("✓ DG4: Present (requires EAC to read)")
    }
    
    private func readDG5(passport: NFCPassportModel, into data: inout PassportData) {
        guard let dg5 = passport.getDataGroup(.DG5) else {
            print("⚠️ DG5 not available")
            return
        }
        
        print("🖼️ Reading DG5 (Displayed Portrait)...")
        // DG5 contains displayed portrait - usually same as DG2
        print("✓ DG5: Portrait data present")
    }
    
    private func readDG6(passport: NFCPassportModel, into data: inout PassportData) {
        guard let dg6 = passport.getDataGroup(.DG6) else {
            print("⚠️ DG6 not available")
            return
        }
        
        print("📦 Reading DG6 (Reserved)...")
        data.dg6Data = Data(dg6.body)
        print("✓ DG6: \(dg6.body.count) bytes")
    }
    
    private func readDG7(passport: NFCPassportModel, into data: inout PassportData) {
        guard let dg7 = passport.getDataGroup(.DG7) as? DataGroup7 else {
            print("⚠️ DG7 not available")
            return
        }
        
        print("✍️ Reading DG7 (Signature)...")
        
        if let signatureImage = passport.signatureImage {
            data.signatureImage = signatureImage
            data.signatureImageData = Data(dg7.imageData)
        }
        
        print("✓ DG7: Signature image")
    }
    
    private func readDG8(passport: NFCPassportModel, into data: inout PassportData) {
        guard let dg8 = passport.getDataGroup(.DG8) else {
            print("⚠️ DG8 not available")
            return
        }
        
        print("🔍 Reading DG8 (Data Features)...")
        
        let feature = DataFeature(
            featureType: "Visual Security Features",
            featureData: Data(dg8.body),
            description: "Holograms, UV patterns, microprinting, etc."
        )
        data.dataFeatures.append(feature)
        
        print("✓ DG8: \(dg8.body.count) bytes")
    }
    
    private func readDG9(passport: NFCPassportModel, into data: inout PassportData) {
        guard let dg9 = passport.getDataGroup(.DG9) else {
            print("⚠️ DG9 not available")
            return
        }
        
        print("🏗️ Reading DG9 (Structure Features)...")
        
        let feature = StructureFeature(
            featureType: "Physical Structure Features",
            featureData: Data(dg9.body),
            description: "RFID chip info, security threads, watermarks, etc."
        )
        data.structureFeatures.append(feature)
        
        print("✓ DG9: \(dg9.body.count) bytes")
    }
    
    private func readDG10(passport: NFCPassportModel, into data: inout PassportData) {
        guard let dg10 = passport.getDataGroup(.DG10) else {
            print("⚠️ DG10 not available")
            return
        }
        
        print("⚗️ Reading DG10 (Substance Features)...")
        
        let feature = SubstanceFeature(
            substanceType: "Material Composition Features",
            substanceData: Data(dg10.body),
            description: "Ink types, paper composition, chemical markers, etc."
        )
        data.substanceFeatures.append(feature)
        
        print("✓ DG10: \(dg10.body.count) bytes")
    }
    
    private func readDG11(passport: NFCPassportModel, into data: inout PassportData) {
        guard let dg11 = passport.getDataGroup(.DG11) as? DataGroup11 else {
            print("⚠️ DG11 not available")
            return
        }
        
        print("ℹ️ Reading DG11 (Personal Details)...")
        
        data.fullName = dg11.fullName
        data.personalNumber = dg11.personalNumber ?? passport.personalNumber
        data.dateOfBirth_Full = dg11.dateOfBirth
        data.telephone = dg11.telephone ?? passport.phoneNumber
        data.profession = dg11.profession
        data.title = dg11.title
        data.personalSummary = dg11.personalSummary
        
        // Handle optional fields
        if let placeOfBirth = dg11.placeOfBirth ?? passport.placeOfBirth {
            data.placeOfBirth = [placeOfBirth]
        }
        
        if let address = dg11.address ?? passport.residenceAddress {
            data.address = [address]
        }
        
        if let citizenship = dg11.proofOfCitizenship {
            data.proofOfCitizenship = Data(citizenship.utf8)
        }
        
        if let tdNumbers = dg11.tdNumbers {
            data.otherValidTravelDocNumbers = [tdNumbers]
        }
        
        data.custodyInformation = dg11.custodyInfo
        
        print("✓ DG11: Extended personal data")
    }
    
    private func readDG12(passport: NFCPassportModel, into data: inout PassportData) {
        guard let dg12 = passport.getDataGroup(.DG12) as? DataGroup12 else {
            print("⚠️ DG12 not available")
            return
        }
        
        print("📋 Reading DG12 (Document Details)...")
        
        data.issuingAuthority = dg12.issuingAuthority
        data.dateOfIssue = dg12.dateOfIssue
        data.taxOrExitRequirements = dg12.taxOrExitRequirements
        
        if let otherPersons = dg12.otherPersonsDetails {
            data.namesOfOtherPersons = [otherPersons]
        }
        
        data.endorsementsAndObservations = dg12.endorsementsOrObservations
        
        if let frontImg = dg12.frontImage {
            data.imageOfFront = Data(frontImg)
        }
        
        if let rearImg = dg12.rearImage {
            data.imageOfRear = Data(rearImg)
        }
        
        data.dateAndTimeOfPersonalization = dg12.personalizationTime
        data.personalizationSystemSerialNumber = dg12.personalizationDeviceSerialNr
        
        print("✓ DG12: Document metadata")
    }
    
    private func readDG13(passport: NFCPassportModel, into data: inout PassportData) {
        guard let dg13 = passport.getDataGroup(.DG13) else {
            print("⚠️ DG13 not available")
            return
        }
        
        print("📦 Reading DG13 (Optional Details)...")
        data.optionalDetailsData = Data(dg13.body)
        print("✓ DG13: \(dg13.body.count) bytes")
    }
    
    private func readDG14(passport: NFCPassportModel, into data: inout PassportData) {
        guard let dg14 = passport.getDataGroup(.DG14) as? DataGroup14 else {
            print("⚠️ DG14 not available")
            return
        }
        
        print("🔐 Reading DG14 (Security Options)...")
        
        data.hasChipAuthentication = passport.isChipAuthenticationSupported
        
        if data.hasChipAuthentication {
            data.supportedSecurityProtocols.append("Chip Authentication")
        }
        
        // Check for other security infos
        for securityInfo in dg14.securityInfos {
            if securityInfo is ChipAuthenticationInfo {
                data.hasChipAuthentication = true
            }
        }
        
        print("✓ DG14: Security protocols detected")
    }
    
    private func readDG15(passport: NFCPassportModel, into data: inout PassportData) {
        guard let dg15 = passport.getDataGroup(.DG15) as? DataGroup15 else {
            print("⚠️ DG15 not available")
            return
        }
        
        print("🔑 Reading DG15 (Active Authentication)...")
        
        data.hasActiveAuthentication = passport.activeAuthenticationSupported
        
        if dg15.rsaPublicKey != nil {
            data.activeAuthAlgorithm = "RSA"
            data.supportedSecurityProtocols.append("Active Authentication")
            
            // Store public key data
            if let keyData = OpenSSLUtils.getPublicKeyData(from: dg15.rsaPublicKey!) {
                data.activeAuthPublicKey = Data(keyData).base64EncodedString()
            }
        } else if dg15.ecdsaPublicKey != nil {
            data.activeAuthAlgorithm = "ECDSA"
            data.supportedSecurityProtocols.append("Active Authentication")
            
            // Store public key data
            if let keyData = OpenSSLUtils.getPublicKeyData(from: dg15.ecdsaPublicKey!) {
                data.activeAuthPublicKey = Data(keyData).base64EncodedString()
            }
        }
        
        print("✓ DG15: Active Authentication \(data.hasActiveAuthentication ? "available" : "not available")")
    }
    
    private func readDG16(passport: NFCPassportModel, into data: inout PassportData) {
        guard let dg16 = passport.getDataGroup(.DG16) else {
            print("⚠️ DG16 not available")
            return
        }
        
        print("🆘 Reading DG16 (Emergency Contacts)...")
        // DG16 structure varies by country - store raw data for now
        print("✓ DG16: \(dg16.body.count) bytes")
    }
    
    
    
    
}



// MARK: - Convenience Extensions

extension PassportReader.PassportData: CustomStringConvertible {
    public var description: String {
        var result = "PassportData{\n"
        result += "  documentCode: \(documentCode ?? "nil")\n"
        result += "  documentNumber: \(documentNumber ?? "nil")\n"
        result += "  firstName: \(firstName ?? "nil")\n"
        result += "  lastName: \(lastName ?? "nil")\n"
        result += "  nationality: \(nationality ?? "nil")\n"
        result += "  issuingState: \(issuingState ?? "nil")\n"
        result += "  gender: \(gender ?? "nil")\n"
        result += "  dateOfBirth: \(dateOfBirth ?? "nil")\n"
        result += "  dateOfExpiry: \(dateOfExpiry ?? "nil")\n"
        result += "  authenticationMethod: \(authenticationMethod.rawValue)\n"
        result += "  hasValidSignature: \(hasValidSignature)\n"
        result += "  faceImages.count: \(faceImages.count)\n"
        result += "  availableDataGroups: \(availableDataGroups)\n"
        result += "  supportedSecurityProtocols: \(supportedSecurityProtocols)\n"
        result += "}"
        return result
    }
}
