import SwiftUI
import UIKit

public struct TextLineSegnemt: Sendable {
    /// The layout frame of the text line.
    public let rect: CGRect
    private let _textRange: Lock<NSTextRange>
    /// The text range of the text line. Range is in NSTextStorage.
    public var textRange: NSTextRange {
        get {
            _textRange.withLock { v in
                v
            }
        }
        set(value) {
            _textRange.withLock { v in
                v = value
            }
        }
    }
    /// The range of the text line in the document. Range is in NSString(utf16).
    public let range: NSRange
    /// The text of the text line.
    public let text: String

    init(rect: CGRect, range: NSRange, textRange: NSTextRange, str: String) {
        self.rect = rect
        self._textRange = Lock(textRange)
        self.range = range
        self.text = str
    }
}

extension NSTextContentManager {
    func range(for textRange: NSTextRange) -> NSRange? {
        let location = offset(from: documentRange.location, to: textRange.location)
        let length = offset(from: textRange.location, to: textRange.endLocation)
        if location == NSNotFound || length == NSNotFound { return nil }
        return NSRange(location: location, length: length)
    }

    func textRange(for range: NSRange) -> NSTextRange? {
        guard let textRangeLocation = location(documentRange.location, offsetBy: range.location),
            let endLocation = location(textRangeLocation, offsetBy: range.length)
        else { return nil }
        return NSTextRange(location: textRangeLocation, end: endLocation)
    }
}

public actor TextLayoutManager: NSObject, NSTextContentStorageDelegate, NSTextLayoutManagerDelegate
{
    private let textContentStorage: NSTextContentStorage
    private let textLayoutManager: NSTextLayoutManager
    public let textContainer: NSTextContainer
    private(set) var lineRects: [CGRect] = []

    public override init() {
        textLayoutManager = NSTextLayoutManager()
        textContentStorage = NSTextContentStorage()
        textContainer = NSTextContainer(size: CGSize(width: 0, height: 0))
        super.init()
        textContainer.lineFragmentPadding = 0
        textContainer.lineBreakMode = .byWordWrapping
        textContainer.maximumNumberOfLines = 0
        textLayoutManager.textContainer = textContainer
        textLayoutManager.delegate = self
        textContentStorage.delegate = self
        textContentStorage.textStorage = NSTextStorage()
        textContentStorage.addTextLayoutManager(textLayoutManager)
    }

    public func setText(attributedString: NSAttributedString, layoutSize: CGSize) {
        textContainer.size = layoutSize
        textContentStorage.textStorage?.setAttributedString(attributedString)
    }

    public func setText(attributedString: NSAttributedString) {
        textContentStorage.textStorage?.setAttributedString(attributedString)
    }

    public func setLayoutSize(_ size: CGSize) {
        textContainer.size = size
    }

    public func replaceText(range: NSRange, with string: NSAttributedString) {
        textContentStorage.performEditingTransaction {
            textContentStorage.textStorage?.replaceCharacters(
                in: range,
                with: string
            )
        }
    }
    //
    //    public func getLineRects() -> [TextLineSegnemt] {
    //        var lineDatas: [TextLineSegnemt] = []
    //        textLayoutManager.enumerateTextLayoutFragments(
    //            from: textContentStorage.documentRange.location, options: .ensuresLayout
    //        ) { textLayoutFragment in
    //            let textLayoutFragmentRenderingOrigin = CGPoint(
    //                x:
    //                    textLayoutFragment.layoutFragmentFrame.origin.x,
    //                y:
    //                    textLayoutFragment.layoutFragmentFrame.origin.y)
    //            let fragmentRange = textLayoutFragment.rangeInElement
    //
    //            for textLineFragment in textLayoutFragment.textLineFragments {
    //                let lineFrame = CGRect(
    //                    origin: CGPoint(
    //                        x: textLayoutFragmentRenderingOrigin.x
    //                            + textLineFragment.typographicBounds.origin.x,
    //                        y: textLayoutFragmentRenderingOrigin.y
    //                            + textLineFragment.typographicBounds.origin.y),
    //                    size: textLineFragment.typographicBounds.size
    //                )
    //                let relativeRange = textLineFragment.characterRange
    //                guard
    //                    let absoluteLocation = textLayoutManager.location(
    //                        fragmentRange.location, offsetBy: relativeRange.location)
    //                else {
    //                    errorLog("No location for line, skip early.")
    //                    return false
    //                }
    //                let absoluteLocationEnd = textLayoutManager.location(
    //                    fragmentRange.location, offsetBy: relativeRange.location + relativeRange.length)
    //                let absoluteRange = NSTextRange(
    //                    location: absoluteLocation, end: absoluteLocationEnd)
    //
    //                guard let absoluteRange else {
    //                    errorLog("No absoluteRange for line, skip early.")
    //                    return false
    //                }
    //
    //                let str = textLineFragment.attributedString.string
    //                lineDatas.append(TextLineSegnemt(rect: lineFrame, range: absoluteRange, str: str))
    //            }
    //            return true
    //        }
    //        return lineDatas
    //    }

    public func getLineSegments() -> [TextLineSegnemt] {
        var segs: [TextLineSegnemt] = []
        guard let str = textContentStorage.attributedString?.string else {
            errorLog("No string, exit early.")
            return []
        }
        let nsstr = NSString(string: str)
        textLayoutManager.enumerateTextSegments(
            in: textContentStorage.documentRange, type: .standard,
            options: []
        ) {
            segRange, textLineFragmentRect, textLineFragmentGlyphRange, textContainer in
            guard let segRange,
                let range = textLayoutManager.textContentManager?.range(for: segRange)
            else {
                errorLog("No range for segRange, exit early.")
                return false
            }

            let str = nsstr.substring(with: range)
            segs.append(
                TextLineSegnemt(
                    rect: textLineFragmentRect, range: range, textRange: segRange, str: str))
            return true
        }
        return segs
    }

    public func getLineRectsByCharacterIndex(start: Int, end: Int? = nil) -> [CGRect] {
        let documentRange = textContentStorage.documentRange
        let documentStart = documentRange.location
        guard let startPosition = textLayoutManager.location(documentStart, offsetBy: start) else {
            return []
        }
        guard
            let endPosition = end.map({ textLayoutManager.location(startPosition, offsetBy: $0) })
                ?? documentRange.endLocation
        else {
            return []
        }
        guard let range = NSTextRange(location: startPosition, end: endPosition) else {
            return []
        }
        var lineRect: [CGRect] = []
        textLayoutManager.enumerateTextSegments(
            in: range, type: .standard,
            options: []
        ) {
            segmentRange, textLineFragmentRect, textLineFragmentGlyphRange, textContainer in
            lineRect.append(textLineFragmentRect)
            return true
        }
        return lineRect
    }

    // MARK: - NSTextLayoutManagerDelegate
    // public func textLayoutManager(
    //     _ textLayoutManager: NSTextLayoutManager,
    //     textLayoutFragmentFor location: NSTextLocation,
    //     in textElement: NSTextElement
    // ) -> NSTextLayoutFragment {
    //     infoLog("textLayoutFragmentFor: \(location)")
    //     return NSTextLayoutFragment(textElement: textElement, range: textElement.elementRange)
    // }

    // MARK: - NSTextContentManagerDelegate
    //   func textContentManager(
    //     _ textContentManager: NSTextContentManager,
    //     shouldEnumerate textElement: NSTextElement,
    //     options: NSTextContentManager.EnumerationOptions
    //   ) -> Bool {
    //     return true
    //   }

    // func textContentManager(_ textContentManager: NSTextContentManager, textElementAt location: any NSTextLocation) -> NSTextElement? {
    //     return nil
    // }

    // MARK: - NSTextContentStorageDelegate
    //    func textContentStorage(_ textContentStorage: NSTextContentStorage, textParagraphWith range: NSRange) -> NSTextParagraph? {
    //        let originalText = textContentStorage.textStorage!.attributedSubstring(from: range)
    //        return NSTextParagraph(attributedString: originalText)
    //    }
}

struct TextView: UIViewRepresentable {
    let attributedString: AttributedString

    init(_ attributedString: AttributedString) {
        self.attributedString = attributedString
    }

    func makeUIView(context: Context) -> UITextView {
        let textLayoutManager = NSTextLayoutManager()
        let textContentStorage = NSTextContentStorage()
        let textContainer = NSTextContainer(size: CGSize(width: 100, height: 0))
        textContainer.lineFragmentPadding = 0
        textContainer.lineBreakMode = .byWordWrapping
        textContainer.maximumNumberOfLines = 0
        textLayoutManager.textContainer = textContainer
        textContentStorage.textStorage = NSTextStorage(
            attributedString: NSAttributedString(attributedString))
        textContentStorage.addTextLayoutManager(textLayoutManager)

        let textView = UITextView(
            frame: CGRect(x: 0, y: 0, width: 100, height: 100),
            textContainer: textLayoutManager.textContainer
        )
        textView.isEditable = false
        textView.textContainerInset = .zero

        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
    }
}

#Preview {
    @Previewable @State var width: CGFloat = 20
    @Previewable @State var height: CGFloat = 20
    @Previewable @State var rects: [TextLineSegnemt] = []
    @Previewable @State var textLayoutManager: TextLayoutManager = TextLayoutManager()

    let paragraphStyle = {
        var s = NSMutableParagraphStyle()
        s.lineBreakStrategy = .standard
        return s
    }()
    let text: AttributedString = AttributedString(
        """
        Introduce Dialogue Scripts Feature

        @CharacterA
        Alright, ready to nail a a a 1 3 

        @Charactery
        Yeah, but I’m worried I’ll mess up the lines again.

        @Charactergl
        Nope, lway better. It’s a floating AI teleprompter designed for dialogue. It highlights our lines in two different colors. Yours is 
        This is going to be our best shoot yet.
        """,
        attributes: AttributeContainer(
            [
                .font: UIFont.systemFont(ofSize: 32, weight: .regular, width: .standard),
                .paragraphStyle: paragraphStyle,
            ]
        )
    )

    VStack {
        ScrollView {
            Text(text)
                .foregroundStyle(Color.cyan)
                .trackAndReadSize { size in
                    width = size.width
                    height = size.height
                }
                .overlay {
                    Canvas { context, size in
                        for rect in rects {
                            // Draw layout frame in red
                            context.stroke(
                                Path(rect.rect),
                                with: .color(.red),
                                lineWidth: 1
                            )
                        }
                        context.stroke(
                            Path(CGRect(x: 0, y: 0, width: width, height: height)),
                            with: .color(.blue), lineWidth: 1)
                    }
                }
                .padding()
        }
    }
    .safeAreaInset(edge: .bottom) {
        HStack {
            Spacer()
            Text("size: \(width)")
            Spacer()
            Button("Measure") {
                Task {
                    await textLayoutManager.setText(
                        attributedString: NSAttributedString(text),
                        layoutSize: CGSize(width: width, height: 0)
                    )
                    rects = await textLayoutManager.getLineSegments()
                    for r in rects {
                        infoLog(r)
                    }

                    let segs = await textLayoutManager.getLineSegments()
                    for s in segs {
                        infoLog(s)
                    }
                }
            }
            Button("Edit") {
                Task {
                    await textLayoutManager.replaceText(
                        range: NSRange(location: 10, length: 5),
                        with: NSAttributedString(
                            string: "hello",
                            attributes: [.foregroundColor: UIColor.red]
                        )
                    )
                }
            }
            Spacer()
        }
        .padding()
        .background(.white)
    }
}
