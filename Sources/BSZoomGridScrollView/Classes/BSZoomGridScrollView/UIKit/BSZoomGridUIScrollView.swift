//
//  BSZoomGridUIScrollView.swift
//  BSZoomGridScrollView
//
//  Created by Jang seoksoon on 2019/11/19.
//
//  Copyright (c) 2019 Jang seoksoon <boraseoksoon@gmail.com>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#if os(iOS)
import UIKit

class BSZoomGridUIScrollView: UIScrollView {
    // MARK: - Initializers
    
    /// Using constuctor Dependency Injection, all initialization should be done in the constructor.
    ///
    /// - Parameters:
    ///   - parentView: a parent view to add scrollView as subview
    ///   - imagesToZoom: image array in grid to be displayed.
    ///                   if image numbers are not enough to fill the grid, it will be repeated until grid is fully drawn.
    ///   - powerOfZoomBounce: a value to be able to choose from enum four enumeration types
    ///   - numberOfRows: number of row to be applied in a row.
    ///   - didLongPressItem: closure that will indicates which UIImage is decided to be chosen, by a long touch.
    ///   - didFinishDraggingOnItem: closure that will indicates
    ///                              which UIImage is decided to be chosen, by a end of pan gesture touch.
    /// - Returns: Initializer
    required init(parentView: UIView,
                  imagesToZoom: [UIImage],
                  powerOfZoomBounce: ZoomBounceRatio = .strong,
                  numberOfColumns: Int = 70,
                  numberOfRows: Int = 30,
                  didLongPressItem: ((_: UIImage) -> Void)?,
                  didFinishDraggingOnItem: ((_: UIImage) -> Void)?) {
        if imagesToZoom.count <= 0 {
            fatalError("""
                        At least, image array containing more than one image
                        should be provided!
                        """)
        }
        /// Closures
        self.didLongPressItem = didLongPressItem
        self.didFinishDraggingOnItem = didFinishDraggingOnItem
        
        /// Variables
        self.parentView = parentView
        self.imagesToZoom = imagesToZoom
        
        self.powerOfZoomBounce = powerOfZoomBounce
        
        super.init(frame: parentView.frame)
        
        self.numberOfColumns = numberOfColumns
        self.numberOfRows = numberOfRows

        /// Setup
        addSubview(self.gridBackgroundView)
        
        contentInsetAdjustmentBehavior = .never
        showsVerticalScrollIndicator = true
        showsHorizontalScrollIndicator = true
        alwaysBounceHorizontal = false
        alwaysBounceVertical = true
        
        maximumZoomScale = .infinity
        minimumZoomScale = 1
        
        delegate = self
        backgroundColor = .black
        
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        contentSize = CGSize(width:parentView.frame.size.width,
                             height:scrollViewContentHeight);
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public Instance Variables
    /// public accessor goes here.
    
    
    // MARK: - Private Instance Variables
    /// private accessor goes here.
    private var didLongPressItem: ((_: UIImage) -> Void)?
    private var didFinishDraggingOnItem: ((_: UIImage) -> Void)?
    
    private var scrollViewContentHeight: CGFloat {
        self.absoluteWidth * self._numberOfColumns
    }
    
    private var absoluteWidth: CGFloat {
        self.parentView.frame.width / CGFloat(numberOfRows)
    }
    
    private var parentView: UIView!
    private(set) var powerOfZoomBounce: ZoomBounceRatio
    
    private var imagesToZoom: [UIImage]

    private var _numberOfColumns: CGFloat = 70.0
    private(set) var numberOfColumns: Int {
        get {
            return Int(_numberOfColumns)
        }
        set {
            _numberOfColumns = CGFloat(newValue)
        }
    }
    
    private var _numberOfRows: CGFloat = 30.0
    private(set) var numberOfRows: Int {
        get {
            return Int(_numberOfRows)
        }
        set {
            _numberOfRows = CGFloat(newValue)
        }
    }
    
    private var zoomBounceRatio: CGFloat {
        switch self.powerOfZoomBounce {
            case .weak:
                return 5.0 / (self.zoomScale * 1.0)
            case .regular:
                return 6.0 / (self.zoomScale * 0.9)
            case .strong:
                return 8.0 / (self.zoomScale * 0.85)
            case .crazy:
                return 10.0 / (self.zoomScale * 0.6)
        }
    }
    
    private var cells = [String: UIImageView]()
    private var selectedCell: UIView?
    
    private lazy var longGesture: UILongPressGestureRecognizer = { [unowned self] in
        UILongPressGestureRecognizer(target: self, action: #selector(handleLong))
    }()
    
    private lazy var panGesture: UIPanGestureRecognizer = { [unowned self] in
        UIPanGestureRecognizer(target: self, action: #selector(handlePan))
    }()
    
    private lazy var gridBackgroundView: UIView = { [unowned self] in
        let gridBackgroundView = UIView(frame: CGRect(x:0,
                                                      y:0,
                                                      width:Int(UIScreen.main.bounds.size.width),
                                                      height:Int(scrollViewContentHeight)))
        gridBackgroundView.backgroundColor = .black
        
        var imageIndex = 0
        for j in 0...numberOfColumns {
            for i in 0...numberOfRows {
                imageIndex+=1
                let cellView = UIImageView()
                cellView.backgroundColor = .black
                cellView.frame = CGRect(x: CGFloat(i) * absoluteWidth,
                                        y: CGFloat(j) * absoluteWidth,
                                        width: absoluteWidth,
                                        height: absoluteWidth)
                cellView.layer.borderWidth = 0.2
                cellView.layer.borderColor = UIColor.black.cgColor

                if imagesToZoom.count - 1 < imageIndex { imageIndex = 0 }
                
                let image = imagesToZoom[imageIndex]
                cellView.image = image
                gridBackgroundView.addSubview(cellView)
                
                let key = "\(i)|\(j)"
                cells[key] = cellView
            }
        }
        
        gridBackgroundView.addGestureRecognizer(longGesture)
        gridBackgroundView.addGestureRecognizer(panGesture)
                
        return gridBackgroundView
    }()
    
    // MARK: - Constants
    /// Private Constants
    static let SCROLL_CHECK_DELAY: Double = 0.25
    static let ICON_WIDTH: CGFloat = 77.0
}

// MARK: - Target, Action
///
extension BSZoomGridUIScrollView {
    @objc func handleLong(gesture: UILongPressGestureRecognizer) {
        self.animate(tracking: gesture) { selectedImage in
            self.didLongPressItem?(selectedImage)
        }
    }
    
    @objc func handlePan(gesture: UIPanGestureRecognizer) {
        self.animate(tracking: gesture) { selectedImage in
            self.didFinishDraggingOnItem?(selectedImage)
        }
    }
}

// MARK: - Public instance methods
///

// MARK: - Private instance methods
///
extension BSZoomGridUIScrollView {
    private func animate(tracking gesture: UIGestureRecognizer, completion: @escaping (_: UIImage) -> Void) {
        let location = gesture.location(in: gridBackgroundView)
        let width = gridBackgroundView.frame.width / CGFloat(numberOfRows)
        
        let i = Int(location.x / width * self.zoomScale)
        let j = Int(location.y / width * self.zoomScale)
        
        let key = "\(i)|\(j)"
        
        guard let cellView = cells[key] else { return }
        
        if selectedCell != cellView {
            UIView.animate(withDuration: 0.4,
                           delay: 0,
                           usingSpringWithDamping: 1,
                           initialSpringVelocity: 1,
                           options: .curveEaseOut,
                           animations: {
                            self.selectedCell?.layer.transform = CATransform3DIdentity
            }, completion: nil)
        }
        
        selectedCell = cellView
        
        gridBackgroundView.bringSubviewToFront(cellView)
        
        UIView.animate(withDuration: 0.4,
                       delay: 0,
                       usingSpringWithDamping: 1,
                       initialSpringVelocity: 1,
                       options: .curveEaseOut,
                       animations: {
                        cellView.layer.transform = CATransform3DMakeScale(self.zoomBounceRatio,
                                                                          self.zoomBounceRatio,
                                                                          self.zoomBounceRatio)
        }, completion: nil)
        
        if gesture.state == .ended {
            UIView.animate(withDuration: 0.4,
                           delay: 0.25,
                           usingSpringWithDamping: 0.5,
                           initialSpringVelocity: 0.5,
                           options: .curveEaseOut,
                           animations: {
                            cellView.layer.transform = CATransform3DIdentity
            }, completion: { (_) in
                // self.isScrollEnabled = true
                
                if let image = cellView.image {
                    completion(image)
                }
            })
        }
    }
    
    private func centering(scrollView: UIScrollView) {
        let mainViewSize = self.parentView.frame.size
        let scrollViewSize = scrollView.bounds.size
        
        let verticalInset = mainViewSize.height < scrollViewSize.height
            ? (scrollViewSize.height - mainViewSize.height) / 2
            : 0
        let horizontalInset = mainViewSize.width < scrollViewSize.width
            ? (scrollViewSize.width - mainViewSize.width) / 2
            : 0
        
        scrollView.contentInset = UIEdgeInsets(top: verticalInset,
                                               left: horizontalInset,
                                               bottom: verticalInset,
                                               right: horizontalInset)
    }

    /// TODO: Resolve conflict when using PanGesture in UIScrollView.
    ///
//    private func checkIfTouchAreaWithinScrollRange(scrollView: UIScrollView,
//                                                   r1: ClosedRange<CGFloat>,
//                                                   r2: ClosedRange<CGFloat>,
//                                                   location: CGPoint) -> Bool {
//        if r1 ~= location.y {
//            return true
//        } else if r2 ~= location.y {
//            return true
//        } else {
//            return false
//        }
//    }
}

// MARK: - UIScrollViewDelegate
///
extension BSZoomGridUIScrollView: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.gridBackgroundView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        self.centering(scrollView: scrollView)
    }
    
    /// TODO: Resolve conflict when using PanGesture in UIScrollView.
    ///
//    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
//        let location = scrollView.panGestureRecognizer .location(in: self.parentView)
//
//        let deviceHeight = UIScreen.main.bounds.height
//        let standardHeight = deviceHeight * 0.35
//
//        let rangeOfTopY = 0.0...standardHeight
//        let rangeOfBottomY = (deviceHeight - standardHeight)...deviceHeight
//
//        if self.checkIfTouchAreaWithinScrollRange(scrollView: scrollView,
//                          r1: rangeOfTopY,
//                          r2: rangeOfBottomY,
//                          location: location) {
//            Delay(BSZoomGridUIScrollView.SCROLL_CHECK_DELAY) {
//                   scrollView.isScrollEnabled = true
//               }
//        } else {
//            Delay(BSZoomGridUIScrollView.SCROLL_CHECK_DELAY) {
//                   scrollView.isScrollEnabled = false
//               }
//        }
//    }
}

// MARK: - UIGestureRecognizerDelegate
///
extension BSZoomGridUIScrollView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith
        otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // TODO: Resolve conflict when using PanGesture in UIScrollView.
        // true -> allow both,
        // false -> disable scrollview.
        
        return true
    }
}

#endif
