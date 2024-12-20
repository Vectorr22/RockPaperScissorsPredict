import SwiftUI
import CoreML

// Extensión para convertir UIImage a CVPixelBuffer
extension UIImage {
    func toCVPixelBuffer() -> CVPixelBuffer? {
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                     kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         Int(self.size.width),
                                         Int(self.size.height),
                                         kCVPixelFormatType_32ARGB,
                                         attrs,
                                         &pixelBuffer)
        guard status == kCVReturnSuccess else { return nil }

        CVPixelBufferLockBaseAddress(pixelBuffer!, .readOnly)
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)

        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData,
                                width: Int(self.size.width),
                                height: Int(self.size.height),
                                bitsPerComponent: 8,
                                bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!),
                                space: rgbColorSpace,
                                bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)

        context?.translateBy(x: 0, y: self.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)

        UIGraphicsPushContext(context!)
        self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        UIGraphicsPopContext()

        CVPixelBufferUnlockBaseAddress(pixelBuffer!, .readOnly)
        return pixelBuffer
    }
}

struct ContentView: View {
    
    let images = [
        "testpaper01-00", "testpaper01-01", "testpaper01-02", "testpaper01-03", "testpaper01-04",
        "testrock01-00", "testrock01-01", "testrock01-02", "testrock01-03", "testrock01-04",
        "testscissors01-00", "testscissors01-01", "testscissors01-02", "testscissors01-03", "testscissors01-04"
    ]
    
    var imageClassifier: RockPaperScissorClassifier_1?
    @State private var currentIndex = 0
    @State private var classLabel: String = ""
    
    init() {
        do {
            imageClassifier = try RockPaperScissorClassifier_1(configuration: MLModelConfiguration())
        } catch {
            print(error)
        }
    }
    
    var isPreviousButtonValid: Bool {
        currentIndex != 0
    }
    
    var isNextButtonValid: Bool {
        currentIndex < images.count - 1
    }
    
    var body: some View {
        ZStack {
            // Fondo degradado
            LinearGradient(gradient: Gradient(colors: [.black, .gray]),
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                
                // Encabezado llamativo
                ZStack {
                    LinearGradient(gradient: Gradient(colors: [.blue, .purple]),
                                   startPoint: .leading, endPoint: .trailing)
                        .frame(height: 150)
                        .cornerRadius(20)
                    HStack {
                        Image(systemName: "hand.raised.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 40))
                        Text("Piedra, Papel o Tijera!")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal)
                
                // Imagen estilizada
                Image(images[currentIndex])
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 250)
                    .cornerRadius(15)
                    .shadow(color: .gray.opacity(0.5), radius: 10, x: 0, y: 5)
                    .overlay(RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.blue, lineWidth: 2))
                    .padding()
                
                // Etiqueta para imagen actual
                Text("Imagen actual")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                // Botón para predecir
                Button(action: {
                    guard let uiImage = UIImage(named: images[currentIndex]) else { return }
                    guard let pixelBuffer = uiImage.toCVPixelBuffer() else { return }
                    
                    do {
                        let result = try imageClassifier?.prediction(image: pixelBuffer)
                        classLabel = result?.target ?? ""
                    } catch {
                        print(error)
                    }
                }) {
                    Text("Predecir")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(LinearGradient(gradient: Gradient(colors: [.green, .blue]),
                                                   startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // Resultado estilizado
                Text(classLabel.isEmpty ? "Presiona Predecir" : "Resultado: \(classLabel)")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(classLabel.isEmpty ? Color.gray : Color.green)
                    .cornerRadius(10)
                    .animation(.easeInOut, value: classLabel)
                
                // Botones de navegación
                HStack {
                    Button(action: { currentIndex -= 1 }) {
                        Label("Anterior", systemImage: "chevron.left")
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.8))
                    .cornerRadius(10)
                    .disabled(!isPreviousButtonValid)
                    
                    Spacer()
                    
                    Text("\(currentIndex + 1) / \(images.count)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Button(action: { currentIndex += 1 }) {
                        Label("Siguiente", systemImage: "chevron.right")
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.8))
                    .cornerRadius(10)
                    .disabled(!isNextButtonValid)
                }
                .padding(.horizontal)
            }
            .padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
