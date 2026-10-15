// Desenha o ícone do app (anel laranja sobre fundo escuro) como PNG 1024×1024.
// Uso: swift Scripts/make-icon.swift Resources/icon-1024.png
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon-1024.png"
let size = 1024
let cs = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
                    space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!

func rgb(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: cs, components: [
        CGFloat((hex >> 16) & 0xFF) / 255, CGFloat((hex >> 8) & 0xFF) / 255, CGFloat(hex & 0xFF) / 255, a
    ])!
}

let s = CGFloat(size)
// Fundo: quadrado arredondado (macOS deixa margem ~10%).
let inset = s * 0.1
let bg = CGRect(x: inset, y: inset, width: s - 2 * inset, height: s - 2 * inset)
let bgPath = CGPath(roundedRect: bg, cornerWidth: bg.width * 0.22, cornerHeight: bg.width * 0.22, transform: nil)
ctx.addPath(bgPath)
ctx.setFillColor(rgb(0x14161B))
ctx.fillPath()

let center = CGPoint(x: s / 2, y: s / 2)
let radius = bg.width * 0.3
let lineWidth = bg.width * 0.075

// Trilho apagado
ctx.setLineWidth(lineWidth)
ctx.setLineCap(.round)
ctx.setStrokeColor(rgb(0xFFFFFF, 0.08))
ctx.addArc(center: center, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
ctx.strokePath()

// Arco de 270° a partir do topo, no sentido horário
ctx.setStrokeColor(rgb(0xFF8A3D))
ctx.addArc(center: center, radius: radius, startAngle: .pi / 2, endAngle: .pi / 2 - .pi * 1.5, clockwise: true)
ctx.strokePath()

let image = ctx.makeImage()!
let url = URL(fileURLWithPath: out)
let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, image, nil)
guard CGImageDestinationFinalize(dest) else { fatalError("falha ao gravar \(out)") }
print("✔ \(out)")
