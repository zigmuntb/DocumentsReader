import Foundation

enum ResultState: Equatable {
    case missing
    case loaded(ChecklistPresentation)
}
