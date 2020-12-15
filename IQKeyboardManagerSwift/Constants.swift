//
//  Constants.swift
//  IQKeyboardManagerSwift
//
//  Created by Sereivoan Yong on 12/15/20.
//

import UIKit

public enum IQAutoToolbarManageBehaviour: Int {

    /// Creates Toolbar according to subview's hirarchy of Textfield's in view.
    case bySubviews

    /// Creates Toolbar according to tag property of TextField's.
    case byTag

    /// Creates Toolbar according to the y,x position of textField in it's superview coordinate.
    case byPosition
}

extension Array where Element: UIView {

    func sorted(by behaviour: IQAutoToolbarManageBehaviour) -> [Element] {
        switch behaviour {
        case .bySubviews:
            return self
        case .byTag:
            return sorted {  $0.tag < $1.tag }
        case .byPosition:
            return sorted {
                if $0.frame.minY != $1.frame.minY {
                    return $0.frame.minY < $1.frame.minY
                } else {
                    return $0.frame.minX < $1.frame.minX
                }
            }
        }
    }
}

public enum IQPreviousNextDisplayMode {

    /// Show NextPrevious when there are more than 1 textField otherwise hide.
    case `default`

    /// Do not show NextPrevious buttons in any case.
    case alwaysHide

    /// Always show nextPrevious buttons, if there are more than 1 textField then both buttons will be visible but will be shown as disabled.
    case alwaysShow
}

public enum IQEnableMode {

    case enabled
    case disabled
}

/*
 /---------------------------------------------------------------------------------------------------\
 \---------------------------------------------------------------------------------------------------/
 |                                   iOS Notification Mechanism                                    |
 /---------------------------------------------------------------------------------------------------\
 \---------------------------------------------------------------------------------------------------/
 
 ------------------------------------------------------------
 When UITextField become first responder
 ------------------------------------------------------------
 - UITextFieldTextDidBeginEditingNotification (UITextField)
 - UIKeyboardWillShowNotification
 - UIKeyboardDidShowNotification
 
 ------------------------------------------------------------
 When UITextView become first responder
 ------------------------------------------------------------
 - UIKeyboardWillShowNotification
 - UITextViewTextDidBeginEditingNotification (UITextView)
 - UIKeyboardDidShowNotification
 
 ------------------------------------------------------------
 When switching focus from UITextField to another UITextField
 ------------------------------------------------------------
 - UITextFieldTextDidEndEditingNotification (UITextField1)
 - UITextFieldTextDidBeginEditingNotification (UITextField2)
 - UIKeyboardWillShowNotification
 - UIKeyboardDidShowNotification
 
 ------------------------------------------------------------
 When switching focus from UITextView to another UITextView
 ------------------------------------------------------------
 - UITextViewTextDidEndEditingNotification: (UITextView1)
 - UIKeyboardWillShowNotification
 - UITextViewTextDidBeginEditingNotification: (UITextView2)
 - UIKeyboardDidShowNotification
 
 ------------------------------------------------------------
 When switching focus from UITextField to UITextView
 ------------------------------------------------------------
 - UITextFieldTextDidEndEditingNotification (UITextField)
 - UIKeyboardWillShowNotification
 - UITextViewTextDidBeginEditingNotification (UITextView)
 - UIKeyboardDidShowNotification
 
 ------------------------------------------------------------
 When switching focus from UITextView to UITextField
 ------------------------------------------------------------
 - UITextViewTextDidEndEditingNotification (UITextView)
 - UITextFieldTextDidBeginEditingNotification (UITextField)
 - UIKeyboardWillShowNotification
 - UIKeyboardDidShowNotification
 
 ------------------------------------------------------------
 When opening/closing UIKeyboard Predictive bar
 ------------------------------------------------------------
 - UIKeyboardWillShowNotification
 - UIKeyboardDidShowNotification
 
 ------------------------------------------------------------
 On orientation change
 ------------------------------------------------------------
 - UIApplicationWillChangeStatusBarOrientationNotification
 - UIKeyboardWillHideNotification
 - UIKeyboardDidHideNotification
 - UIApplicationDidChangeStatusBarOrientationNotification
 - UIKeyboardWillShowNotification
 - UIKeyboardDidShowNotification
 - UIKeyboardWillShowNotification
 - UIKeyboardDidShowNotification
 
 */
