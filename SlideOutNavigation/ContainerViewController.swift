/// Copyright (c) 2017 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit
import QuartzCore

class ContainerViewController: UIViewController {
  var centerViewController: CenterViewController!
  var centerNavigationController: UINavigationController!
  
  enum SlideOutState { case both, leftPanelCollapsed, rightPanelCollapsed }
  private var currentState: SlideOutState = .both {
    didSet {
      let shouldShowShadow = currentState != .both
      shadowForCenterViewController(shouldShowShadow)
    }
  }
  private var leftViewController: SidePanelViewController?
  private var rightViewController: SidePanelViewController?
  
  private let centerPanelExpandOffset: CGFloat = 60
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    centerViewController = UIStoryboard.centerViewController()
    centerViewController.delegate = self
    
    // wrap the centerViewController in a navigation controller, so we can push views to it
    // and display bar button items in the navigation bar
    centerNavigationController = UINavigationController(rootViewController: centerViewController)
    view.addSubview(centerNavigationController.view)
    addChildViewController(centerNavigationController)
    
    centerNavigationController.didMove(toParentViewController: self)
    
    let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
    centerNavigationController.view.addGestureRecognizer(panGestureRecognizer)
  }
}

extension ContainerViewController: UIGestureRecognizerDelegate {
  @objc func handlePanGesture(_ recognizer: UIPanGestureRecognizer) {
    let gestureIsDraggingFromLeftToRight = (recognizer.velocity(in: view).x > 0)
    switch recognizer.state {
    case .began:
      guard currentState == .both else { break }
      if gestureIsDraggingFromLeftToRight {
        addLeftPanelViewController()
      } else {
        addRightPanelViewController()
      }
      shadowForCenterViewController(true)
    case .changed:
      guard let rview = recognizer.view else { break }
      rview.center.x = recognizer.translation(in: view).x
      recognizer.setTranslation(.zero, in: view)
    case .ended:
      guard let rview = recognizer.view else { break }
      if leftViewController != nil {
        // animate the side panel open or closed based on whether the view
        // has moved more or less than halfway
        let hasMovedGreaterTheHalfWay = rview.center.x > view.bounds.size.width
        animateLeftPanel(shouldExpand: hasMovedGreaterTheHalfWay)
      } else if rightViewController != nil {
        let hasMovedGreaterTheHalfWay = 0 < rview.center.x
        animateRightPanel(shouldExpand: hasMovedGreaterTheHalfWay)
      }
    default: break
    }
  }
}

extension ContainerViewController: CenterViewControllerDelegate {
  func toggleLeftPanel() {
    let notAlreadyExpanded = currentState != .leftPanelCollapsed
    if notAlreadyExpanded {
      addLeftPanelViewController()
    }
    animateLeftPanel(shouldExpand: notAlreadyExpanded)
  }
  func toggleRightPanel() {
    let notAlreadyExpanded = currentState != .rightPanelCollapsed
    if notAlreadyExpanded {
      addRightPanelViewController()
    }
    animateRightPanel(shouldExpand: notAlreadyExpanded)
  }
  
  func collapseSidePanels() {
    switch currentState {
    case .both: break
    case .leftPanelCollapsed: toggleLeftPanel()
    case .rightPanelCollapsed: toggleRightPanel()
    }
  }
  private func addLeftPanelViewController() {
    guard leftViewController == nil, let viewController = UIStoryboard.leftViewController() else { return }
    viewController.animals = Animal.allCats()
    addChildSidePanelController(viewController)
    leftViewController = viewController
  }
  
  private func addChildSidePanelController(_ viewController: SidePanelViewController) {
    viewController.delegate = centerViewController
    view.insertSubview(viewController.view, at: 0)
    
    addChildViewController(viewController)
    viewController.didMove(toParentViewController: self)
  }
  
  func addRightPanelViewController() {
    guard rightViewController == nil, let viewController = UIStoryboard.rightViewController() else { return }
    viewController.animals = Animal.allDogs()
    addChildSidePanelController(viewController)
    rightViewController = viewController
  }
  
  private func animateLeftPanel(shouldExpand: Bool) {
    if shouldExpand {
      currentState = .leftPanelCollapsed
      animateCenterPanelXPosition(targetPosition: centerNavigationController.view.frame.width - centerPanelExpandOffset)
      
    } else {
      animateCenterPanelXPosition(targetPosition: 0) { [weak self] finished in
        guard let sself = self else {return}
        sself.currentState = .both
        sself.leftViewController?.view.removeFromSuperview()
        sself.leftViewController = nil
      }
    }
  }
  
  private func animateCenterPanelXPosition(targetPosition: CGFloat, completion: ((Bool)->())? = nil) {
    let animation: ()->() = {[weak self] in
      self?.centerNavigationController.view.frame.origin.x = targetPosition
    }
    UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: animation, completion: completion)
  }
  
  private func shadowForCenterViewController(_ shouldShowShadow: Bool) {
    centerNavigationController.view.layer.shadowOpacity = shouldShowShadow ? 0.8 : 0
  }
  
  func animateRightPanel(shouldExpand: Bool) {
    if shouldExpand {
      currentState = .rightPanelCollapsed
      animateCenterPanelXPosition(targetPosition: -centerNavigationController.view.frame.width + centerPanelExpandOffset)
      
    } else {
      animateCenterPanelXPosition(targetPosition: 0) { [weak self] finished in
        guard let sself = self else {return}
        sself.currentState = .both
        sself.rightViewController?.view.removeFromSuperview()
        sself.rightViewController = nil
      }
    }
  }
}

private extension UIStoryboard {
  
  static func mainStoryboard() -> UIStoryboard { return UIStoryboard(name: "Main", bundle: Bundle.main) }
  
  static func leftViewController() -> SidePanelViewController? {
    return mainStoryboard().instantiateViewController(withIdentifier: "LeftViewController") as? SidePanelViewController
  }
  
  static func rightViewController() -> SidePanelViewController? {
    return mainStoryboard().instantiateViewController(withIdentifier: "RightViewController") as? SidePanelViewController
  }
  
  static func centerViewController() -> CenterViewController? {
    return mainStoryboard().instantiateViewController(withIdentifier: "CenterViewController") as? CenterViewController
  }
}
