//
//  ViewController.swift
//  GifDemo
//
//  Created by lisilong on 2017/11/1.
//  Copyright © 2017年 LongShaoDream. All rights reserved.
//

import UIKit
import MobileCoreServices

class ViewController: UIViewController {
    
    let kImagesCount: NSInteger = 24   // 图片集个数
    
    lazy var imageView: UIImageView = {
        let imageView: UIImageView = UIImageView()
        return imageView
    }()
    
    var timer: Timer?
    var displayLink: CADisplayLink?
    
    var index: NSInteger = 1
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 一、把gif图转换成png格式的图片集，并保存到沙盒中
//        let _ = self.transformGifToPngsAndSaveToLocal(gifName: "shopping")
        
        
        // 二、把图片集合成gif图
//        let _ = self.transformImagesToGifAndSaveToDocument()
        
        
        // 三、播放Gif图
        self.view.addSubview(imageView)
        imageView.center = self.view.center;
        imageView.bounds.size = CGSize.init(width: self.view.bounds.size.width, height: 50)
        
        // 方法一：使用UIimageView播放gif图片
        self.showGifByUIImageView(images: self.loadImages())
        
        // 方法二：使用定时器Timer播放gif图片
//        self.showGifByTimer()
        
        // 方法三：使用CADisplayLink播放gif图片
//        self.showGifByCADisplayLink()
    }
}

// MARK: - GIF ==> pngs

extension ViewController {
    
    /// 把GIF动图转换成png格式的图片集，并把它们保存到沙盒中
    ///
    /// Parameters: gifName: gif图名称
    func transformGifToPngsAndSaveToLocal(gifName: String) -> Bool {
        
        /// 1.读取gif图片为data数据
        let gifData = self.loadGifInLocal(gifName: gifName)
        guard gifData != nil else {
            return false
        }
        
        // 2. 生成image图片数据
        let images = self.createImage(gifData: gifData)
        guard images?.count != 0 else {
            return false
        }
        
        // 3. 把图片保存到本地沙盒
        return self.saveImagesToLocal(imageArray: images as? Array<UIImage>)
    }
    
    
    /// 从本地读取gif图片 ==> 生成data数据
    func loadGifInLocal(gifName: String?) -> Data? {
        guard gifName != nil else {
            return nil
        }
        
        let gifPath = Bundle.main.path(forResource: gifName, ofType: "gif")
        guard gifPath != nil else {
            print("文件名为" + gifName! + "的gif图不存在！")
            return nil
        }
        var gifData: Data = Data.init()
        do {
            gifData = try Data.init(contentsOf: URL.init(fileURLWithPath: gifPath!))
        } catch {
            print(error)
        }
        return gifData
    }
    
    /// 将data图片数据转换成image
    func createImage(gifData: Data?) -> NSArray? {
        guard gifData != nil else {
            return nil
        }
        
        let gifDataSource: CGImageSource = CGImageSourceCreateWithData(gifData! as CFData, nil)!
        let gifImageCount: NSInteger = CGImageSourceGetCount(gifDataSource)
        let images: NSMutableArray   = NSMutableArray.init()
        for index in 0...gifImageCount-1 {
            let imageref: CGImage? = CGImageSourceCreateImageAtIndex(gifDataSource, index, nil)
            let image: UIImage = UIImage.init(cgImage: imageref!, scale: UIScreen.main.scale, orientation: UIImageOrientation.up)
            images.add(image)
        }
        return images
    }
    
    /// 将image图片保存到本地沙盒
    func saveImagesToLocal(imageArray images: Array<UIImage>?) -> Bool {
        guard images?.count != 0 else {
            return false
        }
        
        for image in images! {
            let index = images?.index(of: image)
            let imageData: Data = UIImagePNGRepresentation(image)!
            let docs = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
            let documentsDirectory: String = docs[0] as String
            let imagePath = documentsDirectory + "/shopping\(index ?? 0)" + ".png"
            try? imageData.write(to: URL.init(fileURLWithPath: imagePath), options: [.atomic])
            print(imagePath)
        }
        return true
    }
}



// MARK: - pngs ==> gif

extension ViewController {
    
    /// 把图片集合成GIF图片，并保存到沙盒中
    func transformImagesToGifAndSaveToDocument() -> Bool {
        
        // 1.加载本地图片
        let images: NSArray = self.loadImages()
        guard images.count > 0 else {
            return false
        }
        
        // 2.创建Gif图在Document中的保存路径
        let gifPath: String = self.creatGifPath()
        guard gifPath.characters.count > 0 else {
            return false
        }
        
        // 3.设置GIF属性，利用ImageIO编码GIF文件，并保存到沙盒中
        return self.saveGifToDocument(imageArray: images, gifPath)
    }
    
    
    // 1. 加载本地图片
    func loadImages() -> NSArray {
        let imageArray: NSMutableArray = NSMutableArray()
        for i in 1...kImagesCount {
            let image = UIImage.init(named: "refresh_gif\(i).png")
            if image != nil {
                imageArray.add(image!)
            }
        }
        return imageArray
    }
    
    // 2.创建Gif图在Document中的保存路径
    func creatGifPath() -> String {
        let docs = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let gifPath = docs[0] as String + "/refresh.gif"
        print(gifPath)
        return gifPath
    }
    
    // 3.设置GIF属性，利用ImageIO编码GIF文件
    func saveGifToDocument(imageArray images: NSArray, _ gifPath: String) -> Bool {
        guard images.count > 0 &&
            gifPath.characters.count > 0 else {
                return false
        }
        let url = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, gifPath as CFString, .cfurlposixPathStyle, false)
        let destion = CGImageDestinationCreateWithURL(url!, kUTTypeGIF, images.count, nil)
        
        // 设置gif图片属性
        // 设置每帧之间播放的时间0.1
        let delayTime = [kCGImagePropertyGIFDelayTime as String:0.1]
        let destDic   = [kCGImagePropertyGIFDictionary as String:delayTime]
        // 依次为gif图像对象添加每一帧属性
        for image in images {
            CGImageDestinationAddImage(destion!, (image as AnyObject).cgImage!!, destDic as CFDictionary?)
        }
        
        let propertiesDic: NSMutableDictionary = NSMutableDictionary()
        propertiesDic.setValue(kCGImagePropertyColorModelRGB, forKey: kCGImagePropertyColorModel as String)
        propertiesDic.setValue(16, forKey: kCGImagePropertyDepth as String)         // 设置图片的颜色深度
        propertiesDic.setValue(1, forKey: kCGImagePropertyGIFLoopCount as String)   // 设置Gif执行次数
        
        let gitDestDic = [kCGImagePropertyGIFDictionary as String:propertiesDic]    // 为gif图像设置属性
        CGImageDestinationSetProperties(destion!, gitDestDic as CFDictionary?)
        CGImageDestinationFinalize(destion!)
        return true
    }
}


// MARK: - 播放Gif图
extension ViewController {
    
    // 方法一：使用UIimageView播放gif图片
    func showGifByUIImageView(images: NSArray) -> () {
        if images.count > 0 {
            self.imageView.animationImages = images as? [UIImage]
            self.imageView.animationDuration = 2.0
            self.imageView.animationRepeatCount = 300
            self.imageView.startAnimating()
        }
    }
    
    // 方法二：使用定时器Timer播放gif图片
    func showGifByTimer() -> () {
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(refreshImageView), userInfo: nil, repeats: true)
        RunLoop.current.add(timer!, forMode: RunLoopMode.commonModes)
    }
    
    // 方法三：使用CADisplayLink播放gif图片
    func showGifByCADisplayLink() -> () {
        displayLink = CADisplayLink.init(target: self, selector: #selector(refreshImageView))
        displayLink?.frameInterval = 6
        displayLink?.add(to: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
    }
    
    @objc func refreshImageView() -> () {
        if index < 1 || index > kImagesCount {
            index = 1
        }
        let image: UIImage = UIImage.init(named: "refresh_gif\(index).png")!
        imageView.image = image
        index += 1
    }
}






