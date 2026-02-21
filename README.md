# Wood Inventory

An iOS app that stores your wood shop inventory in **iCloud (CloudKit)** — one record per piece of wood. Take photos of each board, record the species and dimensions, and access your inventory from any device signed into your Apple ID.

---

## Features

| Feature | Details |
|---------|---------|
| 📸 **Photo** | Snap a photo with the camera or pick from your library |
| 🌲 **Wood type** | Choose from 15 common species or type any custom name |
| 📏 **Dimensions** | Length × Width × Thickness in inches |
| 📝 **Notes** | Free-form notes per item |
| ☁️ **iCloud sync** | Private CloudKit database — visible only to you, syncs across all your Apple devices |
| ✏️ **Edit / Delete** | Tap any row to edit; swipe left to delete |

---

## Requirements

- Xcode 15 or later
- iOS 17.0+ deployment target
- An Apple Developer account (free or paid) to enable iCloud/CloudKit
- An Apple ID signed into iCloud on the test device or simulator

---

## Setup

### 1. Open the project

```bash
open WoodInventory/WoodInventory.xcodeproj
```

### 2. Set your Team

1. In the Project navigator select the **WoodInventory** target.
2. Under **Signing & Capabilities → Team**, choose your Apple Developer team.
3. Xcode will automatically provision the app.

### 3. Configure iCloud / CloudKit

1. Under **Signing & Capabilities**, confirm the **iCloud** capability is present.
2. Make sure **CloudKit** is checked and the container `iCloud.com.woodinventory.app` is listed.
   - If you want your own container name, update it in both `WoodInventory.entitlements` and `CloudKitManager.swift` (`containerIdentifier`).

### 4. Build & Run

Select an iPhone simulator or a physical device and press **⌘R**.

> **Note:** The camera is not available in the simulator — use **"Choose Photo"** to pick from the simulator's photo library instead.

---

## CloudKit Data Model

The app stores one `WoodItem` record per piece of wood in the **private CloudKit database**:

| Field | Type | Description |
|-------|------|-------------|
| `woodType` | String | Species / common name (e.g. "Oak") |
| `lengthInches` | Double | Length in inches |
| `widthInches` | Double | Width in inches |
| `thicknessInches` | Double | Thickness in inches |
| `notes` | String | Free-form notes |
| `photo` | CKAsset | JPEG photo of the wood |

Records are stored in the **user's private database**, so they are never shared with other iCloud users and count against the owner's iCloud storage quota.

---

## Project Structure

```
WoodInventory/
├── WoodInventory.xcodeproj/     Xcode project & shared scheme
└── WoodInventory/
    ├── WoodInventoryApp.swift   App entry point
    ├── ContentView.swift        Main list view
    ├── AddEditWoodView.swift    Add / edit form with camera
    ├── CameraView.swift         UIImagePickerController wrapper
    ├── WoodItem.swift           Data model + CKRecord conversion
    ├── CloudKitManager.swift    CloudKit CRUD operations
    ├── Info.plist               Camera & photo library permissions
    └── WoodInventory.entitlements  iCloud / CloudKit entitlements
WoodInventoryTests/
    └── WoodInventoryTests.swift Unit tests for the data model
```
