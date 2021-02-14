import Foundation
import MessageUI

extension Logger: MFMailComposeViewControllerDelegate
{
    class func sendViaEmail(vc: UIViewController)
    {
        if MFMailComposeViewController.canSendMail()
        {
            let logger = Logger.shared
            
            let composeVC = MFMailComposeViewController()
            composeVC.mailComposeDelegate = Logger.shared
            composeVC.setToRecipients([logEmail])
            composeVC.setSubject("Cube log")
            
            let string = logger.entries.map({ $0.string }).joined(separator: "\n")
            composeVC.setMessageBody(string, isHTML: false)
            vc.present(composeVC, animated: true)
        }
        else
        {
            let alert = UIAlertController(title: "No email account linked",
                                          message: "Add one in the Mail app and try again",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            vc.present(alert, animated: true, completion: nil)
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?)
    {
        controller.dismiss(animated: true)
    }
}
