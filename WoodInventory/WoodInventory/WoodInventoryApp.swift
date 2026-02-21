import SwiftUI

@main
struct WoodInventoryApp: App {
    @StateObject private var cloudKitManager = CloudKitManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(cloudKitManager)
        }
    }
}
