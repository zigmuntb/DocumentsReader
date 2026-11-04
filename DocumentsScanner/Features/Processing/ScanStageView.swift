import CoreGraphics
import SwiftUI
import UIKit

/// The page under the beam, with lines lifting off it into quote chips.
struct ScanStageView: View {
    let frame: ScanFrame?
    var reduceMotion: Bool

    @State private var pictures = PagePicture()
    @State private var liftStart: Date?
    @State private var beamSettled = false

    var body: some View {
        let image = pictures.image(token: pictureToken, data: frame?.imageJPEG)
        return Group {
            if reduceMotion {
                column(image: image, beam: restingBeam)
            } else {
                TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: beamSettled)) { timeline in
                    column(image: image, beam: displayBeam(at: timeline.date))
                }
            }
        }
        .onChange(of: liftToken, initial: true) { _, _ in
            liftStart = frame?.activity == .readingLines ? Date() : nil
            beamSettled = false
        }
        .task(id: liftToken) {
            guard !reduceMotion, frame?.activity == .readingLines else { return }
            let duration = ScanTiming.liftDuration(lineCount: frame?.lines.count ?? 0)
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled else { return }
            beamSettled = true
        }
    }

    private func column(image: UIImage?, beam: CGFloat) -> some View {
        let revealed = revealedLines(beam: beam)
        let chips = Array(revealed.suffix(3).reversed())
        return VStack(alignment: .leading, spacing: DSSpacing.m) {
            paper(image: image, revealed: revealed, beam: beam)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            if frame?.activity == .readingLines {
                tray(chips)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var pictureToken: String {
        guard let frame else { return "none" }
        return "\(frame.pageIndex)-\(frame.imageJPEG?.count ?? 0)"
    }

    private var liftToken: String {
        guard let frame else { return "none" }
        return "\(frame.pageIndex)-\(frame.activity.token)-\(frame.lines.count)"
    }

    private var restingBeam: CGFloat {
        frame?.activity == .readingLines ? 1 : 0
    }

    private func paper(image: UIImage?, revealed: [ScanLine], beam: CGFloat) -> some View {
        GeometryReader { geo in
            let aspect = image.map { $0.size.width / max($0.size.height, 1) } ?? 0.72
            let card = fitted(aspect: aspect, in: geo.size)
            ZStack {
                DSColor.elevated
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: card.width, height: card.height)
                        .clipped()
                        .accessibilityHidden(true)
                }
                lineLayer(revealed: revealed, showsEveryLine: image == nil, in: card)
                if !reduceMotion {
                    scanBeam(in: card, beam: beam)
                }
            }
            .frame(width: card.width, height: card.height)
            .clipShape(RoundedRectangle(cornerRadius: DSRadius.m, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: DSRadius.m, style: .continuous)
                    .strokeBorder(DSColor.hairline, lineWidth: 1)
            }
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(pageValue)
    }

    private var pageValue: String {
        guard let frame, frame.pageCount > 0 else {
            return String(localized: "Reading the lease")
        }
        return String(localized: "Page \(frame.pageIndex + 1) of \(frame.pageCount)")
    }

    /// Caught lines are printed on the page. Without a photo, the unread lines are printed too.
    private func lineLayer(revealed: [ScanLine], showsEveryLine: Bool, in card: CGSize) -> some View {
        let source = showsEveryLine ? (frame?.lines ?? []) : revealed
        let caught = Set(revealed.map(\.id))
        return ZStack {
            ForEach(source) { line in
                let bounds = line.bounds ?? CGRect(x: 0.08, y: 0.1, width: 0.84, height: 0.04)
                let isCaught = caught.contains(line.id)
                Text(line.text)
                    .font(.system(size: max(12, bounds.height * card.height * 0.82), design: .serif))
                    .foregroundStyle(isCaught ? DSColor.ink : DSColor.inkSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.45)
                    .frame(
                        width: max(bounds.width * card.width, card.width * 0.7),
                        height: max(bounds.height * card.height, 18),
                        alignment: .leading
                    )
                    .padding(.horizontal, DSSpacing.xxs)
                    .background {
                        if isCaught {
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(DSColor.quote.opacity(imageBacked ? 0.9 : 0.95))
                        }
                    }
                    .position(
                        x: bounds.midX * card.width,
                        y: bounds.midY * card.height
                    )
                    .accessibilityHidden(true)
            }
        }
        .frame(width: card.width, height: card.height)
    }

    private var imageBacked: Bool {
        frame?.imageJPEG?.isEmpty == false
    }

    private func scanBeam(in card: CGSize, beam: CGFloat) -> some View {
        let y = min(max(beam, 0), 1) * card.height
        return ZStack {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            DSColor.primary.opacity(0),
                            DSColor.primary.opacity(0.35),
                            DSColor.primary.opacity(0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: card.width, height: 36)
            Rectangle()
                .fill(DSColor.primary)
                .frame(width: card.width, height: 2)
        }
        .position(x: card.width / 2, y: y)
        .accessibilityHidden(true)
    }

    private func tray(_ lines: [ScanLine]) -> some View {
        VStack(alignment: .leading, spacing: DSSpacing.xs) {
            Text(String(localized: "From this page"))
                .font(DSFont.eyebrow)
                .tracking(DSFont.eyebrowTracking)
                .textCase(.uppercase)
                .foregroundStyle(DSColor.secondary)
                .accessibilityAddTraits(.isHeader)
                .opacity(lines.isEmpty ? 0 : 1)
            ForEach(lines) { line in
                Text(line.text)
                    .font(DSFont.quote)
                    .foregroundStyle(DSColor.ink)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, DSSpacing.s)
                    .padding(.vertical, DSSpacing.xs)
                    .background(
                        DSColor.quote,
                        in: RoundedRectangle(cornerRadius: DSRadius.s, style: .continuous)
                    )
                    .transition(reduceMotion ? .identity : .opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .top)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.28), value: lines.map(\.id))
    }

    private func displayBeam(at date: Date) -> CGFloat {
        if beamSettled, frame?.activity == .readingLines {
            return 1
        }
        return beam(at: date)
    }

    private func beam(at date: Date) -> CGFloat {
        guard let frame else { return loop(date) }
        switch frame.activity {
        case .sweeping:
            return loop(date)
        case .readingLines:
            guard let liftStart else { return 0 }
            let duration = ScanTiming.liftDuration(lineCount: frame.lines.count)
            let elapsed = date.timeIntervalSince(liftStart)
            return CGFloat(min(1, max(0, elapsed / duration)))
        }
    }

    /// Lines the beam has already crossed, in reading order.
    private func revealedLines(beam: CGFloat) -> [ScanLine] {
        guard let frame, frame.activity == .readingLines else { return [] }
        return frame.lines.filter { line in
            beam + 0.001 >= threshold(for: line, count: frame.lines.count)
        }
    }

    private func threshold(for line: ScanLine, count: Int) -> CGFloat {
        if let bounds = line.bounds {
            return bounds.midY
        }
        return (CGFloat(line.index) + 0.45) / CGFloat(max(count, 1))
    }

    private func loop(_ date: Date) -> CGFloat {
        let period = 1.8
        let remainder = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: period)
        return CGFloat(remainder / period)
    }

    private func fitted(aspect: CGFloat, in container: CGSize) -> CGSize {
        guard container.width > 1, container.height > 1, aspect > 0 else {
            return CGSize(width: max(container.width, 1), height: max(container.height, 1))
        }
        let byWidth = CGSize(width: container.width, height: container.width / aspect)
        if byWidth.height <= container.height { return byWidth }
        return CGSize(width: container.height * aspect, height: container.height)
    }
}

/// Decodes each page once. Timeline updates must not decode the JPEG again.
@MainActor
private final class PagePicture {
    private var token = ""
    private var image: UIImage?

    func image(token: String, data: Data?) -> UIImage? {
        if token == self.token { return image }
        self.token = token
        image = data.flatMap(UIImage.init(data:))
        return image
    }
}

private extension ScanActivity {
    var token: String {
        switch self {
        case .sweeping: "sweeping"
        case .readingLines: "lines"
        }
    }
}
