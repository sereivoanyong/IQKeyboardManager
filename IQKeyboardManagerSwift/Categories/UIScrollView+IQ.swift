//
//  UIScrollView+IQ.swift
//  IQKeyboardManagerSwift
//
//  Created by Sereivoan Yong on 12/15/20.
//

import UIKit

private var kShouldIgnoreScrollingAdjustment: Void?
private var kShouldIgnoreContentInsetAdjustment: Void?
private var kShouldRestoreScrollViewContentOffset: Void?

extension UIScrollView {

    /// If YES, then scrollview will ignore scrolling (simply not scroll it) for adjusting textfield position. Default is NO.
    final public var shouldIgnoreScrollingAdjustment: Bool {
        get { return objc_getAssociatedValue(self, &kShouldIgnoreScrollingAdjustment) ?? false }
        set { objc_setAssociatedValue(self, &kShouldIgnoreScrollingAdjustment, newValue) }
    }

    /// If YES, then scrollview will ignore content inset adjustment (simply not updating it) when keyboard is shown. Default is NO.
    final public var shouldIgnoreContentInsetAdjustment: Bool {
        get { return objc_getAssociatedValue(self, &kShouldIgnoreContentInsetAdjustment) ?? false }
        set { objc_setAssociatedValue(self, &kShouldIgnoreContentInsetAdjustment, newValue) }
    }

    /// To set customized distance from keyboard for textField/textView. Can't be less than zero
    final public var shouldRestoreScrollViewContentOffset: Bool {
        get { return objc_getAssociatedValue(self, &kShouldRestoreScrollViewContentOffset) ?? false }
        set { objc_setAssociatedValue(self, &kShouldRestoreScrollViewContentOffset, newValue) }
    }
}

extension UITableView {

    final func previousIndexPath(of indexPath: IndexPath) -> IndexPath? {
        var previousRow = indexPath.row - 1
        var previousSection = indexPath.section

        //Fixing indexPath
        if previousRow < 0 {
            previousSection -= 1
            if previousSection >= 0 {
                previousRow = numberOfRows(inSection: previousSection) - 1
            }
        }

        if previousRow >= 0, previousSection >= 0 {
            return IndexPath(row: previousRow, section: previousSection)
        } else {
            return nil
        }
    }
}

extension UICollectionView {

    final func previousIndexPath(of indexPath: IndexPath) -> IndexPath? {
        var previousRow = indexPath.row - 1
        var previousSection = indexPath.section

        //Fixing indexPath
        if previousRow < 0 {
            previousSection -= 1
            if previousSection >= 0 {
                previousRow = numberOfItems(inSection: previousSection) - 1
            }
        }

        if previousRow >= 0, previousSection >= 0 {
            return IndexPath(item: previousRow, section: previousSection)
        } else {
            return nil
        }
    }
}
