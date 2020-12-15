//
//  IQBarButtonItem.swift
//  IQKeyboardManagerSwift
//
//  Created by Sereivoan Yong on 12/15/20.
//

import UIKit

open class IQBarButtonItem: UIBarButtonItem {

    private static var _classInitialize: Void = classInitialize()

    public override init() {
        _ = IQBarButtonItem._classInitialize
        super.init()
    }

    public required init?(coder: NSCoder) {
        _ = IQBarButtonItem._classInitialize
        super.init(coder: coder)
    }

    private class func classInitialize() {

        let  appearanceProxy = self.appearance()

        let states: [UIControl.State]

        states = [.normal, .highlighted, .disabled, .selected, .application, .reserved]

        for state in states {

            appearanceProxy.setBackgroundImage(nil, for: state, barMetrics: .default)
            appearanceProxy.setBackgroundImage(nil, for: state, style: .done, barMetrics: .default)
            appearanceProxy.setBackgroundImage(nil, for: state, style: .plain, barMetrics: .default)
            appearanceProxy.setBackButtonBackgroundImage(nil, for: state, barMetrics: .default)
        }

        appearanceProxy.setTitlePositionAdjustment(UIOffset(), for: .default)
        appearanceProxy.setBackgroundVerticalPositionAdjustment(0, for: .default)
        appearanceProxy.setBackButtonBackgroundVerticalPositionAdjustment(0, for: .default)
    }

    override open var tintColor: UIColor? {
        didSet {

            var textAttributes = [NSAttributedString.Key: Any]()
            textAttributes[.foregroundColor] = tintColor

            if let attributes = titleTextAttributes(for: .normal) {
                for (key, value) in attributes {
                    textAttributes[key] = value
                }
            }

            setTitleTextAttributes(textAttributes, for: .normal)
        }
    }

    /**
     Boolean to know if it's a system item or custom item, we are having a limitation that we cannot override a designated initializer, so we are manually setting this property once in initialization
     */
    var isSystemItem = false

    /**
     Additional target & action to do get callback action. Note that setting custom target & selector doesn't affect native functionality, this is just an additional target to get a callback.
     
     @param target Target object.
     @param action Target Selector.
     */
    open func setTarget(_ target: AnyObject?, action: Selector?) {
        if let target = target, let action = action {
            invocation = IQInvocation(target, action)
        } else {
            invocation = nil
        }
    }

    /**
     Customized Invocation to be called when button is pressed. invocation is internally created using setTarget:action: method.
     */
    var invocation: IQInvocation?
}

extension IQBarButtonItem {

    public convenience init(configuration: Configuration) {
        switch configuration.source {
        case .systemItem(let systemItem):
            self.init(barButtonSystemItem: systemItem, target: configuration.target, action: configuration.action)
            isSystemItem = true
        case .image(let image):
            self.init(image: image, style: .plain, target: configuration.target, action: configuration.action)
        case .title(let title):
            self.init(title: title, style: .plain, target: configuration.target, action: configuration.action)
        }
    }

    /// IQBarButtonItemConfiguration for creating toolbar with bar button items
    final public class Configuration: NSObject {

        enum Source {

            case systemItem(SystemItem)
            case image(UIImage)
            case title(String)
        }

        let source: Source

        public let systemItem: SystemItem?    //System Item to be used to instantiate bar button.

        public let image: UIImage?    //Image to show on bar button item if it's not a system item.

        public let title: String?     //Title to show on bar button item if it's not a system item.

        public let target: AnyObject?
        public let action: Selector?  //action for bar button item. Usually 'doneAction:(IQBarButtonItem*)item'.

        public init(systemItem: SystemItem, target: AnyObject?, action: Selector?) {
            source = .systemItem(systemItem)
            self.systemItem = systemItem
            self.image = nil
            self.title = nil
            self.target = target
            self.action = action
            super.init()
        }

        public init(image: UIImage?, target: AnyObject?, action: Selector?) {
            source = .image(image!)
            self.systemItem = nil
            self.image = image
            self.title = nil
            self.target = target
            self.action = action
            super.init()
        }

        public init(title: String, target: AnyObject?, action: Selector?) {
            source = .title(title)
            self.systemItem = nil
            self.image = nil
            self.title = title
            self.target = target
            self.action = action
            super.init()
        }
    }
}
