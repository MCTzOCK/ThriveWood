import SwiftUI

#if os(iOS)
import UIKit
typealias PlatformImage = UIImage
#elseif os(macOS)
import AppKit
typealias PlatformImage = NSImage
#endif

extension Image {
    init(platformImage: PlatformImage) {
        #if os(iOS)
        self.init(uiImage: platformImage)
        #else
        self.init(nsImage: platformImage)
        #endif
    }
}

extension PlatformImage {
    static func fromFile(at path: String) -> PlatformImage? {
        #if os(iOS)
        return PlatformImage(contentsOfFile: path)
        #else
        return PlatformImage(contentsOfFile: path)
        #endif
    }

    func jpegData(compressionQuality: CGFloat) -> Data? {
        #if os(iOS)
        return self.jpegData(compressionQuality: compressionQuality)
        #else
        guard let tiff = self.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let data = rep.representation(using: .jpeg, properties: [.compressionFactor: compressionQuality])
        else { return nil }
        return data
        #endif
    }
}

#if os(macOS)
extension NSImage {
    convenience init?(data: Data) {
        self.init(data: data)
    }
}
#endif
