import SwiftUI

struct CapriSpriteView: View {
    var isActive: Bool = false
    var size: CGFloat = 40

    @State private var frameIndex: Int = 0
    private let totalFrames = 60
    private let fps: Double = 24.0

    private let timer = Timer.publish(every: 1.0 / 24.0, on: .main, in: .common).autoconnect()

    var body: some View {
        Group {
            if let image = loadFrame(frameIndex) {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: size, height: size)
            } else {
                Avatar(size: size, pulse: isActive)
            }
        }
        .onReceive(timer) { _ in
            if isActive {
                frameIndex = (frameIndex + 1) % totalFrames
            } else {
                // Лёгкий idle-цикл как на десктопе
                if frameIndex < 20 {
                    frameIndex = (frameIndex + 1) % 20
                } else {
                    frameIndex = (frameIndex + 1) % 10
                }
            }
        }
        .onChange(of: isActive) { _, active in
            if active && frameIndex >= totalFrames {
                frameIndex = 0
            }
        }
    }

    private func loadFrame(_ index: Int) -> UIImage? {
        let name = String(format: "%04d", index)
        let path = "Anim/Capri/\(name)"
        if let image = UIImage(named: path) {
            return image
        }
        // Фоллбек на прямую загрузку из бандла
        if let url = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "Anim/Capri") {
            if let data = try? Data(contentsOf: url) {
                return UIImage(data: data)
            }
        }
        return nil
    }
}
