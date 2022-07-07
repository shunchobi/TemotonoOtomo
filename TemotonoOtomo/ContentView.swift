


import SwiftUI
import AVFoundation

struct ContentView: View {
    
//    @ObservedObject
    @StateObject var mpcSession: MPCSession = MPCSession()
    let videoCapture = VideoCapture()
    @State var image: UIImage? = nil 
    
    var body: some View {
        VStack {
            if let shareImage = mpcSession.currentScreenImage {
                Image(uiImage: shareImage)
                    .resizable()
                    .scaledToFit()
            }
            
            HStack {
                Button("share\nscreen") {
                    DisplayCamera()
                }
            }
            .font(.largeTitle)
        }
    }
    
    
    func DisplayCamera(){
        videoCapture.run { sampleBuffer in
            if let convertImage = UIImageFromSampleBuffer(sampleBuffer) {
                DispatchQueue.main.async {
                    self.image = convertImage
                    if let image = self.image{
                        mpcSession.send(screenImage: image)
                    }
                }
            }
        }
    }

    func UIImageFromSampleBuffer(_ sampleBuffer: CMSampleBuffer) -> UIImage? {
        if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let imageRect = CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))
            let context = CIContext()
            if let image = context.createCGImage(ciImage, from: imageRect) {
                return UIImage(cgImage: image)
            }
        }
        return nil
    }

}
