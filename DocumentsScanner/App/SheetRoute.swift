enum SheetRoute: Identifiable, Hashable {
    case paywall
    case disclaimer

    var id: Self { self }
}
