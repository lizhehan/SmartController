//
//  UIViewController+Extensions.swift
//  SmartController
//
//  Created by 李哲翰 on 2021/5/21.
//

import UIKit

extension UIViewController {
    func presentAlertController(title: String? = nil, message: String? = nil, okActionTitle: String = "好", cancelActionTitle: String = "取消", okHandler: ((UIAlertAction) -> Void)? = nil, cancelHandler: ((UIAlertAction) -> Void)? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction (title: okActionTitle , style: .default, handler: okHandler)
        let cancelAction = UIAlertAction (title: cancelActionTitle, style: .cancel, handler: cancelHandler)
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }
    
    func presentTextFieldAlertController(title: String? = nil, message: String? = nil, text: String? = nil, okActionTitle: String = "好", cancelActionTitle: String = "取消", okHandler: ((UIAlertAction, String?) -> Void)? = nil, cancelHandler: ((UIAlertAction) -> Void)? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.text = text
        }
        let okAction = UIAlertAction (title: okActionTitle , style: .default) { alertAction in
            let textField = alertController.textFields![0] as UITextField
            okHandler?(alertAction, textField.text)
        }
        let cancelAction = UIAlertAction (title: cancelActionTitle, style: .cancel, handler: cancelHandler)
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }
    
    func presentMessage(title: String?, message: String? = nil, handler: ((UIAlertAction) -> Void)? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "好", style: .default, handler: handler))
        present(alertController, animated: true)
    }
    
    func presentLoading(title: String = "\n\n") {
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        let activityIndicatorView = UIActivityIndicatorView()
        activityIndicatorView.startAnimating();
        alertController.view.addSubview(activityIndicatorView)
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.leadingAnchor.constraint(equalTo: alertController.view.leadingAnchor, constant: 16).isActive = true
        activityIndicatorView.centerYAnchor.constraint(equalTo: alertController.view.centerYAnchor).isActive = true
        present(alertController, animated: true)
    }
    
    func dismissLoading(animated flag: Bool = true, completion: (() -> Void)? = nil) {
        dismiss(animated: flag, completion: completion)
    }
}
