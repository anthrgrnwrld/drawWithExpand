//
//  ViewController.swift
//  drawWithExpand
//
//  Created by Masaki Horimoto on 2016/07/08.
//  Copyright © 2016年 Masaki Horimoto. All rights reserved.
//

import UIKit
import Photos

class ViewController: UIViewController, UIScrollViewDelegate {  //UIScrollViewDelegateを追加

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var canvasView: UIImageView!
    @IBOutlet weak var sliderValue: UISlider!
    
    var lastPoint: CGPoint?                 //直前のタッチ座標の保存用
    var lineWidth: CGFloat?                 //描画用の線の太さの保存用
    //var bezierPath = UIBezierPath()         //お絵描きに使用
    var bezierPath: UIBezierPath?           //お絵描きに使用
    var drawColor = UIColor()               //描画色の保存用
    var currentDrawNumber = 0               //現在の表示しているは何回めのタッチか
    var saveImageArray = [UIImage]()        //Undo/Redo用にUIImageを保存
    
    //let defaultLineWidth: CGFloat = 10.0    //デフォルトの線の太さ
    let scale = CGFloat(30)                   //線の太さに変換するためにSlider値にかける係数
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0                   // 最小拡大率
        scrollView.maximumZoomScale = 4.0                   // 最大拡大率
        scrollView.zoomScale = 1.0                          // 表示時の拡大率(初期値)
        
        prepareDrawing()                                    //お絵描き準備
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /**
     拡大縮小に対応
     */
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return self.canvasView
    }
    
    /**
     UIGestureRecognizerでお絵描き対応。1本指でなぞった時のみの対応とする。
     */
    private func prepareDrawing() {
        
        //実際のお絵描きで言う描く手段(色えんぴつ？クレヨン？絵の具？など)の準備
        let myDraw = UIPanGestureRecognizer(target: self, action: #selector(ViewController.drawGesture(_:)))
        myDraw.maximumNumberOfTouches = 1
        self.scrollView.addGestureRecognizer(myDraw)
        
        drawColor = UIColor.blackColor()                    //draw色を黒色に決定する
        lineWidth = CGFloat(sliderValue.value) * scale      //線の太さを決定する
        
        //実際のお絵描きで言うキャンバスの準備 (=何も描かれていないUIImageの作成)
        prepareCanvas()
        
        saveImageArray.append(self.canvasView.image!)       //配列にcanvasView.imageを保存
        
    }

    /**
     キャンバスの準備 (何も描かれていないUIImageの作成)
     */
    func prepareCanvas() {
        let canvasSize = CGSizeMake(view.frame.width * 2, view.frame.width * 2)     //キャンバスのサイズの決定
        let canvasRect = CGRectMake(0, 0, canvasSize.width, canvasSize.height)      //キャンバスのRectの決定
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, 0.0)              //コンテキスト作成(キャンバスのUIImageを作成する為)
        var firstCanvasImage = UIImage()                                            //キャンバス用UIImage(まだ空っぽ)
        UIColor.whiteColor().setFill()                                              //白色塗りつぶし作業1
        UIRectFill(canvasRect)                                                      //白色塗りつぶし作業2
        firstCanvasImage.drawInRect(canvasRect)                                     //firstCanvasImageの内容を描く(真っ白)
        firstCanvasImage = UIGraphicsGetImageFromCurrentImageContext()!              //何も描かれてないUIImageを取得
        canvasView.contentMode = .ScaleAspectFit                                    //contentModeの設定
        canvasView.image = firstCanvasImage                                         //画面の表示を更新
        UIGraphicsEndImageContext()                                                 //コンテキストを閉じる
    }
    
    
    /**
     draw動作
     */
    func drawGesture(sender: AnyObject) {
        
        guard let drawGesture = sender as? UIPanGestureRecognizer else {
            print("drawGesture Error happened.")
            return
        }
        
        guard let canvas = self.canvasView.image else {
            fatalError("self.pictureView.image not found")
        }

        //lineWidth = defaultLineWidth                                    //描画用の線の太さを決定する
        //drawColor = UIColor.blackColor()                                //draw色を決定する
        let touchPoint = drawGesture.locationInView(canvasView)         //タッチ座標を取得
        
        switch drawGesture.state {
        case .Began:
            lastPoint = touchPoint                                      //タッチ座標をlastTouchPointとして保存する

            //touchPointの座標はscrollView基準なのでキャンバスの大きさに合わせた座標に変換しなければいけない
            //LastPointをキャンバスサイズ基準にConvert
            let lastPointForCanvasSize = convertPointForCanvasSize(originalPoint: lastPoint!, canvasSize: canvas.size)
            
            bezierPath = UIBezierPath()
            guard let bzrPth = bezierPath else {
                fatalError("bezierPath Error")
            }
            
            bzrPth.lineCapStyle = .Round                            //描画線の設定 端を丸くする
            //bzrPth.lineWidth = defaultLineWidth                     //描画線の太さ
            bzrPth.lineWidth = lineWidth!                           //描画線の太さ
            bzrPth.moveToPoint(lastPointForCanvasSize)
            
        case .Changed:
            
            let newPoint = touchPoint                                   //タッチポイントを最新として保存
            
            guard let bzrPth = bezierPath else {
                fatalError("bezierPath Error")
            }

            //Draw実行しDraw後のimage取得
            let imageAfterDraw = drawGestureAtChanged(canvas, lastPoint: lastPoint!, newPoint: newPoint, bezierPath: bzrPth)
            
            self.canvasView.image = imageAfterDraw                      //Draw画像をCanvasに上書き
            lastPoint = newPoint                                        //Point保存
            
        case .Ended:

            //currentDrawNumberとsaveImageArray配列数が矛盾無きまでremoveLastする
            while currentDrawNumber != saveImageArray.count - 1 {
                saveImageArray.removeLast()
            }
            
            currentDrawNumber += 1
            saveImageArray.append(self.canvasView.image!)               //配列にcanvasView.imageを保存
            
            if currentDrawNumber != saveImageArray.count - 1 {
                fatalError("index Error")
            }
            
            print("Finish dragging")
            
        default:
            ()
        }
        
    }
    
    /**
     UIGestureRecognizerのStatusが.Changedの時に実行するDraw動作
     
     - parameter canvas : キャンバス
     - parameter lastPoint : 最新のタッチから直前に保存した座標
     - parameter newPoint : 最新のタッチの座標座標
     - parameter bezierPath : 線の設定などが保管されたインスタンス
     - returns : 描画後の画像
     */
    func drawGestureAtChanged(canvas: UIImage, lastPoint: CGPoint, newPoint: CGPoint, bezierPath: UIBezierPath) -> UIImage {
        
        //最新のtouchPointとlastPointからmiddlePointを算出
        let middlePoint = CGPointMake((lastPoint.x + newPoint.x) / 2, (lastPoint.y + newPoint.y) / 2)
        
        //各ポイントの座標はscrollView基準なのでキャンバスの大きさに合わせた座標に変換しなければいけない
        //各ポイントをキャンバスサイズ基準にConvert
        let middlePointForCanvas = convertPointForCanvasSize(originalPoint: middlePoint, canvasSize: canvas.size)
        let lastPointForCanvas   = convertPointForCanvasSize(originalPoint: lastPoint, canvasSize: canvas.size)
        
        bezierPath.addQuadCurveToPoint(middlePointForCanvas, controlPoint: lastPointForCanvas)  //曲線を描く
        UIGraphicsBeginImageContextWithOptions(canvas.size, false, 0.0)                 //コンテキストを作成
        let canvasRect = CGRectMake(0, 0, canvas.size.width, canvas.size.height)        //コンテキストのRect
        self.canvasView.image?.drawInRect(canvasRect)                                   //既存のCanvasを準備
        drawColor.setStroke()                                                           //drawをセット
        bezierPath.stroke()                                                             //draw実行
        let imageAfterDraw = UIGraphicsGetImageFromCurrentImageContext()                //Draw後の画像
        UIGraphicsEndImageContext()                                                     //コンテキストを閉じる
        
        return imageAfterDraw!
    }

    /**
     (おまじない)座標をキャンバスのサイズに準じたものに変換する
     
     - parameter originalPoint : 座標
     - parameter canvasSize : キャンバスのサイズ
     - returns : キャンバス基準に変換した座標
     */
    func convertPointForCanvasSize(originalPoint originalPoint: CGPoint, canvasSize: CGSize) -> CGPoint {
        
        let viewSize = scrollView.frame.size
        var ajustContextSize = canvasSize
        var diffSize: CGSize = CGSizeMake(0, 0)
        let viewRatio = viewSize.width / viewSize.height
        let contextRatio = canvasSize.width / canvasSize.height
        let isWidthLong = viewRatio < contextRatio ? true : false
        
        if isWidthLong {
            
            ajustContextSize.height = ajustContextSize.width * viewSize.height / viewSize.width
            diffSize.height = (ajustContextSize.height - canvasSize.height) / 2
            
        } else {
            
            ajustContextSize.width = ajustContextSize.height * viewSize.width / viewSize.height
            diffSize.width = (ajustContextSize.width - canvasSize.width) / 2
            
        }
        
        let convertPoint = CGPointMake(originalPoint.x * ajustContextSize.width / viewSize.width - diffSize.width,
                                       originalPoint.y * ajustContextSize.height / viewSize.height - diffSize.height)
        
        
        return convertPoint
        
    }

    /**
     Redボタンを押した時の動作
     ペンを赤色にする
     */
    @IBAction func selectRed(sender: AnyObject) {
        
        drawColor = UIColor.redColor()      //赤色に変更する
    }

    /**
     Greenボタンを押した時の動作
     ペンを緑色にする
     */
    @IBAction func selectGreen(sender: AnyObject) {
        
        drawColor = UIColor.greenColor()    //緑色に変更する
    }

    /**
     Blueボタンを押した時の動作
     ペンを青色にする
     */
    @IBAction func selectBlue(sender: AnyObject) {
        
        drawColor = UIColor.blueColor()     //青色に変更する
        
    }

    /**
     Blackボタンを押した時の動作
     ペンを黒色にする
     */
    @IBAction func selecBlack(sender: AnyObject) {
        
        drawColor = UIColor.blackColor()    //黒色に変更する
    }

    /**
     スライダーを動かした時の動作
     ペンの太さを変更する
     */
    @IBAction func slideSlider(sender: AnyObject) {
        
        lineWidth = CGFloat(sliderValue.value) * scale
 
    }

    /**
     Undoボタンを押した時の動作
     Undoを実行する
     */
    @IBAction func pressUndoButton(sender: AnyObject) {
        
        if currentDrawNumber <= 0 {return}
        
        self.canvasView.image = saveImageArray[currentDrawNumber - 1]   //保存している直前imageに置き換える
        
        currentDrawNumber -= 1
        
    }
    
    /**
     Redoボタンを押した時の動作
     Redoを実行する
     */
    @IBAction func pressRedoButton(sender: AnyObject) {
        
        if currentDrawNumber + 1 > saveImageArray.count - 1 {return}
        
        self.canvasView.image = saveImageArray[currentDrawNumber + 1]   //保存しているUndo前のimageに置き換える
        
        currentDrawNumber += 1
        
    }

    /**
     Saveボタンを押した時の動作
     お絵描きをカメラロールへ保存する
     */
    @IBAction func pressSaveButton(sender: AnyObject) {
        
        UIImageWriteToSavedPhotosAlbum(self.canvasView.image!, self, nil, nil)  //カメラロールへの保存
        
    }

    /**
     Instagramボタンを押した時の動作
     URLスキームを使ってInstagramアプリのライブラリ画面を表示する
     */
    @IBAction func pressInstagramButton(sender: AnyObject) {
 
        var imageIdentifier: String?
        PHPhotoLibrary.sharedPhotoLibrary().performChanges({ () -> Void in
            let createAssetRequest = PHAssetChangeRequest.creationRequestForAssetFromImage(self.canvasView.image!)
            let placeHolder = createAssetRequest.placeholderForCreatedAsset
            imageIdentifier = placeHolder!.localIdentifier
            }, completionHandler: { (success, error) -> Void in
                print("Finished adding asset.\(success ? "success" : "error")")
                print("\(imageIdentifier)")
                let testURL = NSURL(string: "instagram://library?LocalIdentifier=" + imageIdentifier!)
                if UIApplication.sharedApplication().canOpenURL(testURL!) {
                    UIApplication.sharedApplication().openURL(testURL!)
                }
        })
        
    }

    
}

