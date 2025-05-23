/*
 See LICENSE folder for this sample’s licensing information.

 Abstract:
 A view controller that demonstrates how to use `UITextField`.
 */

import UIKit

class TextFieldViewController: BaseTableViewController {
    // Cell identifier for each text field table view cell.
    enum TextFieldKind: String, CaseIterable {
        case textField
        case tintedTextField
        case secureTextField
        case specificKeyboardTextField
        case customTextField
        case searchTextField
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        testCells.append(contentsOf: [
            CaseElement(title: NSLocalizedString("DefaultTextFieldTitle", comment: ""),
                        cellID: TextFieldKind.textField.rawValue,
                        configHandler: configureTextField),
            CaseElement(title: NSLocalizedString("TintedTextFieldTitle", comment: ""),
                        cellID: TextFieldKind.tintedTextField.rawValue,
                        configHandler: configureTintedTextField),
            CaseElement(title: NSLocalizedString("SecuretTextFieldTitle", comment: ""),
                        cellID: TextFieldKind.secureTextField.rawValue,
                        configHandler: configureSecureTextField),
            CaseElement(title: NSLocalizedString("SearchTextFieldTitle", comment: ""),
                        cellID: TextFieldKind.searchTextField.rawValue,
                        configHandler: configureSearchTextField),
        ])

        if traitCollection.userInterfaceIdiom != .mac {
            testCells.append(contentsOf: [
                // Show text field with specific kind of keyboard for iOS only.
                CaseElement(title: NSLocalizedString("SpecificKeyboardTextFieldTitle", comment: ""),
                            cellID: TextFieldKind.specificKeyboardTextField.rawValue,
                            configHandler: configureSpecificKeyboardTextField),

                // Show text field with custom background for iOS only.
                CaseElement(title: NSLocalizedString("CustomTextFieldTitle", comment: ""),
                            cellID: TextFieldKind.customTextField.rawValue,
                            configHandler: configureCustomTextField),
            ])
        }
    }

    // MARK: - Configuration

    func configureTextField(_ textField: UITextField) {
        textField.placeholder = NSLocalizedString("Placeholder text", comment: "")
        textField.autocorrectionType = .yes
        textField.returnKeyType = .done
        textField.clearButtonMode = .whileEditing
    }

    func configureTintedTextField(_ textField: UITextField) {
        textField.tintColor = UIColor.systemBlue
        textField.textColor = UIColor.systemGreen

        textField.placeholder = NSLocalizedString("Placeholder text", comment: "")
        textField.returnKeyType = .done
        textField.clearButtonMode = .never
    }

    func configureSecureTextField(_ textField: UITextField) {
        textField.isSecureTextEntry = true

        textField.placeholder = NSLocalizedString("Placeholder text", comment: "")
        textField.returnKeyType = .done
        textField.clearButtonMode = .always
    }

    func configureSearchTextField(_ textField: UITextField) {
        if let searchField = textField as? UISearchTextField {
            searchField.placeholder = NSLocalizedString("Enter search text", comment: "")
            searchField.returnKeyType = .done
            searchField.clearButtonMode = .always
            searchField.allowsDeletingTokens = true

            // Setup the left view as a symbol image view.
            let searchIcon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
            searchIcon.tintColor = UIColor.systemGray
            searchField.leftView = searchIcon
            searchField.leftViewMode = .always

            let secondToken = UISearchToken(icon: UIImage(systemName: "staroflife"), text: "Token 2")
            searchField.insertToken(secondToken, at: 0)

            let firstToken = UISearchToken(icon: UIImage(systemName: "staroflife.fill"), text: "Token 1")
            searchField.insertToken(firstToken, at: 0)
        }
    }

    /** 	There are many different types of keyboards that you may choose to use.
         The different types of keyboards are defined in the `UITextInputTraits` interface.
         This example shows how to display a keyboard to help enter email addresses.
     */
    func configureSpecificKeyboardTextField(_ textField: UITextField) {
        textField.keyboardType = .emailAddress

        textField.placeholder = NSLocalizedString("Placeholder text", comment: "")
        textField.returnKeyType = .done
    }

    func configureCustomTextField(_ textField: UITextField) {
        // Text fields with custom image backgrounds must have no border.
        textField.borderStyle = .none

        textField.background = UIImage(named: "text_field_background")

        // Create a purple button to be used as the right view of the custom text field.
        let purpleImage = UIImage(named: "text_field_purple_right_view")!
        let purpleImageButton = UIButton(type: .custom)
        purpleImageButton.bounds = CGRect(x: 0, y: 0, width: purpleImage.size.width, height: purpleImage.size.height)
        purpleImageButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 5)
        purpleImageButton.setImage(purpleImage, for: .normal)
        purpleImageButton.addTarget(self, action: #selector(TextFieldViewController.customTextFieldPurpleButtonClicked), for: .touchUpInside)
        textField.rightView = purpleImageButton
        textField.rightViewMode = .always

        textField.placeholder = NSLocalizedString("Placeholder text", comment: "")
        textField.autocorrectionType = .no
        textField.clearButtonMode = .never
        textField.returnKeyType = .done
    }

    // MARK: - Actions

    @objc
    func customTextFieldPurpleButtonClicked() {
        debugPrint("The custom text field's purple right view button was clicked.")
    }
}

// Custom text field for controlling input text placement.
class CustomTextField: UITextField {
    let leftMarginPadding: CGFloat = 12
    let rightMarginPadding: CGFloat = 36

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        var rect = bounds
        rect.origin.x += leftMarginPadding
        rect.size.width -= rightMarginPadding
        return rect
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        var rect = bounds
        rect.origin.x += leftMarginPadding
        rect.size.width -= rightMarginPadding
        return rect
    }
}
