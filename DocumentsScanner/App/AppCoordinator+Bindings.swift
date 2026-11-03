import Foundation

extension AppCoordinator {
    func bindChildren() {
        onboardingViewModel.onEvent = { [weak self] event in
            if case .continued = event {
                self?.onboardingCoordinator.finish()
            }
        }
        onboardingCoordinator.onFinish = { [weak self] in
            self?.handle(.onboardingCompleted)
        }

        homeViewModel.onEvent = { [weak self] event in
            guard let self else { return }
            switch event {
            case .scan:
                self.handle(.scanTapped)
            case .importDocument:
                self.handle(.importTapped)
            case .history:
                self.handle(.historyTapped)
            case .settings:
                self.handle(.settingsTapped)
            }
        }

        scanViewModel.onEvent = { [weak self] event in
            guard let self else { return }
            switch event {
            case .finished(let id):
                self.scanCoordinator.finish(documentID: id)
            case .cancelled:
                self.scanCoordinator.cancel()
            case .failed:
                self.handle(.scannerFailed)
            }
        }
        scanCoordinator.onCancel = { [weak self] in
            self?.handle(.scannerCancelled)
        }
        scanCoordinator.onFinish = { [weak self] documentID in
            self?.handle(.scannerFinished(documentID))
        }

        importViewModel.onEvent = { [weak self] event in
            switch event {
            case .ready(let id):
                self?.handle(.importReady(id))
            case .failed:
                self?.handle(.importFailed)
            }
        }

        paywallViewModel.onEvent = { [weak self] event in
            guard let self else { return }
            switch event {
            case .closed:
                self.paywallCoordinator.close()
            case .purchased:
                self.handle(.purchaseCompleted)
            }
        }
        paywallCoordinator.onClose = { [weak self] in
            self?.handle(.paywallClosed)
        }

        disclaimerViewModel.onAcknowledge = { [weak self] in
            self?.handle(.disclaimerAcknowledged)
        }

        historyViewModel.onEvent = { [weak self] event in
            if case .open(let documentID) = event {
                self?.handle(.historyOpened(documentID))
            }
        }

        settingsViewModel.onEvent = { [weak self] event in
            if case .showPaywall = event {
                self?.handle(.paywallRequested)
            }
        }

        resultCoordinator.onSelectItem = { [weak self] documentID, itemID in
            self?.handle(.itemSelected(documentID: documentID, itemID: itemID))
        }
    }
}
