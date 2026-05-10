import SwiftUI

@main
struct glanceApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView(
                appLocale: Binding(
                    get: { appDelegate.appLocale },
                    set: { appDelegate.appLocale = $0 }
                ),
                updaterViewModel: appDelegate.updaterViewModel
            )
            .environment(\.locale, appDelegate.appLocale)
        }
    }
}
