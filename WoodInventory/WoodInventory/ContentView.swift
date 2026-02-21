import SwiftUI

struct ContentView: View {
    @EnvironmentObject var manager: CloudKitManager
    @State private var showingAddItem = false
    @State private var selectedItem: WoodItem?

    var body: some View {
        NavigationView {
            Group {
                if !manager.iCloudAvailable {
                    iCloudWarningView
                } else if manager.isLoading && manager.items.isEmpty {
                    ProgressView("Loading inventory…")
                } else if manager.items.isEmpty {
                    emptyStateView
                } else {
                    itemList
                }
            }
            .navigationTitle("Wood Inventory")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddItem = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .disabled(!manager.iCloudAvailable)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    if manager.isLoading {
                        ProgressView()
                    }
                }
            }
            .sheet(isPresented: $showingAddItem) {
                AddEditWoodView(item: nil)
            }
            .sheet(item: $selectedItem) { item in
                AddEditWoodView(item: item)
            }
            .alert("Error", isPresented: .constant(manager.errorMessage != nil)) {
                Button("OK") { manager.errorMessage = nil }
            } message: {
                Text(manager.errorMessage ?? "")
            }
            .refreshable {
                manager.fetchItems()
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - Sub-views

    private var itemList: some View {
        List {
            ForEach(manager.items) { item in
                WoodItemRow(item: item)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedItem = item
                    }
            }
            .onDelete { offsets in
                Task { await manager.delete(at: offsets) }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "shippingbox")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            Text("No Wood Yet")
                .font(.title2.bold())
            Text("Tap + to add your first piece of wood.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var iCloudWarningView: some View {
        VStack(spacing: 16) {
            Image(systemName: "icloud.slash")
                .font(.system(size: 64))
                .foregroundColor(.orange)
            Text("iCloud Unavailable")
                .font(.title2.bold())
            Text(manager.errorMessage ?? "Sign in to iCloud in Settings to use Wood Inventory.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("Retry") {
                manager.checkiCloudStatus()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - Row view

struct WoodItemRow: View {
    let item: WoodItem

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            if let photo = item.photo {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.secondary)
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.woodType.isEmpty ? "Unknown Type" : item.woodType)
                    .font(.headline)
                Text(item.dimensionSummary)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                if !item.notes.isEmpty {
                    Text(item.notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView()
        .environmentObject(CloudKitManager())
}
