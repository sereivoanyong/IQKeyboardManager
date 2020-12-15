//
//  UIView+Hierarchy.swift
//  IQKeyboardManagerSwift
//
//  Created by Sereivoan Yong on 12/15/20.
//

import UIKit

extension UIView {

    // MARK: viewControllers

    /// Returns the UIViewController object that manages the receiver.
    final var containingViewController: UIViewController? {
        if let next = next {
            if let viewController = next as? UIViewController {
                return viewController
            }
            if let view = next as? UIView {
                return view.containingViewController
            }
        }
        return nil
    }

    /// Returns the UIViewController object that is actually the parent of this object. Most of the time it's the viewController object which actually contains it, but result may be different if it's viewController is added as childViewController of another viewController.
    final func parentContainerViewController() -> UIViewController? {
        guard var target = containingViewController else {
            return nil
        }

        if var navigationController = target.navigationController {
            while let parent = navigationController.navigationController {
                navigationController = parent
            }

            var parent: UIViewController = navigationController

            while let currentParent = parent.parent,
                  !(currentParent is UINavigationController) && !(currentParent is UITabBarController) && !(currentParent is UISplitViewController) {
                parent = currentParent
            }

            if navigationController == parent {
                return navigationController.topViewController
            } else {
                return parent
            }

        } else if let tabBarController = target.tabBarController {

            if let navigationController = tabBarController.selectedViewController as? UINavigationController {
                return navigationController.topViewController
            } else {
                return tabBarController.selectedViewController
            }

        } else {
            while let parentController = target.parent,
                  !(parentController is UINavigationController) && !(parentController is UITabBarController) && !(parentController is UISplitViewController) {
                target = parentController
            }

            return target
        }
    }

    // MARK: Superviews/Subviews/Siblings

    /// Returns the superView of provided class type.
    /// - Parameters:
    ///   - classType: class type of the object which is to be search in above hierarchy and return.
    ///   - belowView: view object in upper hierarchy where method should stop searching and return nil.
    final func superview<T: UIView>(of type: T.Type, belowView: UIView? = nil) -> T? {
        if let superview = superview {
            if let superview = superview as? T {

                //If it's UIScrollView, then validating for special cases
                if superview is UIScrollView {

                    let classNameString = NSStringFromClass(Swift.type(of: superview))

                    //  If it's not UITableViewWrapperView class, this is internal class which is actually manage in UITableview. The speciality of this class is that it's superview is UITableView.
                    //  If it's not UITableViewCellScrollView class, this is internal class which is actually manage in UITableviewCell. The speciality of this class is that it's superview is UITableViewCell.
                    //If it's not _UIQueuingScrollView class, actually we validate for _ prefix which usually used by Apple internal classes
                    if superview.superview?.isKind(of: UITableView.self) == false,
                       superview.superview?.isKind(of: UITableViewCell.self) == false,
                       !classNameString.hasPrefix("_") {
                        return superview
                    }
                } else {
                    return superview
                }
            } else if superview == belowView {
                return nil
            }

            return superview.superview(of: type, belowView: belowView)
        }
        return nil
    }

    /// Returns all siblings of the receiver which canBecomeFirstResponder.
    final func responderSiblings() -> [TextInputView] {

        //Array of (UITextField/UITextView's).
        var textInputViews: [TextInputView] = []

        //	Getting all siblings
        if let superview = superview {
            for subview in superview.subviews {
                if let textInputView = subview as? TextInputView, textInputView.IQcanBecomeFirstResponder() {
                    if textInputView == self || !textInputView.ignoreSwitchingByNextPrevious {
                        textInputViews.append(textInputView)
                    }
                }
            }
        }

        return textInputViews
    }

    /// Returns all deep subViews of the receiver which canBecomeFirstResponder.
    final func deepResponderViews() -> [TextInputView] {

        //Array of (UITextField/UITextView's).
        var textInputViews = [TextInputView]()

        for subview in subviews {
            if let textInputView = subview as? TextInputView, textInputView.IQcanBecomeFirstResponder() {
                if textInputView == self || !textInputView.ignoreSwitchingByNextPrevious {
                    textInputViews.append(textInputView)
                }
            }
            //Sometimes there are hidden or disabled views and textField inside them still recorded, so we added some more validations here (Bug ID: #458)
            //Uncommented else (Bug ID: #625)
            else if subview.subviews.count != 0, isUserInteractionEnabled, !isHidden, alpha != 0.0 {
                for deepView in subview.deepResponderViews() {
                    textInputViews.append(deepView)
                }
            }
        }

        //subviews are returning in opposite order. Sorting according the frames 'y'.
        return textInputViews.sorted(by: { view1, view2 in

            let frame1 = view1.convert(view1.bounds, to: self)
            let frame2 = view2.convert(view2.bounds, to: self)

            if frame1.minY != frame2.minY {
                return frame1.minY < frame2.minY
            } else {
                return frame1.minX < frame2.minX
            }
        })
    }

    // MARK: Special TextFields

    /// Returns YES if the receiver object is UIAlertSheetTextField, otherwise return NO.
    final func isAlertViewTextField() -> Bool {
        var responder: UIResponder? = containingViewController
        while let currentResponder = responder {
            if currentResponder is UIAlertController {
                return true
            }
            responder = currentResponder.next
        }
        return false
    }
}

extension UITextField {

    /// Returns searchBar if receiver object is UISearchBarTextField, otherwise return nil.
    final func textFieldSearchBar() -> UISearchBar? {
        var responder = next
        if let currentResponder = responder {
            if let searchBar = currentResponder as? UISearchBar {
                return searchBar
            }
            if currentResponder is UIViewController {
                return nil
            }
            responder = currentResponder.next
        }
        return nil
    }
}
