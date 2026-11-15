import AppKit

// アプリのアイコン(1024px の PNG)を描く。使い方: swiftc make_icon.swift -o make_icon && ./make_icon 出力.png
let size: CGFloat = 1024
let img = NSImage(size: NSSize(width: size, height: size))
img.lockFocus()

// 背景: macOS の標準の大きさ(824px)の角丸の四角に、青のグラデーション
let bgRect = NSRect(x: 100, y: 100, width: 824, height: 824)
let bg = NSBezierPath(roundedRect: bgRect, xRadius: 185, yRadius: 185)
NSGradient(starting: NSColor(red: 0.36, green: 0.62, blue: 1.0, alpha: 1),
           ending: NSColor(red: 0.12, green: 0.36, blue: 0.90, alpha: 1))!.draw(in: bg, angle: -90)

// 紙: 右上の角を折った白い紙
let px: CGFloat = 290, py: CGFloat = 220, pw: CGFloat = 444, ph: CGFloat = 584, fold: CGFloat = 120
let paper = NSBezierPath()
paper.move(to: NSPoint(x: px, y: py))
paper.line(to: NSPoint(x: px + pw, y: py))
paper.line(to: NSPoint(x: px + pw, y: py + ph - fold))
paper.line(to: NSPoint(x: px + pw - fold, y: py + ph))
paper.line(to: NSPoint(x: px, y: py + ph))
paper.close()
let shadow = NSShadow()
shadow.shadowColor = NSColor.black.withAlphaComponent(0.25)
shadow.shadowBlurRadius = 30
shadow.shadowOffset = NSSize(width: 0, height: -12)
NSGraphicsContext.saveGraphicsState()
shadow.set()
NSColor.white.setFill()
paper.fill()
NSGraphicsContext.restoreGraphicsState()

// 折り返し部分
let flap = NSBezierPath()
flap.move(to: NSPoint(x: px + pw - fold, y: py + ph))
flap.line(to: NSPoint(x: px + pw - fold, y: py + ph - fold))
flap.line(to: NSPoint(x: px + pw, y: py + ph - fold))
flap.close()
NSColor(white: 0.82, alpha: 1).setFill()
flap.fill()

// 文字の行(書式のない、ただの文字を表す灰色の線)
NSColor(white: 0.70, alpha: 1).setFill()
let lineH: CGFloat = 34, gap: CGFloat = 72
let widths: [CGFloat] = [250, 344, 344, 300, 344, 210]
for (i, w) in widths.enumerated() {
    let y = py + ph - 200 - CGFloat(i) * gap
    NSBezierPath(roundedRect: NSRect(x: px + 50, y: y, width: w, height: lineH), xRadius: 17, yRadius: 17).fill()
}

// 入力位置を示す青い縦線(エディタらしさ)
NSColor(red: 0.12, green: 0.36, blue: 0.90, alpha: 1).setFill()
let lastY = py + ph - 200 - CGFloat(widths.count - 1) * gap
NSBezierPath(roundedRect: NSRect(x: px + 50 + widths.last! + 22, y: lastY - 14, width: 16, height: lineH + 28),
             xRadius: 8, yRadius: 8).fill()

img.unlockFocus()

let rep = NSBitmapImageRep(data: img.tiffRepresentation!)!
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
