import SwiftUI

/// Original 5×7 dot glyphs, drawn as circles. No bundled font or image asset.
struct DotNumber: View {
    let text: String
    var size: CGFloat = 5
    var color: Color = .white
    static let glyphs: [Character: [String]] = [
        "0": ["01110","10001","10011","10101","11001","10001","01110"],
        "1": ["00100","01100","00100","00100","00100","00100","01110"],
        "2": ["01110","10001","00001","00010","00100","01000","11111"],
        "3": ["11110","00001","00001","01110","00001","00001","11110"],
        "4": ["00010","00110","01010","10010","11111","00010","00010"],
        "5": ["11111","10000","10000","11110","00001","00001","11110"],
        "6": ["01110","10000","10000","11110","10001","10001","01110"],
        "7": ["11111","00001","00010","00100","01000","01000","01000"],
        "8": ["01110","10001","10001","01110","10001","10001","01110"],
        "9": ["01110","10001","10001","01111","00001","00001","01110"],
        ":": ["0","1","1","0","1","1","0"],
        ".": ["00","00","00","00","00","11","11"],
        "%": ["11001","11010","00010","00100","01000","01011","10011"],
        "-": ["000","000","000","111","000","000","000"],
        "K": ["10001","10010","10100","11000","10100","10010","10001"],
        "M": ["10001","11011","10101","10101","10001","10001","10001"],
        " ": ["00","00","00","00","00","00","00"]
    ]
    private var width: CGFloat { text.reduce(0) { $0 + CGFloat((Self.glyphs[$1]?.first?.count ?? 3) + 1) * size } - size }
    var body: some View {
        Canvas { context, _ in
            var x: CGFloat = 0
            for character in text {
                let glyph = Self.glyphs[character] ?? Self.glyphs["-"]!
                for (row, line) in glyph.enumerated() {
                    for (column, bit) in line.enumerated() {
                        let rect = CGRect(x: x + CGFloat(column) * size, y: CGFloat(row) * size, width: size * 0.71, height: size * 0.71)
                        context.fill(Path(ellipseIn: rect), with: .color(color.opacity(bit == "1" ? 1 : 0.065)))
                    }
                }
                x += CGFloat(glyph[0].count + 1) * size
            }
        }
        .frame(width: max(0, width), height: size * 7)
        .accessibilityElement(children: .ignore).accessibilityLabel(text)
    }
}
struct Sparkline: View {
    let values: [Double]
    let color: Color
    var body: some View {
        Canvas { context, size in
            guard values.count > 1 else { return }
            var line = Path()
            for (index, value) in values.enumerated() {
                let point = CGPoint(x: CGFloat(index) / CGFloat(values.count - 1) * size.width, y: size.height * (1 - min(100, max(0, value)) / 100))
                if index == 0 { line.move(to: point) } else { line.addLine(to: point) }
            }
            context.stroke(line, with: .color(color), style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
        }.accessibilityHidden(true)
    }
}
