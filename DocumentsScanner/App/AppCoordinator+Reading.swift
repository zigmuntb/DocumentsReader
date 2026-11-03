import Foundation

extension AppCoordinator {
    func openReading(_ documentID: UUID) {
        if case .checklist = container.sessionStore.reading(id: documentID)?.outcome {
            openResult(documentID)
        } else {
            openTranscript(documentID)
        }
    }

    func openTranscript(_ documentID: UUID) {
        if transcriptViewModels[documentID] == nil {
            transcriptViewModels[documentID] = TranscriptViewModel(
                documentID: documentID,
                session: container.sessionStore
            )
        }
        push(.transcript(documentID: documentID))
    }

    func openResult(_ documentID: UUID) {
        if resultViewModels[documentID] == nil {
            let model = ResultViewModel(
                documentID: documentID,
                session: container.sessionStore,
                purchases: container.purchases
            )
            model.onEvent = { [weak self] event in
                guard let self else { return }
                switch event {
                case .openItem(let itemID):
                    self.resultCoordinator.selectItem(documentID: documentID, itemID: itemID)
                case .unlock:
                    self.handle(.paywallRequested)
                }
            }
            resultViewModels[documentID] = model
        } else {
            resultViewModels[documentID]?.refreshAccess()
        }
        push(.result(documentID: documentID))
    }

    func openItem(documentID: UUID, itemID: UUID) {
        if detailViewModels[itemID] == nil {
            let model = ItemDetailViewModel(
                documentID: documentID,
                itemID: itemID,
                session: container.sessionStore,
                purchases: container.purchases
            )
            model.onEvent = { [weak self] event in
                if case .unlock = event {
                    self?.handle(.paywallRequested)
                }
            }
            detailViewModels[itemID] = model
        }
        push(.itemDetail(documentID: documentID, itemID: itemID))
    }
}
