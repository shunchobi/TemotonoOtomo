


import SwiftUI
import AVFoundation
import Foundation



extension CIImage{
    func resize(to scale: CGFloat) -> CIImage?{
        guard let filter = CIFilter(name: "CILanczosScaleTransform") else{
            return nil
        }
        filter.setDefaults()
        filter.setValue(self, forKey: kCIInputImageKey)
        filter.setValue(scale, forKey: kCIInputScaleKey)
        return filter.outputImage
    }
}

//class Timer{
//    static func get() -> String{
//        let date = Date()
//        let dateFormatter = DateFormatter()
//        dateFormatter.timeStyle = .long
//        let a = dateFormatter.string(from: date)
//        return a
//    }
//}


class Counter{
    static var sentCont = 0
    static var recivedCount = 0
    static var partnersRecivedCount = 0
    static var delta = 0
}


struct ContentView: View {
    
    @StateObject var mpcSession: MPCSession = MPCSession()
    let videoCapture = VideoCapture()
    @State var image: UIImage? = nil
    
    var context = CIContext(options: nil)
    
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
                Text(String("sent count: \(Counter.sentCont)"))
                Text(String("recived count: \(Counter.partnersRecivedCount)"))
                Text(String("delta count: \(Counter.delta)"))
            }
            .font(.largeTitle)
        }
    }
    
    
    
    func DisplayCamera(){
        videoCapture.sending = true
        // スレッドの管理が難しく、各スレッドから同じデータの参照を防ぐ排他制御をするため、ここではDispachqueの使用は避けた
        videoCapture.run { sampleBuffer in
            if let imageData: Data = GetUIImageDataFromSampleBuffer(sampleBuffer, context) {
                mpcSession.send(imageData: imageData)
            }
        }
    }
    
    
    func GetUIImageDataFromSampleBuffer(_ sampleBuffer: CMSampleBuffer, _ context: CIContext) -> Data? {
        if let cvImageBuffer: CVImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            let ciImage: CIImage = CIImage(cvImageBuffer: cvImageBuffer) // リサイズするならここで -> .resize(to: 0.5)
            if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
                let uiImage = UIImage(cgImage: cgImage)
                let imageData = uiImage.jpegData(compressionQuality: 0.1)
                // imageDataと送信回数、受信回数をまとめて一つのデータにするためにMessageクラスをインスタンス
                let imageDataWithCount = Message(image: imageData!, sendCount: UInt(Counter.sentCont), receivedCount: UInt(Counter.recivedCount))
                // imageDataと送信回数、受信回数をまとめて一つのデータにする
                return imageDataWithCount.toData()
            }
        }
        return nil
    }
    
    
    
    ///
    /// sampleBufferをStringにし、これをstartStreamで使用できる？
    ///
    func GetStringAsConveredSampleBufferImage(_ sampleBuffer: CMSampleBuffer) -> String? {
        let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        //        CVPixelBufferLockBaseAddress(imageBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer!)
        let height = CVPixelBufferGetHeight(imageBuffer!)
        let src_buff = CVPixelBufferGetBaseAddress(imageBuffer!)
        let data = NSData(bytes: src_buff, length: bytesPerRow * height).base64EncodedString(options: [])
        CVPixelBufferUnlockBaseAddress(imageBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        return data
    }
    
    
}
