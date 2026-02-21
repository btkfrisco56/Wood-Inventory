import Foundation
import CloudKit
import Combine

/// Manages all CloudKit (iCloud) operations for the wood inventory.
/// Records are stored in the user's private iCloud database so that
/// only the device owner can see them.
@MainActor
final class CloudKitManager: ObservableObject {

    // MARK: - Published state

    @Published var items: [WoodItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var iCloudAvailable = false

    // MARK: - CloudKit container

    /// The iCloud container identifier set in the app's entitlements.
    private let containerIdentifier = "iCloud.com.woodinventory.app"
    private lazy var container = CKContainer(identifier: containerIdentifier)
    private lazy var privateDB = container.privateCloudDatabase

    // MARK: - Lifecycle

    init() {
        checkiCloudStatus()
    }

    // MARK: - iCloud availability check

    func checkiCloudStatus() {
        container.accountStatus { [weak self] status, error in
            Task { @MainActor in
                switch status {
                case .available:
                    self?.iCloudAvailable = true
                    self?.fetchItems()
                case .noAccount:
                    self?.errorMessage = "No iCloud account found. Please sign in to iCloud in Settings."
                case .restricted:
                    self?.errorMessage = "iCloud access is restricted on this device."
                case .couldNotDetermine:
                    self?.errorMessage = error?.localizedDescription ?? "Could not determine iCloud status."
                case .temporarilyUnavailable:
                    self?.errorMessage = "iCloud is temporarily unavailable. Please try again later."
                @unknown default:
                    self?.errorMessage = "Unknown iCloud account status."
                }
            }
        }
    }

    // MARK: - Fetch

    /// Fetches all WoodItem records from the private iCloud database.
    func fetchItems() {
        isLoading = true
        errorMessage = nil

        let query = CKQuery(recordType: WoodItem.recordType,
                            predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "modificationDate", ascending: false)]

        let operation = CKQueryOperation(query: query)
        var fetchedRecords: [CKRecord] = []

        operation.recordMatchedBlock = { _, result in
            if case .success(let record) = result {
                fetchedRecords.append(record)
            }
        }

        operation.queryResultBlock = { [weak self] result in
            Task { @MainActor in
                self?.isLoading = false
                switch result {
                case .success:
                    self?.items = fetchedRecords.map { WoodItem(record: $0) }
                case .failure(let error):
                    self?.errorMessage = "Failed to fetch items: \(error.localizedDescription)"
                }
            }
        }

        privateDB.add(operation)
    }

    // MARK: - Save (Create / Update)

    /// Saves a new or updated WoodItem to iCloud.
    func save(_ item: WoodItem) async {
        isLoading = true
        errorMessage = nil
        let record = item.toCKRecord()
        do {
            let savedRecord = try await privateDB.save(record)
            let savedItem = WoodItem(record: savedRecord)
            if let index = items.firstIndex(where: { $0.id == item.id }) {
                items[index] = savedItem
            } else {
                items.insert(savedItem, at: 0)
            }
        } catch {
            errorMessage = "Failed to save item: \(error.localizedDescription)"
        }
        isLoading = false
    }

    // MARK: - Delete

    /// Deletes a WoodItem from iCloud and removes it from the local list.
    func delete(_ item: WoodItem) async {
        isLoading = true
        errorMessage = nil
        do {
            try await privateDB.deleteRecord(withID: item.id)
            items.removeAll { $0.id == item.id }
        } catch {
            errorMessage = "Failed to delete item: \(error.localizedDescription)"
        }
        isLoading = false
    }

    /// Convenience helper to delete items by index set (used by List's onDelete).
    func delete(at offsets: IndexSet) async {
        // Collect items before any deletions so indices remain valid
        let itemsToDelete = offsets.map { items[$0] }
        for item in itemsToDelete {
            await delete(item)
        }
    }
}
