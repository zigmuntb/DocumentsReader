@MainActor
protocol DisclaimerStoring: AnyObject {
    var isAcknowledged: Bool { get }
    func acknowledge()
}
