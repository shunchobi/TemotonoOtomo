


import SwiftUI
import AVFoundation



extension CIImage{
    func resize(to scale: CGFloat) -> CIImage?{
        print("from extension CIImage")
        guard let filter = CIFilter(name: "CILanczosScaleTransform") else{
            return nil
        }
        filter.setDefaults()
        filter.setValue(self, forKey: kCIInputImageKey)
        filter.setValue(scale, forKey: kCIInputScaleKey)
        return filter.outputImage
    }
}


struct ContentView: View {
    
    @StateObject var mpcSession: MPCSession = MPCSession()
    let videoCapture = VideoCapture()
    @State var image: UIImage? = nil
    @State var testNum = 1
    
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
    
//    //非同期スレッドの作成
//        DispatchQueue(label: "my.async").async {
//            //ここで非同期でのメイン処理をする
//            //do something
//
//            //非同期スレッドの中に後処理でしたいものを入れる。
//            //ここでは画面描画の処理をしたいのでメインスレッドで動くように指定している。
//            DispatchQueue.main.sync {
//                    self.didCount += 1
//                    self.progressBar.doubleValue = Double(self.didCount)
//                    self.btnRedraw(self)
//                    self.tableview.reloadData()
//                }
//            })
//
    

    func DisplayCamera(){
        videoCapture.run { sampleBuffer in

            if let convertImage = UIImageFromSampleBuffer(sampleBuffer) { // Heavy Process
//            if let convertImage = getScreenImageData(sampleBuffer) { // fail
//            if let convertImage = imageFromSampleBuffer(sampleBuffer) { // fail
//                if let convertImage = GetStringAsConveredSampleBufferImage(sampleBuffer) { // fail
                DispatchQueue.main.async {
//                        self.image = convertImageß
//                        if let image = self.image{
//                            print("call send func")
                    if let imageData = convertImage.jpegData(compressionQuality: 0.1) { // heavy
                        let encodeString:String = imageData.base64EncodedString(options: [])
                        let data: Data? = encodeString.data(using: .utf8) // --> これを配信する
                            mpcSession.send(imageData: data)
                    }
                }
        }
        }
    }
    
    
    func GetStringAsConveredSampleBufferImage(_ sampleBuffer: CMSampleBuffer) -> String? {
        let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        CVPixelBufferLockBaseAddress(imageBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer!)
        let height = CVPixelBufferGetHeight(imageBuffer!)
        let src_buff = CVPixelBufferGetBaseAddress(imageBuffer!)
        let data = NSData(bytes: src_buff, length: bytesPerRow * height).base64EncodedString(options: [])
        CVPixelBufferUnlockBaseAddress(imageBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        return data
    }
    

    func UIImageFromSampleBuffer(_ sampleBuffer: CMSampleBuffer) -> UIImage? {
//        if let dataBuffer: CMBlockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) {
        if let pixelBuffer: CVImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer) // Heavy Process
            
//            guard let resizedCiImage = ciImage.resize(to: 0.5) else{
//                return nil
//            }
            
            let imageRect = CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))
            let context = CIContext()
            if let image = context.createCGImage(ciImage, from: imageRect) {
                return UIImage(cgImage: image)
            }
        }
        return nil
    }
    

    
    
    func getScreenImageData(_ sampleBuffer: CMSampleBuffer) -> UIImage? {
        
//        guard let colorSpace = UIImageFromSampleBuffer(sampleBuffer)!.cgImage!.colorSpace else {return nil}
        print("call from button")
        guard let imageBuffer: CVImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                print("fail No 1")
                return nil
        }
        
        
//        // test for space color
//        let pixelBuffer: CVImageBuffer? = CMSampleBufferGetImageBuffer(sampleBuffer)
//        let ciImage = CIImage(cvPixelBuffer: pixelBuffer!) // Heavy Process
//
//        let uiImage: UIImage? = UIImageFromSampleBuffer(sampleBuffer)
//
//        let colorspaces = CGColorSpace(name: CGColorSpace.sRGB)
//        print("colorspaces = \(type(of: colorspaces))")
//        //////////////
        
        
        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        guard let baseAddress: UnsafeMutableRawPointer = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0) else {
            print("fail No 2")
                return nil
        }
        let bytesPerRow:Int = CVPixelBufferGetBytesPerRow(imageBuffer)
        let width:Int = CVPixelBufferGetWidth(imageBuffer)
        let height:Int = CVPixelBufferGetHeight(imageBuffer)
        
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        // CGImageAlphaInfo.premultipliedFirst.rawValue|CGBitmapInfo.byteOrder32Little.rawValue
        let colorSpace:CGColorSpace = CGColorSpaceCreateDeviceRGB()
        // CGColorSpaceCreateDeviceRGB


        print("colorSpace = \(type(of: colorSpace))")
        print("bitmapInfo = \(type(of: bitmapInfo.rawValue))")


        guard let newContext: CGContext = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue) else {
            print("fail No 3")
            return nil
        }
        guard let imageRef: CGImage = newContext.makeImage() else {
            print("fail No 4")
            return nil
        }
        let image = UIImage(cgImage: imageRef, scale: 0.0, orientation: .up)
        return image
    }
    
    
    
//
//    func imageFromSampleBuffer(_ sampleBuffer: CMSampleBuffer) -> UIImage? {
//        if let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
//            CVPixelBufferLockBaseAddress(imageBuffer, .readOnly)
//            let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer)
//            let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
//            let width = CVPixelBufferGetWidth(imageBuffer)
//            let height = CVPixelBufferGetHeight(imageBuffer)
//            let colorSpace = CGColorSpaceCreateDeviceRGB()
//            let context = CGContext(data: baseAddress,width: width,height: height,bitsPerComponent: 8,bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)
//
//            print("concolorSpacetext! = \(type(of: colorSpace))")
//            return nil
//            let quartzImage = CGBitmapContextCreateImage(context)
//            CVPixelBufferUnlockBaseAddress(imageBuffer,0)
//
//            if let quartzImage = quartzImage {
//                let image = UIImage(CGImage: quartzImage)
//                return image
//            }
//        }
//        return nil
//    }

}
