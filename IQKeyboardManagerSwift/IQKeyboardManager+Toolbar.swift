//
//  IQKeyboardManager+Toolbar.swift
// https://github.com/hackiftekhar/IQKeyboardManager
// Copyright (c) 2013-20 Iftekhar Qurashi.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

// import Foundation - UIKit contains Foundation
import UIKit

extension IQKeyboardManager {

    /**
    Default tag for toolbar with Done button   -1002.
    */
    private static let  kIQDoneButtonToolbarTag         =   -1002

    /**
    Default tag for toolbar with Previous/Next buttons -1005.
    */
    private static let  kIQPreviousNextButtonToolbarTag =   -1005

    /** Add toolbar if it is required to add on textFields and it's siblings. */
    func addToolbarIfRequired() {

        //Either there is no inputAccessoryView or if accessoryView is not appropriate for current situation(There is Previous/Next/Done toolbar).
        guard let siblings = responderViews(), !siblings.isEmpty,
              let textField = textFieldView, textField.responds(to: #selector(setter: UITextField.inputAccessoryView)),
              (textField.inputAccessoryView == nil ||
                textField.inputAccessoryView?.tag == IQKeyboardManager.kIQPreviousNextButtonToolbarTag ||
                textField.inputAccessoryView?.tag == IQKeyboardManager.kIQDoneButtonToolbarTag) else {
            return
        }

        let startTime = CACurrentMediaTime()
        showLog("****** \(#function) started ******", indentation: 1)

        showLog("Found \(siblings.count) responder sibling(s)")

        let rightConfiguration: IQBarButtonItem.Configuration

        if let doneBarButtonItemImage = toolbarDoneBarButtonItemImage {
            rightConfiguration = IQBarButtonItem.Configuration(image: doneBarButtonItemImage, target: self, action: #selector(self.doneAction(_:)))
        } else if let doneBarButtonItemText = toolbarDoneBarButtonItemText {
            rightConfiguration = IQBarButtonItem.Configuration(title: doneBarButtonItemText, target: self, action: #selector(self.doneAction(_:)))
        } else {
            rightConfiguration = IQBarButtonItem.Configuration(systemItem: .done, target: self, action: #selector(self.doneAction(_:)))
        }
        rightConfiguration.accessibilityLabel = toolbarDoneBarButtonItemAccessibilityLabel ?? "Done"

        //    If only one object is found, then adding only Done button.
        if (siblings.count <= 1 && previousNextDisplayMode == .default) || previousNextDisplayMode == .alwaysHide {

            textField.addKeyboardToolbar(titleText: (shouldShowToolbarPlaceholder ? textField.drawingToolbarPlaceholder: nil), rightBarButtonConfiguration: rightConfiguration, previousBarButtonConfiguration: nil, nextBarButtonConfiguration: nil)

            textField.inputAccessoryView?.tag = IQKeyboardManager.kIQDoneButtonToolbarTag //  (Bug ID: #78)

        } else if previousNextDisplayMode == .default || previousNextDisplayMode == .alwaysShow {

            let prevConfiguration: IQBarButtonItem.Configuration

            if let doneBarButtonItemImage = toolbarPreviousBarButtonItemImage {
                prevConfiguration = IQBarButtonItem.Configuration(image: doneBarButtonItemImage, target: self, action: #selector(self.previousAction(_:)))
            } else if let doneBarButtonItemText = toolbarPreviousBarButtonItemText {
                prevConfiguration = IQBarButtonItem.Configuration(title: doneBarButtonItemText, target: self, action: #selector(self.previousAction(_:)))
            } else {
                prevConfiguration = IQBarButtonItem.Configuration(image: UIImage.keyboardPreviousImage(), target: self, action: #selector(self.previousAction(_:)))
            }
            prevConfiguration.accessibilityLabel = toolbarPreviousBarButtonItemAccessibilityLabel ?? "Previous"

            let nextConfiguration: IQBarButtonItem.Configuration

            if let doneBarButtonItemImage = toolbarNextBarButtonItemImage {
                nextConfiguration = IQBarButtonItem.Configuration(image: doneBarButtonItemImage, target: self, action: #selector(self.nextAction(_:)))
            } else if let doneBarButtonItemText = toolbarNextBarButtonItemText {
                nextConfiguration = IQBarButtonItem.Configuration(title: doneBarButtonItemText, target: self, action: #selector(self.nextAction(_:)))
            } else {
                nextConfiguration = IQBarButtonItem.Configuration(image: UIImage.keyboardNextImage(), target: self, action: #selector(self.nextAction(_:)))
            }
            nextConfiguration.accessibilityLabel = toolbarNextBarButtonItemAccessibilityLabel ?? "Next"

            textField.addKeyboardToolbar(titleText: (shouldShowToolbarPlaceholder ? textField.drawingToolbarPlaceholder: nil), rightBarButtonConfiguration: rightConfiguration, previousBarButtonConfiguration: prevConfiguration, nextBarButtonConfiguration: nextConfiguration)

            textField.inputAccessoryView?.tag = IQKeyboardManager.kIQPreviousNextButtonToolbarTag //  (Bug ID: #78)
        }

        let toolbar = textField.keyboardToolbar

        //Setting toolbar tintColor //  (Enhancement ID: #30)
        toolbar.tintColor = shouldToolbarUsesTextFieldTintColor ? textField.tintColor : toolbarTintColor

        //  Setting toolbar to keyboard.
        //Bar style according to keyboard appearance
        if let keyboardAppearance = textField.keyboardAppearance, keyboardAppearance == .dark {
            toolbar.barStyle = .black
            toolbar.barTintColor = nil
        } else {
            toolbar.barStyle = .default
            toolbar.barTintColor = toolbarBarTintColor
        }

        //Setting toolbar title font.   //  (Enhancement ID: #30)
        if shouldShowToolbarPlaceholder, !textField.shouldHideToolbarPlaceholder {

            //Updating placeholder font to toolbar.     //(Bug ID: #148, #272)
            if toolbar.titleBarButton.title == nil ||
                toolbar.titleBarButton.title != textField.drawingToolbarPlaceholder {
                toolbar.titleBarButton.title = textField.drawingToolbarPlaceholder
            }

            //Setting toolbar title font.   //  (Enhancement ID: #30)
            toolbar.titleBarButton.titleFont = placeholderFont

            //Setting toolbar title color.   //  (Enhancement ID: #880)
            toolbar.titleBarButton.titleColor = placeholderColor

            //Setting toolbar button title color.   //  (Enhancement ID: #880)
            toolbar.titleBarButton.selectableTitleColor = placeholderButtonColor

        } else {
            toolbar.titleBarButton.title = nil
        }

        //In case of UITableView (Special), the next/previous buttons has to be refreshed everytime.    (Bug ID: #56)

        textField.keyboardToolbar.previousBarButton.isEnabled = (siblings.first !== textField)   //    If firstTextField, then previous should not be enabled.
        textField.keyboardToolbar.nextBarButton.isEnabled = (siblings.last !== textField)        //    If lastTextField then next should not be enaled.

        let elapsedTime = CACurrentMediaTime() - startTime
        showLog("****** \(#function) ended: \(elapsedTime) seconds ******", indentation: -1)
    }

    /** Remove any toolbar if it is IQToolbar. */
    func removeToolbarIfRequired() {    //  (Bug ID: #18)

        guard let siblings = responderViews(), !siblings.isEmpty,
              let textField = textFieldView, textField.responds(to: #selector(setter: UITextField.inputAccessoryView)),
              (textField.inputAccessoryView == nil ||
                textField.inputAccessoryView?.tag == IQKeyboardManager.kIQPreviousNextButtonToolbarTag ||
                textField.inputAccessoryView?.tag == IQKeyboardManager.kIQDoneButtonToolbarTag) else {
            return
        }

        let startTime = CACurrentMediaTime()
        showLog("****** \(#function) started ******", indentation: 1)

        showLog("Found \(siblings.count) responder sibling(s)")
        
        for view in siblings {
            if let toolbar = view.inputAccessoryView as? IQToolbar {

                //setInputAccessoryView: check   (Bug ID: #307)
                if view.responds(to: #selector(setter: UITextField.inputAccessoryView)),
                    (toolbar.tag == IQKeyboardManager.kIQDoneButtonToolbarTag || toolbar.tag == IQKeyboardManager.kIQPreviousNextButtonToolbarTag) {

                    if let textField = view as? UITextField {
                        textField.inputAccessoryView = nil
                    } else if let textView = view as? UITextView {
                        textView.inputAccessoryView = nil
                    }

                    view.reloadInputViews()
                }
            }
        }

        let elapsedTime = CACurrentMediaTime() - startTime
        showLog("****** \(#function) ended: \(elapsedTime) seconds ******", indentation: -1)
    }

    /**    reloadInputViews to reload toolbar buttons enable/disable state on the fly Enhancement ID #434. */
    public func reloadInputViews() {

        //If enabled then adding toolbar.
        if privateIsEnableAutoToolbar() {
            self.addToolbarIfRequired()
        } else {
            self.removeToolbarIfRequired()
        }
    }
}

// MARK: Previous next button actions
public extension IQKeyboardManager {

    /**
    Returns YES if can navigate to previous responder textField/textView, otherwise NO.
    */
    var canGoPrevious: Bool {
        //If it is not first textField. then it's previous object canBecomeFirstResponder.
        if let textInputViews = responderViews(), let textInputView = textFieldView, let index = firstIndex(of: textInputView, in: textInputViews), index > 0 {
            return true
        }
        return false
    }

    /**
    Returns YES if can navigate to next responder textField/textView, otherwise NO.
    */
    var canGoNext: Bool {
        //If it is not first textField. then it's previous object canBecomeFirstResponder.
        if let textInputViews = responderViews(), let textInputView = textFieldView, let index = firstIndex(of: textInputView, in: textInputViews), index < textInputViews.count-1 {
            return true
        }
        return false
    }

    /**
    Navigate to previous responder textField/textView.
    */
    @discardableResult
    func goPrevious() -> Bool {

        //If it is not first textField. then it's previous object becomeFirstResponder.
        guard let textInputViews = responderViews(), let textInputView = textFieldView, let index = firstIndex(of: textInputView, in: textInputViews), index > 0 else {
            return false
        }

        let nextTextInputView = textInputViews[index-1]

        let isAcceptAsFirstResponder = nextTextInputView.becomeFirstResponder()

        //  If it refuses then becoming previous textFieldView as first responder again.    (Bug ID: #96)
        if !isAcceptAsFirstResponder {
            //If next field refuses to become first responder then restoring old textField as first responder.
            textInputView.becomeFirstResponder()

            showLog("Refuses to become first responder: \(nextTextInputView)")
        }

        return isAcceptAsFirstResponder    }

    /**
    Navigate to next responder textField/textView.
    */
    @discardableResult func goNext() -> Bool {

        //If it is not first textField. then it's previous object becomeFirstResponder.
        guard let textInputViews = responderViews(), let textInputView = textFieldView, let index = firstIndex(of: textInputView, in: textInputViews), index < textInputViews.count-1 else {
            return false
        }

        let nextTextInputView = textInputViews[index+1]

        let isAcceptAsFirstResponder = nextTextInputView.becomeFirstResponder()

        //  If it refuses then becoming previous textFieldView as first responder again.    (Bug ID: #96)
        if !isAcceptAsFirstResponder {
            //If next field refuses to become first responder then restoring old textField as first responder.
            textInputView.becomeFirstResponder()

            showLog("Refuses to become first responder: \(nextTextInputView)")
        }

        return isAcceptAsFirstResponder
    }

    /**    previousAction. */
    @objc func previousAction (_ barButton: IQBarButtonItem) {

        //If user wants to play input Click sound.
        if shouldPlayInputClicks {
            //Play Input Click Sound.
            UIDevice.current.playInputClick()
        }

        guard canGoPrevious, let textInputView = textFieldView else {
            return
        }

        let isAcceptAsFirstResponder = goPrevious()

        var invocation = barButton.invocation
        var sender = textInputView

        //Handling search bar special case
        if let textField = textInputView as? UITextField, let searchBar = textField.textFieldSearchBar() {
            invocation = searchBar.keyboardToolbar.previousBarButton.invocation
            sender = searchBar
        }

        if isAcceptAsFirstResponder {
            invocation?.invoke(from: sender)
        }
    }

    /**    nextAction. */
    @objc func nextAction (_ barButton: IQBarButtonItem) {

        //If user wants to play input Click sound.
        if shouldPlayInputClicks {
            //Play Input Click Sound.
            UIDevice.current.playInputClick()
        }

        guard canGoNext, let textInputView = textFieldView else {
            return
        }

        let isAcceptAsFirstResponder = goNext()

        var invocation = barButton.invocation
        var sender = textInputView

        //Handling search bar special case
        if let textField = textInputView as? UITextField, let searchBar = textField.textFieldSearchBar() {
            invocation = searchBar.keyboardToolbar.nextBarButton.invocation
            sender = searchBar
        }

        if isAcceptAsFirstResponder {
            invocation?.invoke(from: sender)
        }
    }

    /**    doneAction. Resigning current textField. */
    @objc func doneAction (_ barButton: IQBarButtonItem) {

        //If user wants to play input Click sound.
        if shouldPlayInputClicks {
            //Play Input Click Sound.
            UIDevice.current.playInputClick()
        }

        guard let textInputView = textFieldView else {
            return
        }

        //Resign textFieldView.
        let isResignedFirstResponder = resignFirstResponder()

        var invocation = barButton.invocation
        var sender = textInputView

        //Handling search bar special case
        if let textField = textInputView as? UITextField, let searchBar = textField.textFieldSearchBar() {
            invocation = searchBar.keyboardToolbar.doneBarButton.invocation
            sender = searchBar
        }

        if isResignedFirstResponder {
            invocation?.invoke(from: sender)
        }
    }
}
