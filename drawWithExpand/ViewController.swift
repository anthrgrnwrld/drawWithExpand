//
//  ViewController.swift
//  drawWithExpand
//
//  Created by Masaki Horimoto on 2016/07/08.
//  Copyright © 2016年 Masaki Horimoto. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIScrollViewDelegate {  //UIScrollViewDelegateを追加

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var canvasView: UIImageView!
    
    var lastPoint: CGPoint?                 //直前のタッチ座標の保存用
    var lineWidth: CGFloat?                 //描画用の線の太さの保存用
    var bezierPath = UIBezierPath()         //お絵描きに使用
    var drawColor = UIColor()               //描画色の保存用
    
    let defaultLineWidth: CGFloat = 10.0    //デフォルトの線の太さ
    
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
        
        //実際のお絵描きで言うキャンバスの準備 (=何も描かれていないUIImageの作成)
        prepareCanvas()
        
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
        firstCanvasImage = UIGraphicsGetImageFromCurrentImageContext()              //何も描かれてないUIImageを取得
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

        lineWidth = defaultLineWidth                                    //描画用の線の太さを決定する
        drawColor = UIColor.blackColor()                                //draw色を決定する
        let touchPoint = drawGesture.locationInView(canvasView)         //タッチ座標を取得
        
        switch drawGesture.state {
        case .Began:
            lastPoint = touchPoint                                      //タッチ座標をlastTouchPointとして保存する

            //touchPointの座標はscrollView基準なのでキャンバスの大きさに合わせた座標に変換しなければいけない
            //LastPointをキャンバスサイズ基準にConvert
            let lastPointForCanvasSize = convertPointForCanvasSize(originalPoint: lastPoint!, canvasSize: canvas.size)
            
            bezierPath.lineCapStyle = .Round                            //描画線の設定 端を丸くする
            bezierPath.lineWidth = defaultLineWidth                     //描画線の太さ
            bezierPath.moveToPoint(lastPointForCanvasSize)
            
        case .Changed:
            
            let newPoint = touchPoint                                   //タッチポイントを最新として保存

            //Draw実行しDraw後のimage取得
            let imageAfterDraw = drawGestureAtChanged(canvas, lastPoint: lastPoint!, newPoint: newPoint, bezierPath: bezierPath)
            
            self.canvasView.image = imageAfterDraw                      //Draw画像をCanvasに上書き
            lastPoint = newPoint                                        //Point保存
            
        case .Ended:
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
        
        return imageAfterDraw
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


}

