import XCTest
@testable import WoodInventory
import CloudKit

final class WoodInventoryTests: XCTestCase {

    // MARK: - WoodItem model tests

    func testNewItemHasUniqueID() {
        let item1 = WoodItem(woodType: "Oak")
        let item2 = WoodItem(woodType: "Pine")
        XCTAssertNotEqual(item1.id, item2.id)
    }

    func testDimensionSummaryFormatting() {
        let item = WoodItem(woodType: "Maple",
                            lengthInches: 96,
                            widthInches: 3.5,
                            thicknessInches: 1.5)
        XCTAssertEqual(item.dimensionSummary, "96 × 3.5 × 1.5 in")
    }

    func testDimensionSummaryAllZeros() {
        let item = WoodItem()
        XCTAssertEqual(item.dimensionSummary, "0 × 0 × 0 in")
    }

    func testUpdatingPreservesRecordID() {
        let original = WoodItem(woodType: "Cedar",
                                lengthInches: 48,
                                widthInches: 2,
                                thicknessInches: 1)
        let updated = WoodItem(updating: original,
                               woodType: "Cedar (reclaimed)",
                               lengthInches: 48,
                               widthInches: 2,
                               thicknessInches: 1,
                               notes: "From old barn",
                               photo: nil)
        XCTAssertEqual(original.id, updated.id)
        XCTAssertEqual(updated.woodType, "Cedar (reclaimed)")
        XCTAssertEqual(updated.notes, "From old barn")
    }

    func testToCKRecordRoundTrip() {
        let item = WoodItem(woodType: "Walnut",
                            lengthInches: 72,
                            widthInches: 5.25,
                            thicknessInches: 0.75,
                            notes: "Live edge slab")
        let record = item.toCKRecord()
        XCTAssertEqual(record.recordType, WoodItem.recordType)
        XCTAssertEqual(record["woodType"] as? String, "Walnut")
        XCTAssertEqual(record["lengthInches"] as? Double, 72)
        XCTAssertEqual(record["widthInches"] as? Double, 5.25)
        XCTAssertEqual(record["thicknessInches"] as? Double, 0.75)
        XCTAssertEqual(record["notes"] as? String, "Live edge slab")
    }

    func testInitFromCKRecord() {
        let record = CKRecord(recordType: WoodItem.recordType)
        record["woodType"] = "Birch" as CKRecordValue
        record["lengthInches"] = 60.0 as CKRecordValue
        record["widthInches"] = 4.0 as CKRecordValue
        record["thicknessInches"] = 0.5 as CKRecordValue
        record["notes"] = "Planed smooth" as CKRecordValue

        let item = WoodItem(record: record)
        XCTAssertEqual(item.woodType, "Birch")
        XCTAssertEqual(item.lengthInches, 60.0)
        XCTAssertEqual(item.widthInches, 4.0)
        XCTAssertEqual(item.thicknessInches, 0.5)
        XCTAssertEqual(item.notes, "Planed smooth")
        XCTAssertNil(item.photo)
    }

    func testInitFromEmptyCKRecord() {
        let record = CKRecord(recordType: WoodItem.recordType)
        let item = WoodItem(record: record)
        XCTAssertEqual(item.woodType, "")
        XCTAssertEqual(item.lengthInches, 0)
        XCTAssertEqual(item.widthInches, 0)
        XCTAssertEqual(item.thicknessInches, 0)
        XCTAssertEqual(item.notes, "")
        XCTAssertNil(item.photo)
    }
}
