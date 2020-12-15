//
//  objc_Association.swift
//  IQKeyboardManagerSwift
//
//  Created by Sereivoan Yong on 12/15/20.
//

import ObjectiveC

@usableFromInline
final class Box<T> {

    var value: T

    init(value: T) {
        self.value = value
    }
}

@usableFromInline
func objc_getAssociatedBox<T>(_ object: Any, _ key: UnsafeRawPointer) -> Box<T>? {
    return objc_getAssociatedObject(object, key) as? Box<T>
}

@usableFromInline
func objc_getAssociatedValue<T>(_ object: Any, _ key: UnsafeRawPointer) -> T? {
    return (objc_getAssociatedBox(object, key) as Box<T>?)?.value
}

@usableFromInline
func objc_setAssociatedValue<T>(_ object: Any, _ key: UnsafeRawPointer, _ value: T?) {
    if let value = value {
        if let box = objc_getAssociatedBox(object, key) as Box<T>? {
            box.value = value
        } else {
            objc_setAssociatedObject(object, key, Box<T>(value: value), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    } else {
        objc_setAssociatedObject(object, key, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}
