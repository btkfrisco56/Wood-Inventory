import Foundation
import CloudKit
import UIKit

/// Represents a single piece of wood in the inventory.
struct WoodItem: Identifiable {
    /// CloudKit record type name used for all wood records.
    static let recordType = "WoodItem"

    let id: CKRecord.ID
    var woodType: String
    var lengthInches: Double
    var widthInches: Double
    var thicknessInches: Double
    var notes: String
    /// Locally cached photo fetched from the CKAsset.
    var photo: UIImage?

    // MARK: - CloudKit field keys

    private enum Keys {
        static let woodType = "woodType"
        static let lengthInches = "lengthInches"
        static let widthInches = "widthInches"
        static let thicknessInches = "thicknessInches"
        static let notes = "notes"
        static let photo = "photo"
    }

    // MARK: - Init from CKRecord

    init(record: CKRecord) {
        self.id = record.recordID
        self.woodType = record[Keys.woodType] as? String ?? ""
        self.lengthInches = record[Keys.lengthInches] as? Double ?? 0
        self.widthInches = record[Keys.widthInches] as? Double ?? 0
        self.thicknessInches = record[Keys.thicknessInches] as? Double ?? 0
        self.notes = record[Keys.notes] as? String ?? ""

        if let asset = record[Keys.photo] as? CKAsset,
           let fileURL = asset.fileURL,
           let data = try? Data(contentsOf: fileURL) {
            self.photo = UIImage(data: data)
        }
    }

    // MARK: - Init for new item

    init(woodType: String = "",
         lengthInches: Double = 0,
         widthInches: Double = 0,
         thicknessInches: Double = 0,
         notes: String = "",
         photo: UIImage? = nil) {
        self.id = CKRecord.ID(recordName: UUID().uuidString)
        self.woodType = woodType
        self.lengthInches = lengthInches
        self.widthInches = widthInches
        self.thicknessInches = thicknessInches
        self.notes = notes
        self.photo = photo
    }

    // MARK: - Init for updating an existing item (preserves record ID)

    init(updating existing: WoodItem,
         woodType: String,
         lengthInches: Double,
         widthInches: Double,
         thicknessInches: Double,
         notes: String,
         photo: UIImage?) {
        self.id = existing.id
        self.woodType = woodType
        self.lengthInches = lengthInches
        self.widthInches = widthInches
        self.thicknessInches = thicknessInches
        self.notes = notes
        self.photo = photo
    }

    // MARK: - Convert to CKRecord

    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: WoodItem.recordType, recordID: id)
        record[Keys.woodType] = woodType as CKRecordValue
        record[Keys.lengthInches] = lengthInches as CKRecordValue
        record[Keys.widthInches] = widthInches as CKRecordValue
        record[Keys.thicknessInches] = thicknessInches as CKRecordValue
        record[Keys.notes] = notes as CKRecordValue

        if let photo = photo,
           let data = photo.jpegData(compressionQuality: 0.8) {
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("jpg")
            // Only attach the asset if the write actually succeeds
            if (try? data.write(to: tempURL)) != nil {
                record[Keys.photo] = CKAsset(fileURL: tempURL)
            }
        }

        return record
    }

    /// A human-readable dimension string, e.g. "96 × 3.5 × 1.5 in".
    var dimensionSummary: String {
        String(format: "%.4g × %.4g × %.4g in",
               lengthInches, widthInches, thicknessInches)
    }
}
