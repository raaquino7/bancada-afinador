// Remove o canal alfa de PNGs (as lojas não aceitam capturas com transparência).
// Uso: swift tool/sem_alfa.swift arquivo1.png arquivo2.png ...
// Sobrescreve cada arquivo com um PNG RGB de 24 bits, sem perda.
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

for path in CommandLine.arguments.dropFirst() {
  let url = URL(fileURLWithPath: path)
  guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
        let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
    print("não abriu: \(path)"); exit(1)
  }
  let space = CGColorSpace(name: CGColorSpace.sRGB)!
  guard let context = CGContext(
    data: nil, width: image.width, height: image.height, bitsPerComponent: 8,
    bytesPerRow: 0, space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
  ) else { print("sem contexto: \(path)"); exit(1) }
  context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
  context.fill(CGRect(x: 0, y: 0, width: image.width, height: image.height))
  context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
  guard let flat = context.makeImage(),
        let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
    print("não salvou: \(path)"); exit(1)
  }
  CGImageDestinationAddImage(dest, flat, nil)
  CGImageDestinationFinalize(dest)
  print("ok \(path)")
}
