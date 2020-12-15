//
//  TableViewInContainerViewController.swift
//  IQKeyboardManager
//
//  Created by InfoEnum02 on 20/04/15.
//  Copyright (c) 2015 Iftekhar. All rights reserved.
//

import UIKit

final class ScrollStackViewController: UIViewController {

    lazy private(set) var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = .white
        scrollView.alwaysBounceHorizontal = false
        scrollView.alwaysBounceVertical = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.contentInset = UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 0)
        scrollView.keyboardDismissMode = .interactive
        scrollView.layoutMargins = .zero
        scrollView.preservesSuperviewLayoutMargins = true
        return scrollView
    }()

    lazy private(set) var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.spacing = 12
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = .zero
        stackView.preservesSuperviewLayoutMargins = true
        return stackView
    }()

//    override func loadView() {
//        view = scrollView
//    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 11.0, *) {
            view.insetsLayoutMarginsFromSafeArea = false
        }

        scrollView.frame = view.bounds
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(scrollView)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)

//        NSLayoutConstraint.activate([
//            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
//
//            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
//            stackView.leftAnchor.constraint(equalTo: scrollView.leftAnchor),
//            scrollView.bottomAnchor.constraint(equalTo: stackView.bottomAnchor),
//            scrollView.rightAnchor.constraint(equalTo: stackView.rightAnchor)
//        ])

        if #available(iOS 11.0, *) {
            NSLayoutConstraint.activate([
                scrollView.contentLayoutGuide.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

                stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
                stackView.leftAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leftAnchor),
                scrollView.contentLayoutGuide.bottomAnchor.constraint(equalTo: stackView.bottomAnchor),
                scrollView.contentLayoutGuide.rightAnchor.constraint(equalTo: stackView.rightAnchor)
            ])
        }

        for _ in 1...20 {
            let textField = UITextField()
            textField.borderStyle = .roundedRect
            stackView.addArrangedSubview(textField)
        }
    }

    @available(iOS 11.0, *)
    override func viewLayoutMarginsDidChange() {
        super.viewLayoutMarginsDidChange()
        print(view.layoutMargins)
    }
}

class TableViewInContainerViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIPopoverPresentationControllerDelegate {

    @IBAction func showDemo(_ sender: UIBarButtonItem) {
        let scrollStackViewController = ScrollStackViewController()
        let navigationController = UINavigationController(rootViewController: scrollStackViewController)
        present(navigationController, animated: true, completion: nil)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 30
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let identifier = "TestCell"

        var cell = tableView.dequeueReusableCell(withIdentifier: identifier)

        if cell == nil {

            cell = UITableViewCell(style: .default, reuseIdentifier: identifier)
            cell?.backgroundColor = UIColor.clear

            let contentView: UIView! = cell?.contentView

            let textField = UITextField(frame: CGRect(x: 10, y: 0, width: contentView.frame.size.width-20, height: 33))
            textField.autoresizingMask = [.flexibleBottomMargin, .flexibleTopMargin, .flexibleWidth]
            textField.center = contentView.center
            textField.backgroundColor = UIColor.clear
            textField.borderStyle = .roundedRect
            textField.tag = 123
            cell?.contentView.addSubview(textField)
        }

        let textField = cell?.viewWithTag(123) as? UITextField
        textField?.placeholder = "Cell \((indexPath as NSIndexPath).row)"

        return cell!
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if let identifier = segue.identifier {

            if identifier == "SettingsNavigationController" {

                let controller = segue.destination

                controller.modalPresentationStyle = .popover
                controller.popoverPresentationController?.barButtonItem = sender as? UIBarButtonItem

                let heightWidth = max(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
                controller.preferredContentSize = CGSize(width: heightWidth, height: heightWidth)
                controller.popoverPresentationController?.delegate = self
            }
        }
    }

    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }

    func prepareForPopoverPresentation(_ popoverPresentationController: UIPopoverPresentationController) {
        self.view.endEditing(true)
    }

    override var shouldAutorotate: Bool {
        return true
    }
}
