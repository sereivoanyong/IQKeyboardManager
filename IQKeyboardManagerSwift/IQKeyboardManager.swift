//
//  IQKeyboardManager.swift
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
import CoreGraphics
import QuartzCore

// MARK: IQToolbar tags

/**
Codeless drop-in universal library allows to prevent issues of keyboard sliding up and cover UITextField/UITextView. Neither need to write any code nor any setup required and much more. A generic version of KeyboardManagement. https://developer.apple.com/library/ios/documentation/StringsTextFonts/Conceptual/TextAndWebiPhoneOS/KeyboardManagement/KeyboardManagement.html
*/

final public class IQKeyboardManager: NSObject {

    /** To save UITextField/UITextView object voa textField/textView notifications. */
    weak var textFieldView: UIView?

    var topViewBeginOrigin: CGPoint = IQKeyboardManager.kIQCGPointInvalid

    /** To save rootViewController */
    weak var rootViewController: UIViewController?

    /** To overcome with popGestureRecognizer issue Bug ID: #1361 */
    weak var rootViewControllerWhilePopGestureRecognizerActive: UIViewController?

    var topViewBeginOriginWhilePopGestureRecognizerActive: CGPoint = IQKeyboardManager.kIQCGPointInvalid

    /**
     Boolean to know if keyboard is showing.
     */
    private(set) var keyboardShowing: Bool = false

    /** To save keyboardWillShowNotification. Needed for enable keyboard functionality. */
    var keyboardShowNotification: Notification?

    /** To save keyboard rame. */
    var keyboardFrame: CGRect = .zero

    /** To save keyboard animation duration. */
    var animationDuration: TimeInterval = 0.25

    /** To mimic the keyboard animation */
    var animationCurve: UIView.AnimationOptions = .curveEaseOut

    /**
     moved distance to the top used to maintain distance between keyboard and textField. Most of the time this will be a positive value.
     */
    private(set) var movedDistance: CGFloat = 0

    /**
    Will be called then movedDistance will be changed
     */
    var movedDistanceChanged: ((CGFloat) -> Void)?

    /** Variable to save lastScrollView that was scrolled. */
    weak var lastScrollView: UIScrollView?

    /** LastScrollView's initial contentOffset. */
    var startingContentOffset: CGPoint = IQKeyboardManager.kIQCGPointInvalid

    /** LastScrollView's initial scrollIndicatorInsets. */
    var startingScrollIndicatorInsets: UIEdgeInsets = .zero

    /** LastScrollView's initial contentInsets. */
    var startingContentInsets: UIEdgeInsets = .zero

    /** used to adjust contentInset of UITextView. */
    var startingTextViewContentInsets: UIEdgeInsets = .zero

    /** used to adjust scrollIndicatorInsets of UITextView. */
    var startingTextViewScrollIndicatorInsets: UIEdgeInsets = .zero

    /** used with textView to detect a textFieldView contentInset is changed or not. (Bug ID: #92)*/
    var isTextViewContentInsetChanged: Bool = false

    /** To know if we have any pending request to adjust view position. */
    private var hasPendingAdjustRequest: Bool = false

    /**
    Returns the default singleton instance.
    */
    public static let shared = IQKeyboardManager()

    /**
     Invalid point value.
     */
    static let  kIQCGPointInvalid = CGPoint.init(x: CGFloat.greatestFiniteMagnitude, y: CGFloat.greatestFiniteMagnitude)

    // MARK: UIKeyboard handling

    /**
    Enable/disable managing distance between keyboard and textField. Default is YES(Enabled when class loads in `+(void)load` method).
    */
    public var enable = false {

        didSet {
            //If not enable, enable it.
            if enable, !oldValue {
                //If keyboard is currently showing. Sending a fake notification for keyboardWillHide to retain view's original position.
                if let notification = keyboardShowNotification {
                    keyboardWillShow(notification)
                }
                showLog("Enabled")
            } else if !enable, oldValue {   //If not disable, desable it.
                keyboardWillHide(nil)
                showLog("Disabled")
            }
        }
    }

    /**
    To set keyboard distance from textField. can't be less than zero. Default is 10.0.
    */
    public var keyboardDistanceFromTextField: CGFloat = 10.0

    // MARK: IQToolbar handling

    /**
    Automatic add the IQToolbar functionality. Default is YES.
    */
    public var enableAutoToolbar = true {
        didSet {
            privateIsEnableAutoToolbar() ? addToolbarIfRequired() : removeToolbarIfRequired()

            let enableToolbar = enableAutoToolbar ? "Yes" : "NO"

            showLog("enableAutoToolbar: \(enableToolbar)")
        }
    }

    /**
     /**
     IQAutoToolbarBySubviews:   Creates Toolbar according to subview's hirarchy of Textfield's in view.
     IQAutoToolbarByTag:        Creates Toolbar according to tag property of TextField's.
     IQAutoToolbarByPosition:   Creates Toolbar according to the y,x position of textField in it's superview coordinate.

     Default is IQAutoToolbarBySubviews.
     */
    AutoToolbar managing behaviour. Default is IQAutoToolbarBySubviews.
    */
    public var toolbarManageBehaviour = IQAutoToolbarManageBehaviour.bySubviews

    /**
    If YES, then uses textField's tintColor property for IQToolbar, otherwise tint color is default. Default is NO.
    */
    public var shouldToolbarUsesTextFieldTintColor = false

    /**
    This is used for toolbar.tintColor when textfield.keyboardAppearance is UIKeyboardAppearanceDefault. If shouldToolbarUsesTextFieldTintColor is YES then this property is ignored. Default is nil and uses black color.
    */
    public var toolbarTintColor: UIColor?

    /**
     This is used for toolbar.barTintColor. Default is nil.
     */
    public var toolbarBarTintColor: UIColor?

    /**
     IQPreviousNextDisplayModeDefault:      Show NextPrevious when there are more than 1 textField otherwise hide.
     IQPreviousNextDisplayModeAlwaysHide:   Do not show NextPrevious buttons in any case.
     IQPreviousNextDisplayModeAlwaysShow:   Always show nextPrevious buttons, if there are more than 1 textField then both buttons will be visible but will be shown as disabled.
     */
    public var previousNextDisplayMode = IQPreviousNextDisplayMode.default

    /**
     Toolbar previous/next/done button icon, If nothing is provided then check toolbarDoneBarButtonItemText to draw done button.
     */
    public var toolbarPreviousBarButtonItemImage: UIImage?
    public var toolbarNextBarButtonItemImage: UIImage?
    public var toolbarDoneBarButtonItemImage: UIImage?

    /**
     Toolbar previous/next/done button text, If nothing is provided then system default 'UIBarButtonSystemItemDone' will be used.
     */
    public var toolbarPreviousBarButtonItemText: String?
    public var toolbarPreviousBarButtonItemAccessibilityLabel: String?
    public var toolbarNextBarButtonItemText: String?
    public var toolbarNextBarButtonItemAccessibilityLabel: String?
    public var toolbarDoneBarButtonItemText: String?
    public var toolbarDoneBarButtonItemAccessibilityLabel: String?

    /**
    If YES, then it add the textField's placeholder text on IQToolbar. Default is YES.
    */
    public var shouldShowToolbarPlaceholder = true

    /**
    Placeholder Font. Default is nil.
    */
    public var placeholderFont: UIFont?

    /**
     Placeholder Color. Default is nil. Which means lightGray
     */
    public var placeholderColor: UIColor?

    /**
     Placeholder Button Color when it's treated as button. Default is nil.
     */
    public var placeholderButtonColor: UIColor?

    // MARK: UIKeyboard appearance overriding

    /**
    Override the keyboardAppearance for all textField/textView. Default is NO.
    */
    public var overrideKeyboardAppearance = false

    /**
    If overrideKeyboardAppearance is YES, then all the textField keyboardAppearance is set using this property.
    */
    public var keyboardAppearance = UIKeyboardAppearance.default

    // MARK: UITextField/UITextView Next/Previous/Resign handling

    /**
    Resigns Keyboard on touching outside of UITextField/View. Default is NO.
    */
    public var shouldResignOnTouchOutside = false {

        didSet {
            resignFirstResponderGesture.isEnabled = privateShouldResignOnTouchOutside()

            let shouldResign = shouldResignOnTouchOutside ? "Yes" : "NO"

            showLog("shouldResignOnTouchOutside: \(shouldResign)")
        }
    }

    /** TapGesture to resign keyboard on view's touch. It's a readonly property and exposed only for adding/removing dependencies if your added gesture does have collision with this one */
    lazy public var resignFirstResponderGesture: UITapGestureRecognizer = {

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.tapRecognized(_:)))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self

        return tapGesture
    }()

    /*******************************************/

    /**
    Resigns currently first responder field.
    */
    @discardableResult public func resignFirstResponder() -> Bool {

        guard let textFieldRetain = textFieldView else {
            return false
        }

        //Resigning first responder
        guard textFieldRetain.resignFirstResponder() else {
            showLog("Refuses to resign first responder: \(textFieldRetain)")
            //  If it refuses then becoming it as first responder again.    (Bug ID: #96)
            //If it refuses to resign then becoming it first responder again for getting notifications callback.
            textFieldRetain.becomeFirstResponder()
            return false
        }
        return true
    }

    // MARK: UISound handling

    /**
    If YES, then it plays inputClick sound on next/previous/done click.
    */
    public var shouldPlayInputClicks = true

    // MARK: UIAnimation handling

    /**
    If YES, then calls 'setNeedsLayout' and 'layoutIfNeeded' on any frame update of to viewController's view.
    */
    public var layoutIfNeededOnUpdate = false

    // MARK: Class Level disabling methods

    /**
     Disable distance handling within the scope of disabled distance handling viewControllers classes. Within this scope, 'enabled' property is ignored. Class should be kind of UIViewController.
     */
    public var disabledDistanceHandlingClasses: [UIViewController.Type] = [UITableViewController.self, UIAlertController.self]

    /**
     Enable distance handling within the scope of enabled distance handling viewControllers classes. Within this scope, 'enabled' property is ignored. Class should be kind of UIViewController. If same Class is added in disabledDistanceHandlingClasses list, then enabledDistanceHandlingClasses will be ignored.
     */
    public var enabledDistanceHandlingClasses: [UIViewController.Type] = []

    /**
     Disable automatic toolbar creation within the scope of disabled toolbar viewControllers classes. Within this scope, 'enableAutoToolbar' property is ignored. Class should be kind of UIViewController.
     */
    public var disabledToolbarClasses: [UIViewController.Type] = [UIAlertController.self]

    /**
     Enable automatic toolbar creation within the scope of enabled toolbar viewControllers classes. Within this scope, 'enableAutoToolbar' property is ignored. Class should be kind of UIViewController. If same Class is added in disabledToolbarClasses list, then enabledToolbarClasses will be ignore.
     */
    public var enabledToolbarClasses: [UIViewController.Type] = []

    /**
     Allowed subclasses of UIView to add all inner textField, this will allow to navigate between textField contains in different superview. Class should be kind of UIView.
     */
    public var toolbarPreviousNextAllowedClasses: [UIView.Type] = [UITableView.self, UICollectionView.self, IQPreviousNextView.self]

    /**
     Disabled classes to ignore 'shouldResignOnTouchOutside' property, Class should be kind of UIViewController.
     */
    public var disabledTouchResignedClasses: [UIViewController.Type] = [UIAlertController.self]

    /**
     Enabled classes to forcefully enable 'shouldResignOnTouchOutsite' property. Class should be kind of UIViewController. If same Class is added in disabledTouchResignedClasses list, then enabledTouchResignedClasses will be ignored.
     */
    public var enabledTouchResignedClasses: [UIViewController.Type] = []

    /**
     if shouldResignOnTouchOutside is enabled then you can customise the behaviour to not recognise gesture touches on some specific view subclasses. Class should be kind of UIView. Default is [UIControl, UINavigationBar]
     */
    public var touchResignedGestureIgnoreClasses: [UIView.Type] = [UIControl.self, UINavigationBar.self]

    // MARK: Third Party Library support
    /// Add TextField/TextView Notifications customised Notifications. For example while using YYTextView https://github.com/ibireme/YYText

    /**
    Add/Remove customised Notification for third party customised TextField/TextView. Please be aware that the Notification object must be idential to UITextField/UITextView Notification objects and customised TextField/TextView support must be idential to UITextField/UITextView.
    @param didBeginEditingNotificationName This should be identical to UITextViewTextDidBeginEditingNotification
    @param didEndEditingNotificationName This should be identical to UITextViewTextDidEndEditingNotification
    */

    public func registerTextFieldViewClass(_ aClass: UIView.Type, didBeginEditingNotification: Notification.Name, didEndEditingNotification: Notification.Name) {

        NotificationCenter.default.addObserver(self, selector: #selector(self.textFieldViewDidBeginEditing(_:)), name: didBeginEditingNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.textFieldViewDidEndEditing(_:)), name: didEndEditingNotification, object: nil)
    }

    public func unregisterTextFieldViewClass(_ aClass: UIView.Type, didBeginEditingNotification: Notification.Name, didEndEditingNotification: Notification.Name) {

        NotificationCenter.default.removeObserver(self, name: didBeginEditingNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: didEndEditingNotification, object: nil)
    }

    /**************************************************************************************/

    // MARK: Initialization/Deinitialization

    /*  Singleton Object Initialization. */
    override init() {

        super.init()

        self.registerAllNotifications()

        //Creating gesture for @shouldResignOnTouchOutside. (Enhancement ID: #14)
        resignFirstResponderGesture.isEnabled = shouldResignOnTouchOutside

        //Loading IQToolbar, IQTitleBarButtonItem, IQBarButtonItem to fix first time keyboard appearance delay (Bug ID: #550)
        //If you experience exception breakpoint issue at below line then try these solutions https://stackoverflow.com/questions/27375640/all-exception-break-point-is-stopping-for-no-reason-on-simulator
        let textField = UITextField()
        textField.addDoneOnKeyboardWithTarget(nil, action: #selector(self.doneAction(_:)))
        textField.addPreviousNextDoneOnKeyboardWithTarget(nil, previousAction: #selector(self.previousAction(_:)), nextAction: #selector(self.nextAction(_:)), doneAction: #selector(self.doneAction(_:)))
    }

    deinit {
        //  Disable the keyboard manager.
        enable = false

        //Removing notification observers on dealloc.
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Position

    func optimizedAdjustPosition() {
        if !hasPendingAdjustRequest {
            hasPendingAdjustRequest = true
            OperationQueue.main.addOperation {
                self.adjustPosition()
                self.hasPendingAdjustRequest = false
            }
        }
    }

    /* Adjusting RootViewController's frame according to interface orientation. */
    private func adjustPosition() {

        //  We are unable to get textField object while keyboard showing on WKWebView's textField.  (Bug ID: #11)
        guard hasPendingAdjustRequest,
            let textFieldView = textFieldView,
            let rootController = textFieldView.parentContainerViewController(),
            let window = textFieldView.window,
            let textFieldViewRectInWindow = textFieldView.superview?.convert(textFieldView.frame, to: window),
            let textFieldViewRectInRootSuperview = textFieldView.superview?.convert(textFieldView.frame, to: rootController.view?.superview) else {
                return
        }

        let startTime = CACurrentMediaTime()
        showLog("****** \(#function) started ******", indentation: 1)

        //  Getting RootViewOrigin.
        var rootViewOrigin = rootController.view.frame.origin

        //Maintain keyboardDistanceFromTextField
        var specialKeyboardDistanceFromTextField = textFieldView.keyboardDistanceFromTextField

        if let searchBar = textFieldView.textFieldSearchBar() {
            specialKeyboardDistanceFromTextField = searchBar.keyboardDistanceFromTextField
        }

        let newKeyboardDistanceFromTextField = (specialKeyboardDistanceFromTextField == kIQUseDefaultKeyboardDistance) ? keyboardDistanceFromTextField : specialKeyboardDistanceFromTextField

        var kbSize = keyboardFrame.size

        do {
            var kbFrame = keyboardFrame

            kbFrame.origin.y -= newKeyboardDistanceFromTextField
            kbFrame.size.height += newKeyboardDistanceFromTextField

            //Calculating actual keyboard covered size respect to window, keyboard frame may be different when hardware keyboard is attached (Bug ID: #469) (Bug ID: #381) (Bug ID: #1506)
            let intersectRect = kbFrame.intersection(window.frame)

            if intersectRect.isNull {
                kbSize = CGSize(width: kbFrame.size.width, height: 0)
            } else {
                kbSize = intersectRect.size
            }
        }

        let statusBarHeight: CGFloat
        if #available(iOS 13, *) {
            statusBarHeight = window.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        } else {
            statusBarHeight = UIApplication.shared.statusBarFrame.height
        }

        let navigationBarAreaHeight: CGFloat = statusBarHeight + ( rootController.navigationController?.navigationBar.frame.height ?? 0)
        let layoutAreaHeight: CGFloat = rootController.view.layoutMargins.bottom

        let topLayoutGuide: CGFloat = max(navigationBarAreaHeight, layoutAreaHeight) + 5
        let bottomLayoutGuide: CGFloat = textFieldView is UITextView ? 0 : rootController.view.layoutMargins.bottom  //Validation of textView for case where there is a tab bar at the bottom or running on iPhone X and textView is at the bottom.

        //  Move positive = textField is hidden.
        //  Move negative = textField is showing.
        //  Calculating move position.
        var move: CGFloat = min(textFieldViewRectInRootSuperview.minY-(topLayoutGuide), textFieldViewRectInWindow.maxY-(window.frame.height-kbSize.height)+bottomLayoutGuide)

        showLog("Need to move: \(move)")

        var superScrollView: UIScrollView?
        var superView = textFieldView.superviewOfClassType(UIScrollView.self) as? UIScrollView

        //Getting UIScrollView whose scrolling is enabled.    //  (Bug ID: #285)
        while let view = superView {

            if view.isScrollEnabled, !view.shouldIgnoreScrollingAdjustment {
                superScrollView = view
                break
            } else {
                //  Getting it's superScrollView.   //  (Enhancement ID: #21, #24)
                superView = view.superviewOfClassType(UIScrollView.self) as? UIScrollView
            }
        }

        //If there was a lastScrollView.    //  (Bug ID: #34)
        if let lastScrollView = lastScrollView {
            //If we can't find current superScrollView, then setting lastScrollView to it's original form.
            if superScrollView == nil {

                if lastScrollView.contentInset != self.startingContentInsets {
                    showLog("Restoring contentInset to: \(startingContentInsets)")
                    UIView.animate(withDuration: animationDuration, delay: 0, options: animationCurve, animations: {

                        lastScrollView.contentInset = self.startingContentInsets
                        lastScrollView.scrollIndicatorInsets = self.startingScrollIndicatorInsets
                    })
                }

                if lastScrollView.shouldRestoreScrollViewContentOffset, lastScrollView.contentOffset != startingContentOffset {
                    showLog("Restoring contentOffset to: \(startingContentOffset)")

                    var animatedContentOffset = false   //  (Bug ID: #1365, #1508, #1541)

                    if #available(iOS 9, *) {
                        animatedContentOffset = textFieldView.superviewOfClassType(UIStackView.self, belowView: lastScrollView) != nil
                    }

                    if animatedContentOffset {
                        lastScrollView.setContentOffset(startingContentOffset, animated: UIView.areAnimationsEnabled)
                    } else {
                        lastScrollView.contentOffset = startingContentOffset
                    }
                }

                startingContentInsets = UIEdgeInsets()
                startingScrollIndicatorInsets = UIEdgeInsets()
                startingContentOffset = CGPoint.zero
                self.lastScrollView = nil
            } else if superScrollView != lastScrollView {     //If both scrollView's are different, then reset lastScrollView to it's original frame and setting current scrollView as last scrollView.

                if lastScrollView.contentInset != self.startingContentInsets {
                    showLog("Restoring contentInset to: \(startingContentInsets)")
                    UIView.animate(withDuration: animationDuration, delay: 0, options: animationCurve, animations: {

                        lastScrollView.contentInset = self.startingContentInsets
                        lastScrollView.scrollIndicatorInsets = self.startingScrollIndicatorInsets
                    })
                }

                if lastScrollView.shouldRestoreScrollViewContentOffset, lastScrollView.contentOffset != startingContentOffset {
                    showLog("Restoring contentOffset to: \(startingContentOffset)")

                    var animatedContentOffset = false   //  (Bug ID: #1365, #1508, #1541)

                    if #available(iOS 9, *) {
                        animatedContentOffset = textFieldView.superviewOfClassType(UIStackView.self, belowView: lastScrollView) != nil
                    }

                    if animatedContentOffset {
                        lastScrollView.setContentOffset(startingContentOffset, animated: UIView.areAnimationsEnabled)
                    } else {
                        lastScrollView.contentOffset = startingContentOffset
                    }
                }

                self.lastScrollView = superScrollView
                if let scrollView = superScrollView {
                    startingContentInsets = scrollView.contentInset
                    startingContentOffset = scrollView.contentOffset

                    if #available(iOS 11.1, *) {
                        startingScrollIndicatorInsets = scrollView.verticalScrollIndicatorInsets
                    } else {
                        startingScrollIndicatorInsets = scrollView.scrollIndicatorInsets
                    }
                }

                showLog("Saving ScrollView New contentInset: \(startingContentInsets) and contentOffset: \(startingContentOffset)")
            }
            //Else the case where superScrollView == lastScrollView means we are on same scrollView after switching to different textField. So doing nothing, going ahead
        } else if let unwrappedSuperScrollView = superScrollView {    //If there was no lastScrollView and we found a current scrollView. then setting it as lastScrollView.
            lastScrollView = unwrappedSuperScrollView
            startingContentInsets = unwrappedSuperScrollView.contentInset
            startingContentOffset = unwrappedSuperScrollView.contentOffset

            if #available(iOS 11.1, *) {
                startingScrollIndicatorInsets = unwrappedSuperScrollView.verticalScrollIndicatorInsets
            } else {
                startingScrollIndicatorInsets = unwrappedSuperScrollView.scrollIndicatorInsets
            }

            showLog("Saving ScrollView contentInset: \(startingContentInsets) and contentOffset: \(startingContentOffset)")
        }

        //  Special case for ScrollView.
        //  If we found lastScrollView then setting it's contentOffset to show textField.
        if let lastScrollView = lastScrollView {
            //Saving
            var lastView = textFieldView
            var superScrollView = self.lastScrollView

            while let scrollView = superScrollView {

                var shouldContinue = false

                if move > 0 {
                    shouldContinue =  move > (-scrollView.contentOffset.y - scrollView.contentInset.top)

                } else if let tableView = scrollView.superviewOfClassType(UITableView.self) as? UITableView {

                    shouldContinue = scrollView.contentOffset.y > 0

                    if shouldContinue, let tableCell = textFieldView.superviewOfClassType(UITableViewCell.self) as? UITableViewCell, let indexPath = tableView.indexPath(for: tableCell), let previousIndexPath = tableView.previousIndexPath(of: indexPath) {

                        let previousCellRect = tableView.rectForRow(at: previousIndexPath)
                        if !previousCellRect.isEmpty {
                            let previousCellRectInRootSuperview = tableView.convert(previousCellRect, to: rootController.view.superview)

                            move = min(0, previousCellRectInRootSuperview.maxY - topLayoutGuide)
                        }
                    }
                } else if let collectionView = scrollView.superviewOfClassType(UICollectionView.self) as? UICollectionView {

                    shouldContinue = scrollView.contentOffset.y > 0

                    if shouldContinue, let collectionCell = textFieldView.superviewOfClassType(UICollectionViewCell.self) as? UICollectionViewCell, let indexPath = collectionView.indexPath(for: collectionCell), let previousIndexPath = collectionView.previousIndexPath(of: indexPath), let attributes = collectionView.layoutAttributesForItem(at: previousIndexPath) {

                        let previousCellRect = attributes.frame
                        if !previousCellRect.isEmpty {
                            let previousCellRectInRootSuperview = collectionView.convert(previousCellRect, to: rootController.view.superview)

                            move = min(0, previousCellRectInRootSuperview.maxY - topLayoutGuide)
                        }
                    }
                } else {

                    shouldContinue = textFieldViewRectInRootSuperview.origin.y < topLayoutGuide

                    if shouldContinue {
                        move = min(0, textFieldViewRectInRootSuperview.origin.y - topLayoutGuide)
                    }
                }

                //Looping in upper hierarchy until we don't found any scrollView in it's upper hirarchy till UIWindow object.
                if shouldContinue {

                    var tempScrollView = scrollView.superviewOfClassType(UIScrollView.self) as? UIScrollView
                    var nextScrollView: UIScrollView?
                    while let view = tempScrollView {

                        if view.isScrollEnabled, !view.shouldIgnoreScrollingAdjustment {
                            nextScrollView = view
                            break
                        } else {
                            tempScrollView = view.superviewOfClassType(UIScrollView.self) as? UIScrollView
                        }
                    }

                    //Getting lastViewRect.
                    if let lastViewRect = lastView.superview?.convert(lastView.frame, to: scrollView) {

                        //Calculating the expected Y offset from move and scrollView's contentOffset.
                        var shouldOffsetY = scrollView.contentOffset.y - min(scrollView.contentOffset.y, -move)

                        //Rearranging the expected Y offset according to the view.
                        shouldOffsetY = min(shouldOffsetY, lastViewRect.origin.y)

                        //[_textFieldView isKindOfClass:[UITextView class]] If is a UITextView type
                        //nextScrollView == nil    If processing scrollView is last scrollView in upper hierarchy (there is no other scrollView upper hierrchy.)
                        //[_textFieldView isKindOfClass:[UITextView class]] If is a UITextView type
                        //shouldOffsetY >= 0     shouldOffsetY must be greater than in order to keep distance from navigationBar (Bug ID: #92)
                        if textFieldView is UITextView, nextScrollView == nil, shouldOffsetY >= 0 {

                            //  Converting Rectangle according to window bounds.
                            if let currentTextFieldViewRect = textFieldView.superview?.convert(textFieldView.frame, to: window) {

                                //Calculating expected fix distance which needs to be managed from navigation bar
                                let expectedFixDistance = currentTextFieldViewRect.minY - topLayoutGuide

                                //Now if expectedOffsetY (superScrollView.contentOffset.y + expectedFixDistance) is lower than current shouldOffsetY, which means we're in a position where navigationBar up and hide, then reducing shouldOffsetY with expectedOffsetY (superScrollView.contentOffset.y + expectedFixDistance)
                                shouldOffsetY = min(shouldOffsetY, scrollView.contentOffset.y + expectedFixDistance)

                                //Setting move to 0 because now we don't want to move any view anymore (All will be managed by our contentInset logic.
                                move = 0
                            } else {
                                //Subtracting the Y offset from the move variable, because we are going to change scrollView's contentOffset.y to shouldOffsetY.
                                move -= (shouldOffsetY-scrollView.contentOffset.y)
                            }
                        } else {
                            //Subtracting the Y offset from the move variable, because we are going to change scrollView's contentOffset.y to shouldOffsetY.
                            move -= (shouldOffsetY-scrollView.contentOffset.y)
                        }

                        let newContentOffset = CGPoint(x: scrollView.contentOffset.x, y: shouldOffsetY)

                        if scrollView.contentOffset != newContentOffset {

                            showLog("old contentOffset: \(scrollView.contentOffset) new contentOffset: \(newContentOffset)")
                            self.showLog("Remaining Move: \(move)")

                            //Getting problem while using `setContentOffset:animated:`, So I used animation API.
                            UIView.animate(withDuration: animationDuration, delay: 0, options: animationCurve, animations: {

                                var animatedContentOffset = false   //  (Bug ID: #1365, #1508, #1541)

                                if #available(iOS 9, *) {
                                    animatedContentOffset = textFieldView.superviewOfClassType(UIStackView.self, belowView: scrollView) != nil
                                }

                                if animatedContentOffset {
                                    scrollView.setContentOffset(newContentOffset, animated: UIView.areAnimationsEnabled)
                                } else {
                                    scrollView.contentOffset = newContentOffset
                                }
                            }) { _ in

                                if scrollView is UITableView || scrollView is UICollectionView {
                                    //This will update the next/previous states
                                    self.addToolbarIfRequired()
                                }
                            }
                        }
                    }

                    //  Getting next lastView & superScrollView.
                    lastView = scrollView
                    superScrollView = nextScrollView
                } else {
                    move = 0
                    break
                }
            }

            //Updating contentInset
            if let lastScrollViewRect = lastScrollView.superview?.convert(lastScrollView.frame, to: window),
                lastScrollView.shouldIgnoreContentInsetAdjustment == false {

                var bottomInset: CGFloat = (kbSize.height)-(window.frame.height-lastScrollViewRect.maxY)
                var bottomScrollIndicatorInset = bottomInset - newKeyboardDistanceFromTextField

                // Update the insets so that the scroll vew doesn't shift incorrectly when the offset is near the bottom of the scroll view.
                bottomInset = max(startingContentInsets.bottom, bottomInset)
                bottomScrollIndicatorInset = max(startingScrollIndicatorInsets.bottom, bottomScrollIndicatorInset)

                if #available(iOS 11, *) {
                    bottomInset -= lastScrollView.safeAreaInsets.bottom
                    bottomScrollIndicatorInset -= lastScrollView.safeAreaInsets.bottom
                }

                var movedInsets = lastScrollView.contentInset
                movedInsets.bottom = bottomInset

                if lastScrollView.contentInset != movedInsets {
                    showLog("old ContentInset: \(lastScrollView.contentInset) new ContentInset: \(movedInsets)")

                    UIView.animate(withDuration: animationDuration, delay: 0, options: animationCurve, animations: {
                        lastScrollView.contentInset = movedInsets

                        var newScrollIndicatorInset: UIEdgeInsets

                        if #available(iOS 11.1, *) {
                            newScrollIndicatorInset = lastScrollView.verticalScrollIndicatorInsets
                        } else {
                            newScrollIndicatorInset = lastScrollView.scrollIndicatorInsets
                        }

                        newScrollIndicatorInset.bottom = bottomScrollIndicatorInset
                        lastScrollView.scrollIndicatorInsets = newScrollIndicatorInset
                    })
                }
            }
        }
        //Going ahead. No else if.

        //Special case for UITextView(Readjusting textView.contentInset when textView hight is too big to fit on screen)
        //_lastScrollView       If not having inside any scrollView, (now contentInset manages the full screen textView.
        //[_textFieldView isKindOfClass:[UITextView class]] If is a UITextView type
        if let textView = textFieldView as? UITextView, textView.isScrollEnabled {

            //                CGRect rootSuperViewFrameInWindow = [_rootViewController.view.superview convertRect:_rootViewController.view.superview.bounds toView:keyWindow];
            //
            //                CGFloat keyboardOverlapping = CGRectGetMaxY(rootSuperViewFrameInWindow) - keyboardYPosition;
            //
            //                CGFloat textViewHeight = MIN(CGRectGetHeight(_textFieldView.frame), (CGRectGetHeight(rootSuperViewFrameInWindow)-topLayoutGuide-keyboardOverlapping));

            let keyboardYPosition = window.frame.height - (kbSize.height-newKeyboardDistanceFromTextField)
            var rootSuperViewFrameInWindow = window.frame
            if let rootSuperview = rootController.view.superview {
                rootSuperViewFrameInWindow = rootSuperview.convert(rootSuperview.bounds, to: window)
            }

            let keyboardOverlapping = rootSuperViewFrameInWindow.maxY - keyboardYPosition

            let textViewHeight = min(textView.frame.height, rootSuperViewFrameInWindow.height-topLayoutGuide-keyboardOverlapping)

            if textView.frame.size.height-textView.contentInset.bottom>textViewHeight {
                //_isTextViewContentInsetChanged,  If frame is not change by library in past, then saving user textView properties  (Bug ID: #92)
                if !self.isTextViewContentInsetChanged {
                    self.startingTextViewContentInsets = textView.contentInset

                    if #available(iOS 11.1, *) {
                        self.startingTextViewScrollIndicatorInsets = textView.verticalScrollIndicatorInsets
                    } else {
                        self.startingTextViewScrollIndicatorInsets = textView.scrollIndicatorInsets
                    }
                }

                self.isTextViewContentInsetChanged = true

                var newContentInset = textView.contentInset
                newContentInset.bottom = textView.frame.size.height-textViewHeight

                if #available(iOS 11, *) {
                    newContentInset.bottom -= textView.safeAreaInsets.bottom
                }

                if textView.contentInset != newContentInset {
                    self.showLog("\(textFieldView) Old UITextView.contentInset: \(textView.contentInset) New UITextView.contentInset: \(newContentInset)")

                    UIView.animate(withDuration: animationDuration, delay: 0, options: animationCurve, animations: {

                        textView.contentInset = newContentInset
                        textView.scrollIndicatorInsets = newContentInset
                    })
                }
            }
        }

        //  +Positive or zero.
        if move >= 0 {

            rootViewOrigin.y = max(rootViewOrigin.y - move, min(0, -(kbSize.height-newKeyboardDistanceFromTextField)))

            if rootController.view.frame.origin != rootViewOrigin {
                showLog("Moving Upward")

                UIView.animate(withDuration: animationDuration, delay: 0, options: animationCurve, animations: {

                    var rect = rootController.view.frame
                    rect.origin = rootViewOrigin
                    rootController.view.frame = rect

                    //Animating content if needed (Bug ID: #204)
                    if self.layoutIfNeededOnUpdate {
                        //Animating content (Bug ID: #160)
                        rootController.view.setNeedsLayout()
                        rootController.view.layoutIfNeeded()
                    }

                    self.showLog("Set \(rootController) origin to: \(rootViewOrigin)")
                })
            }

            movedDistance = (topViewBeginOrigin.y-rootViewOrigin.y)
        } else {  //  -Negative
            let disturbDistance: CGFloat = rootViewOrigin.y-topViewBeginOrigin.y

            //  disturbDistance Negative = frame disturbed.
            //  disturbDistance positive = frame not disturbed.
            if disturbDistance <= 0 {

                rootViewOrigin.y -= max(move, disturbDistance)

                if rootController.view.frame.origin != rootViewOrigin {
                    showLog("Moving Downward")
                    //  Setting adjusted rootViewRect
                    //  Setting adjusted rootViewRect

                    UIView.animate(withDuration: animationDuration, delay: 0, options: animationCurve, animations: {

                        var rect = rootController.view.frame
                        rect.origin = rootViewOrigin
                        rootController.view.frame = rect

                        //Animating content if needed (Bug ID: #204)
                        if self.layoutIfNeededOnUpdate {
                            //Animating content (Bug ID: #160)
                            rootController.view.setNeedsLayout()
                            rootController.view.layoutIfNeeded()
                        }

                        self.showLog("Set \(rootController) origin to: \(rootViewOrigin)")
                    })
                }

                movedDistance = (topViewBeginOrigin.y-rootViewOrigin.y)
            }
        }

        let elapsedTime = CACurrentMediaTime() - startTime
        showLog("****** \(#function) ended: \(elapsedTime) seconds ******", indentation: -1)
    }

    func restorePosition() {

        hasPendingAdjustRequest = false

        //  Setting rootViewController frame to it's original position. //  (Bug ID: #18)
        guard topViewBeginOrigin != IQKeyboardManager.kIQCGPointInvalid, let rootViewController = rootViewController else {
            return
        }

        if rootViewController.view.frame.origin != self.topViewBeginOrigin {
            //Used UIViewAnimationOptionBeginFromCurrentState to minimize strange animations.
            UIView.animate(withDuration: animationDuration, delay: 0, options: animationCurve, animations: {

                self.showLog("Restoring \(rootViewController) origin to: \(self.topViewBeginOrigin)")

                //  Setting it's new frame
                var rect = rootViewController.view.frame
                rect.origin = self.topViewBeginOrigin
                rootViewController.view.frame = rect

                //Animating content if needed (Bug ID: #204)
                if self.layoutIfNeededOnUpdate {
                    //Animating content (Bug ID: #160)
                    rootViewController.view.setNeedsLayout()
                    rootViewController.view.layoutIfNeeded()
                }
            })
        }

        self.movedDistance = 0

        if rootViewController.navigationController?.interactivePopGestureRecognizer?.state == .began {
            self.rootViewControllerWhilePopGestureRecognizerActive = rootViewController
            self.topViewBeginOriginWhilePopGestureRecognizerActive = self.topViewBeginOrigin
        }

        self.rootViewController = nil
    }

    // MARK: Public Methods

    /*  Refreshes textField/textView position if any external changes is explicitly made by user.   */
    public func reloadLayoutIfNeeded() {

        guard privateIsEnabled(),
            keyboardShowing,
            topViewBeginOrigin != IQKeyboardManager.kIQCGPointInvalid,
            let textFieldView = textFieldView,
            textFieldView.isAlertViewTextField() == false else {
                return
        }
        optimizedAdjustPosition()
    }

    // MARK: - UIKeyboard Notifications

    /*  UIKeyboardWillShowNotification. */
    @objc func keyboardWillShow(_ notification: Notification?) {

        keyboardShowNotification = notification

        //  Boolean to know keyboard is showing/hiding
        keyboardShowing = true

        let oldKBFrame = keyboardFrame

        if let info = notification?.userInfo {

            //  Getting keyboard animation.
            if let curve = info[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt {
                animationCurve = UIView.AnimationOptions(rawValue: curve).union(.beginFromCurrentState)
            } else {
                animationCurve = UIView.AnimationOptions.curveEaseOut.union(.beginFromCurrentState)
            }

            //  Getting keyboard animation duration
            animationDuration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25

            //  Getting UIKeyboardSize.
            if let kbFrame = info[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {

                keyboardFrame = kbFrame
                showLog("UIKeyboard Frame: \(keyboardFrame)")
            }
        }

        guard privateIsEnabled() else {
            restorePosition()
            topViewBeginOrigin = IQKeyboardManager.kIQCGPointInvalid
            return
        }

        let startTime = CACurrentMediaTime()
        showLog("****** \(#function) started ******", indentation: 1)

        //  (Bug ID: #5)
        if let textFieldView = textFieldView, topViewBeginOrigin == IQKeyboardManager.kIQCGPointInvalid {

            //  keyboard is not showing(At the beginning only). We should save rootViewRect.
            rootViewController = textFieldView.parentContainerViewController()
            if let controller = rootViewController {

                if rootViewControllerWhilePopGestureRecognizerActive == controller {
                    topViewBeginOrigin = topViewBeginOriginWhilePopGestureRecognizerActive
                } else {
                    topViewBeginOrigin = controller.view.frame.origin
                }

                rootViewControllerWhilePopGestureRecognizerActive = nil
                topViewBeginOriginWhilePopGestureRecognizerActive = IQKeyboardManager.kIQCGPointInvalid

                self.showLog("Saving \(controller) beginning origin: \(self.topViewBeginOrigin)")
            }
        }

        //If last restored keyboard size is different(any orientation accure), then refresh. otherwise not.
        if keyboardFrame != oldKBFrame {

            //If textFieldView is inside UITableViewController then let UITableViewController to handle it (Bug ID: #37) (Bug ID: #76) See note:- https://developer.apple.com/library/ios/documentation/StringsTextFonts/Conceptual/TextAndWebiPhoneOS/KeyboardManagement/KeyboardManagement.html If it is UIAlertView textField then do not affect anything (Bug ID: #70).

            if keyboardShowing,
               let textFieldView = textFieldView,
               textFieldView.isAlertViewTextField() == false {

                //  keyboard is already showing. adjust position.
                optimizedAdjustPosition()
            }
        }

        let elapsedTime = CACurrentMediaTime() - startTime
        showLog("****** \(#function) ended: \(elapsedTime) seconds ******", indentation: -1)
    }

    /*  UIKeyboardDidShowNotification. */
    @objc func keyboardDidShow(_ notification: Notification?) {

        guard privateIsEnabled(),
              let textFieldView = textFieldView,
              let parentController = textFieldView.parentContainerViewController(), (parentController.modalPresentationStyle == UIModalPresentationStyle.formSheet || parentController.modalPresentationStyle == UIModalPresentationStyle.pageSheet),
              textFieldView.isAlertViewTextField() == false else {
            return
        }

        let startTime = CACurrentMediaTime()
        showLog("****** \(#function) started ******", indentation: 1)

        self.optimizedAdjustPosition()

        let elapsedTime = CACurrentMediaTime() - startTime
        showLog("****** \(#function) ended: \(elapsedTime) seconds ******", indentation: -1)
    }

    /*  UIKeyboardWillHideNotification. So setting rootViewController to it's default frame. */
    @objc func keyboardWillHide(_ notification: Notification?) {

        //If it's not a fake notification generated by [self setEnable:NO].
        if notification != nil {
            keyboardShowNotification = nil
        }

        //  Boolean to know keyboard is showing/hiding
        keyboardShowing = false

        if let info = notification?.userInfo {

            //  Getting keyboard animation.
            if let curve = info[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt {
                animationCurve = UIView.AnimationOptions(rawValue: curve).union(.beginFromCurrentState)
            } else {
                animationCurve = UIView.AnimationOptions.curveEaseOut.union(.beginFromCurrentState)
            }

            //  Getting keyboard animation duration
            animationDuration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25
        }

        //If not enabled then do nothing.
        guard privateIsEnabled() else {
            return
        }

        let startTime = CACurrentMediaTime()
        showLog("****** \(#function) started ******", indentation: 1)

        //Commented due to #56. Added all the conditions below to handle WKWebView's textFields.    (Bug ID: #56)
        //  We are unable to get textField object while keyboard showing on WKWebView's textField.  (Bug ID: #11)
        //    if (_textFieldView == nil)   return

        //Restoring the contentOffset of the lastScrollView
        if let lastScrollView = lastScrollView {

            UIView.animate(withDuration: animationDuration, delay: 0, options: animationCurve, animations: {

                if lastScrollView.contentInset != self.startingContentInsets {
                    self.showLog("Restoring contentInset to: \(self.startingContentInsets)")
                    lastScrollView.contentInset = self.startingContentInsets
                    lastScrollView.scrollIndicatorInsets = self.startingScrollIndicatorInsets
                }

                if lastScrollView.shouldRestoreScrollViewContentOffset, lastScrollView.contentOffset != self.startingContentOffset {
                    self.showLog("Restoring contentOffset to: \(self.startingContentOffset)")

                    var animatedContentOffset = false   //  (Bug ID: #1365, #1508, #1541)

                    if #available(iOS 9, *) {
                        animatedContentOffset = self.textFieldView?.superviewOfClassType(UIStackView.self, belowView: lastScrollView) != nil
                    }

                    if animatedContentOffset {
                        lastScrollView.setContentOffset(self.startingContentOffset, animated: UIView.areAnimationsEnabled)
                    } else {
                        lastScrollView.contentOffset = self.startingContentOffset
                    }
                }

                // TODO: restore scrollView state
                // This is temporary solution. Have to implement the save and restore scrollView state
                var superScrollView: UIScrollView? = lastScrollView

                while let scrollView = superScrollView {

                    let contentSize = CGSize(width: max(scrollView.contentSize.width, scrollView.frame.width), height: max(scrollView.contentSize.height, scrollView.frame.height))

                    let minimumY = contentSize.height - scrollView.frame.height

                    if minimumY < scrollView.contentOffset.y {

                        let newContentOffset = CGPoint(x: scrollView.contentOffset.x, y: minimumY)
                        if scrollView.contentOffset != newContentOffset {

                            var animatedContentOffset = false   //  (Bug ID: #1365, #1508, #1541)

                            if #available(iOS 9, *) {
                                animatedContentOffset = self.textFieldView?.superviewOfClassType(UIStackView.self, belowView: scrollView) != nil
                            }

                            if animatedContentOffset {
                                scrollView.setContentOffset(newContentOffset, animated: UIView.areAnimationsEnabled)
                            } else {
                                scrollView.contentOffset = newContentOffset
                            }

                            self.showLog("Restoring contentOffset to: \(self.startingContentOffset)")
                        }
                    }

                    superScrollView = scrollView.superviewOfClassType(UIScrollView.self) as? UIScrollView
                }
            })
        }

        restorePosition()

        //Reset all values
        lastScrollView = nil
        keyboardFrame = CGRect.zero
        startingContentInsets = UIEdgeInsets()
        startingScrollIndicatorInsets = UIEdgeInsets()
        startingContentOffset = CGPoint.zero
        //    topViewBeginRect = CGRectZero    //Commented due to #82

        let elapsedTime = CACurrentMediaTime() - startTime
        showLog("****** \(#function) ended: \(elapsedTime) seconds ******", indentation: -1)
    }

    @objc func keyboardDidHide(_ notification: Notification) {

        let startTime = CACurrentMediaTime()
        showLog("****** \(#function) started ******", indentation: 1)

        topViewBeginOrigin = IQKeyboardManager.kIQCGPointInvalid

        keyboardFrame = CGRect.zero

        let elapsedTime = CACurrentMediaTime() - startTime
        showLog("****** \(#function) ended: \(elapsedTime) seconds ******", indentation: -1)
    }

    // MARK: - UITextField/UITextView Notifications

    /**  UITextFieldTextDidBeginEditingNotification, UITextViewTextDidBeginEditingNotification. Fetching UITextFieldView object. */
    @objc func textFieldViewDidBeginEditing(_ notification: Notification) {

        let startTime = CACurrentMediaTime()
        showLog("****** \(#function) started ******", indentation: 1)

        //  Getting object
        textFieldView = notification.object as? UIView

        if overrideKeyboardAppearance, let textInput = textFieldView as? UITextInput, textInput.keyboardAppearance != keyboardAppearance {
            //Setting textField keyboard appearance and reloading inputViews.
            if let textFieldView = textFieldView as? UITextField {
                textFieldView.keyboardAppearance = keyboardAppearance
            } else if  let textFieldView = textFieldView as? UITextView {
                textFieldView.keyboardAppearance = keyboardAppearance
            }
            textFieldView?.reloadInputViews()
        }

        //If autoToolbar enable, then add toolbar on all the UITextField/UITextView's if required.
        if privateIsEnableAutoToolbar() {

            //UITextView special case. Keyboard Notification is firing before textView notification so we need to resign it first and then again set it as first responder to add toolbar on it.
            if let textView = textFieldView as? UITextView, textView.inputAccessoryView == nil {

                UIView.animate(withDuration: 0.00001, delay: 0, options: animationCurve, animations: {

                    self.addToolbarIfRequired()

                }, completion: { _ in

                    //On textView toolbar didn't appear on first time, so forcing textView to reload it's inputViews.
                    textView.reloadInputViews()
                })
            } else {
                //Adding toolbar
                addToolbarIfRequired()
            }
        } else {
            removeToolbarIfRequired()
        }

        resignFirstResponderGesture.isEnabled = privateShouldResignOnTouchOutside()
        textFieldView?.window?.addGestureRecognizer(resignFirstResponderGesture)    //   (Enhancement ID: #14)

        if privateIsEnabled() == false {
            restorePosition()
            topViewBeginOrigin = IQKeyboardManager.kIQCGPointInvalid
        } else {
            if topViewBeginOrigin == IQKeyboardManager.kIQCGPointInvalid {    //  (Bug ID: #5)

                rootViewController = textFieldView?.parentContainerViewController()

                if let controller = rootViewController {

                    if rootViewControllerWhilePopGestureRecognizerActive == controller {
                        topViewBeginOrigin = topViewBeginOriginWhilePopGestureRecognizerActive
                    } else {
                        topViewBeginOrigin = controller.view.frame.origin
                    }

                    rootViewControllerWhilePopGestureRecognizerActive = nil
                    topViewBeginOriginWhilePopGestureRecognizerActive = IQKeyboardManager.kIQCGPointInvalid

                    self.showLog("Saving \(controller) beginning origin: \(self.topViewBeginOrigin)")
                }
            }

            //If textFieldView is inside ignored responder then do nothing. (Bug ID: #37, #74, #76)
            //See notes:- https://developer.apple.com/library/ios/documentation/StringsTextFonts/Conceptual/TextAndWebiPhoneOS/KeyboardManagement/KeyboardManagement.html If it is UIAlertView textField then do not affect anything (Bug ID: #70).
            if keyboardShowing,
                let textFieldView = textFieldView,
                textFieldView.isAlertViewTextField() == false {

                //  keyboard is already showing. adjust position.
                optimizedAdjustPosition()
            }
        }

        let elapsedTime = CACurrentMediaTime() - startTime
        showLog("****** \(#function) ended: \(elapsedTime) seconds ******", indentation: -1)
    }

    /**  UITextFieldTextDidEndEditingNotification, UITextViewTextDidEndEditingNotification. Removing fetched object. */
    @objc func textFieldViewDidEndEditing(_ notification: Notification) {

        let startTime = CACurrentMediaTime()
        showLog("****** \(#function) started ******", indentation: 1)

        //Removing gesture recognizer   (Enhancement ID: #14)
        textFieldView?.window?.removeGestureRecognizer(resignFirstResponderGesture)

        // We check if there's a change in original frame or not.

        if let textView = textFieldView as? UITextView {

            if isTextViewContentInsetChanged {
                self.isTextViewContentInsetChanged = false

                if textView.contentInset != self.startingTextViewContentInsets {
                    self.showLog("Restoring textView.contentInset to: \(self.startingTextViewContentInsets)")

                    UIView.animate(withDuration: animationDuration, delay: 0, options: animationCurve, animations: {

                        //Setting textField to it's initial contentInset
                        textView.contentInset = self.startingTextViewContentInsets
                        textView.scrollIndicatorInsets = self.startingTextViewScrollIndicatorInsets

                    })
                }
            }
        }

        //Setting object to nil
        textFieldView = nil

        let elapsedTime = CACurrentMediaTime() - startTime
        showLog("****** \(#function) ended: \(elapsedTime) seconds ******", indentation: -1)
    }

    // MARK: - UIStatusBar Notification methods

    /**  UIApplicationWillChangeStatusBarOrientationNotification. Need to set the textView to it's original position. If any frame changes made. (Bug ID: #92)*/
    @objc func willChangeStatusBarOrientation(_ notification: Notification) {

        let currentStatusBarOrientation: UIInterfaceOrientation
        if #available(iOS 13, *) {
            currentStatusBarOrientation = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.windowScene?.interfaceOrientation ?? .unknown
        } else {
            currentStatusBarOrientation = UIApplication.shared.statusBarOrientation
        }

        guard let statusBarOrientation = notification.userInfo?[UIApplication.statusBarOrientationUserInfoKey] as? Int, currentStatusBarOrientation.rawValue != statusBarOrientation else {
            return
        }

        let startTime = CACurrentMediaTime()
        showLog("****** \(#function) started ******", indentation: 1)

        //If textViewContentInsetChanged is saved then restore it.
        if let textView = textFieldView as? UITextView {

            if isTextViewContentInsetChanged {
                self.isTextViewContentInsetChanged = false
                if textView.contentInset != self.startingTextViewContentInsets {
                    UIView.animate(withDuration: animationDuration, delay: 0, options: animationCurve, animations: {

                        self.showLog("Restoring textView.contentInset to: \(self.startingTextViewContentInsets)")

                        //Setting textField to it's initial contentInset
                        textView.contentInset = self.startingTextViewContentInsets
                        textView.scrollIndicatorInsets = self.startingTextViewScrollIndicatorInsets

                    })
                }
            }
        }

        restorePosition()

        let elapsedTime = CACurrentMediaTime() - startTime
        showLog("****** \(#function) ended: \(elapsedTime) seconds ******", indentation: -1)
    }
}

extension IQKeyboardManager: UIGestureRecognizerDelegate {

    /** Resigning on tap gesture.   (Enhancement ID: #14)*/
    @objc func tapRecognized(_ gesture: UITapGestureRecognizer) {

        if gesture.state == .ended {

            //Resigning currently responder textField.
            resignFirstResponder()
        }
    }

    /** Note: returning YES is guaranteed to allow simultaneous recognition. returning NO is not guaranteed to prevent simultaneous recognition, as the other gesture's delegate may return YES. */
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }

    /** To not detect touch events in a subclass of UIControl, these may have added their own selector for specific work */
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        //  Should not recognize gesture if the clicked view is either UIControl or UINavigationBar(<Back button etc...)    (Bug ID: #145)

        for ignoreClass in touchResignedGestureIgnoreClasses {

            if touch.view?.isKind(of: ignoreClass) ?? false {
                return false
            }
        }

        return true
    }
}
