//
//  UITextInputTraits+IQ.swift
//  IQKeyboardManagerSwift
//
//  Created by Sereivoan Yong on 12/15/20.
//

import UIKit

private var kKeyboardDistanceFromTextFieldKey: Void?
private var kIgnoreSwitchingByNextPreviousKey: Void?
private var kEnableModeKey: Void?
private var kShouldResignOnTouchOutsideModeKey: Void?

extension UITextInputTraits where Self: UIView {

    func IQcanBecomeFirstResponder() -> Bool {

        var IQcanBecomeFirstResponder = false

        //  Setting toolbar to keyboard.
        if let textView = self as? UITextView {
            IQcanBecomeFirstResponder = textView.isEditable
        } else if let textField = self as? UITextField {
            IQcanBecomeFirstResponder = textField.isEnabled && textField.textFieldSearchBar() == nil
        }

        if IQcanBecomeFirstResponder {
            IQcanBecomeFirstResponder = isUserInteractionEnabled && !isHidden && alpha != 0.0 && !isAlertViewTextField()
        }

        return IQcanBecomeFirstResponder
    }

    /// To set customized distance from keyboard for textField/textView. Can't be less than zero
    public var keyboardDistanceFromTextField: CGFloat? {
        get { return objc_getAssociatedValue(self, &kKeyboardDistanceFromTextFieldKey) }
        set { objc_setAssociatedValue(self, &kKeyboardDistanceFromTextFieldKey, newValue) }
    }

    /// If shouldIgnoreSwitchingByNextPrevious is true then library will ignore this textField/textView while moving to other textField/textView using keyboard toolbar next previous buttons. Default is false
    public var ignoreSwitchingByNextPrevious: Bool {
        get { return objc_getAssociatedValue(self, &kIgnoreSwitchingByNextPreviousKey) ?? false }
        set { objc_setAssociatedValue(self, &kIgnoreSwitchingByNextPreviousKey, newValue) }
    }

    /// Override Enable/disable managing distance between keyboard and textField behaviour for this particular textField.
    public var enableMode: IQEnableMode? {
        get { return objc_getAssociatedValue(self, &kEnableModeKey) }
        set { objc_setAssociatedValue(self, &kEnableModeKey, newValue) }
    }

    /// Override resigns Keyboard on touching outside of UITextField/View behaviour for this particular textField.
    public var shouldResignOnTouchOutsideMode: IQEnableMode? {
        get { return objc_getAssociatedValue(self, &kShouldResignOnTouchOutsideModeKey) }
        set { objc_setAssociatedValue(self, &kShouldResignOnTouchOutsideModeKey, newValue) }
    }
}
