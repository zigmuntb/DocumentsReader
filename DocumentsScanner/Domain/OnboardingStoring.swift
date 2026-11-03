@MainActor
protocol OnboardingStoring: AnyObject {
    var isComplete: Bool { get }
    func markComplete()
}
