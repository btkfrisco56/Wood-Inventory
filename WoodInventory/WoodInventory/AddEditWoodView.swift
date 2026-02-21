import SwiftUI

/// Add a new wood item or edit an existing one.
struct AddEditWoodView: View {
    @EnvironmentObject var manager: CloudKitManager
    @Environment(\.dismiss) private var dismiss

    // Optional – nil means we're adding a new item
    let existingItem: WoodItem?

    // Form fields
    @State private var woodType: String
    @State private var lengthInches: String
    @State private var widthInches: String
    @State private var thicknessInches: String
    @State private var notes: String
    @State private var photo: UIImage?

    // Camera / photo picker
    @State private var showingImagePicker = false
    @State private var imageSource: UIImagePickerController.SourceType = .camera

    // Validation
    @State private var showingValidationAlert = false
    @State private var isSaving = false

    // Common wood species for the picker
    private let woodTypes = [
        "Custom",
        "Pine",
        "Oak",
        "Maple",
        "Cherry",
        "Walnut",
        "Birch",
        "Poplar",
        "Cedar",
        "Ash",
        "Hickory",
        "Mahogany",
        "Teak",
        "Douglas Fir",
        "Redwood",
        "Cypress"
    ]

    init(item: WoodItem?) {
        self.existingItem = item
        if let item {
            _woodType = State(initialValue: item.woodType)
            _lengthInches = State(initialValue: String(format: "%.4g", item.lengthInches))
            _widthInches = State(initialValue: String(format: "%.4g", item.widthInches))
            _thicknessInches = State(initialValue: String(format: "%.4g", item.thicknessInches))
            _notes = State(initialValue: item.notes)
            _photo = State(initialValue: item.photo)
        } else {
            _woodType = State(initialValue: "")
            _lengthInches = State(initialValue: "")
            _widthInches = State(initialValue: "")
            _thicknessInches = State(initialValue: "")
            _notes = State(initialValue: "")
            _photo = State(initialValue: nil)
        }
    }

    var body: some View {
        NavigationView {
            Form {
                // Photo section
                Section("Photo") {
                    if let photo = photo {
                        Image(uiImage: photo)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .cornerRadius(8)
                    }
                    photoButtons
                }

                // Wood type section
                Section("Wood Type") {
                    // Quick-pick from common species
                    Picker("Species", selection: woodTypeBinding) {
                        ForEach(woodTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    // Free-form entry overrides the picker
                    TextField("Or type a custom species…", text: $woodType)
                        .autocapitalization(.words)
                }

                // Dimensions section
                Section("Dimensions (inches)") {
                    dimensionField("Length", value: $lengthInches, placeholder: "e.g. 96")
                    dimensionField("Width", value: $widthInches, placeholder: "e.g. 3.5")
                    dimensionField("Thickness", value: $thicknessInches, placeholder: "e.g. 1.5")
                }

                // Notes section
                Section("Notes") {
                    TextField("Any additional notes…", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(existingItem == nil ? "Add Wood" : "Edit Wood")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveItem() }
                        .disabled(isSaving || woodType.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                CameraView(image: $photo, sourceType: imageSource)
            }
            .alert("Missing Information", isPresented: $showingValidationAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please enter at least a wood type before saving.")
            }
            .overlay {
                if isSaving {
                    ProgressView("Saving…")
                        .padding(24)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    // MARK: - Photo buttons

    private var photoButtons: some View {
        HStack {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button {
                    imageSource = .camera
                    showingImagePicker = true
                } label: {
                    Label("Take Photo", systemImage: "camera")
                }
                Spacer()
            }
            Button {
                imageSource = .photoLibrary
                showingImagePicker = true
            } label: {
                Label("Choose Photo", systemImage: "photo.on.rectangle")
            }
            if photo != nil {
                Spacer()
                Button(role: .destructive) {
                    photo = nil
                } label: {
                    Label("Remove", systemImage: "trash")
                }
            }
        }
        .font(.subheadline)
    }

    // MARK: - Dimension field helper

    private func dimensionField(_ label: String, value: Binding<String>, placeholder: String) -> some View {
        HStack {
            Text(label)
                .frame(width: 80, alignment: .leading)
            TextField(placeholder, text: value)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
            Text("in")
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Wood type picker binding

    /// When the user picks a preset, copy it into woodType so free-form overrides still work.
    private var woodTypeBinding: Binding<String> {
        Binding(
            get: { woodTypes.contains(woodType) ? woodType : "Custom" },
            set: { newValue in
                if newValue != "Custom" { woodType = newValue }
            }
        )
    }

    // MARK: - Save

    private func saveItem() {
        let trimmedType = woodType.trimmingCharacters(in: .whitespaces)
        guard !trimmedType.isEmpty else {
            showingValidationAlert = true
            return
        }

        isSaving = true
        let length = Double(lengthInches) ?? 0
        let width = Double(widthInches) ?? 0
        let thickness = Double(thicknessInches) ?? 0
        let trimmedNotes = notes.trimmingCharacters(in: .whitespaces)

        let itemToSave: WoodItem
        if let existing = existingItem {
            // Preserve the CloudKit record ID so this is an update, not a new record
            itemToSave = WoodItem(updating: existing,
                                  woodType: trimmedType,
                                  lengthInches: length,
                                  widthInches: width,
                                  thicknessInches: thickness,
                                  notes: trimmedNotes,
                                  photo: photo)
        } else {
            itemToSave = WoodItem(woodType: trimmedType,
                                  lengthInches: length,
                                  widthInches: width,
                                  thicknessInches: thickness,
                                  notes: trimmedNotes,
                                  photo: photo)
        }

        Task {
            await manager.save(itemToSave)
            isSaving = false
            dismiss()
        }
    }
}

#Preview {
    AddEditWoodView(item: nil)
        .environmentObject(CloudKitManager())
}
