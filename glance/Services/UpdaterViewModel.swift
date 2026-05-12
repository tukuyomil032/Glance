//
//  UpdaterViewModel.swift
//  glance
//
//  Created by yomi on 2026/05/09.
//

import Sparkle
import Combine
import OSLog

final class UpdaterViewModel: ObservableObject {
    private let updaterController: SPUStandardUpdaterController
    private let bundle: Bundle
    private let logger = Logger(subsystem: "com.tukuyomi032.glance", category: "Updater")
    @Published var canCheckForUpdates = false
    @Published private(set) var missingConfigurationReason: String?

    init(bundle: Bundle = .main) {
        self.bundle = bundle
        updaterController = SPUStandardUpdaterController(
            startingUpdater: !AppMetadata.isUITestMode(),
            updaterDelegate: nil,
            userDriverDelegate: nil
        )

        if AppMetadata.sparkleFeedURL(bundle: bundle) == nil {
            missingConfigurationReason = "SUFeedURL is missing from the app bundle."
            logger.error("Sparkle feed URL is missing from the app bundle metadata.")
        } else if AppMetadata.sparklePublicEDKey(bundle: bundle) == nil {
            missingConfigurationReason = "SUPublicEDKey is missing from the app bundle."
            logger.error("Sparkle public key is missing from the app bundle metadata.")
        }

        updaterController.updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }

    func checkForUpdates() {
        guard missingConfigurationReason == nil else {
            logger.error("Skipped update check because bundle metadata is incomplete.")
            return
        }

        updaterController.updater.checkForUpdates()
    }

    var automaticallyChecksForUpdates: Bool {
        get { updaterController.updater.automaticallyChecksForUpdates }
        set { updaterController.updater.automaticallyChecksForUpdates = newValue }
    }

    var isConfiguredForUpdates: Bool {
        missingConfigurationReason == nil
    }
}
