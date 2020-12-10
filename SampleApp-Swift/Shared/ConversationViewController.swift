//
//  ConversationViewController.swift
//  SampleApp-Swift
//
//  Created by Nimrod Shai on 2/23/16.
//  Copyright © 2016 LivePerson. All rights reserved.
//

import Foundation
import LPMessagingSDK
import LPAMS
import LPInfra

class ConversationViewController: UIViewController {

    var accountNumber: String? = nil
    var conversationQueryProtocol: ConversationParamProtocol?
   
    //MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(backButtonPressed))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Menu", style: .plain, target: self, action: #selector(menuButtonPressed))
    }
    
    //MARK: - Actions
    @objc func backButtonPressed() {
        if let accountNumber = self.accountNumber {
            self.conversationQueryProtocol = LPMessagingSDK.instance.getConversationBrandQuery(accountNumber)
            if let conversationQuery = conversationQueryProtocol {
                LPMessagingSDK.instance.removeConversation(conversationQuery)
                _ = self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    @objc func menuButtonPressed() {
        var style = UIAlertController.Style.actionSheet
        if UIDevice.current.userInterfaceIdiom == .pad {
            style = .alert
        }
        
        let alertController = UIAlertController(title: "Menu", message: "Choose an option", preferredStyle: style)
        
        /**
        is how to resolve a conversation
        */
        guard let conversationQuery = self.conversationQueryProtocol else {
            debugPrint("no conversationQuery found!!!")
            return
        }
   
        //resolve option
        let resolveAction = UIAlertAction(title: "Resolve", style: .default) { (alert: UIAlertAction) -> Void in
            LPMessagingSDK.instance.resolveConversation(conversationQuery)
        }

        //urgent option
//        let urgentTitle = LPMessagingSDK.instance.isUrgent(conversationQuery) ? "Dismiss Urgent" : "Mark as Urgent"

        /**
        This is how to manage the urgency state of the conversation
        */
//        let urgentAction = UIAlertAction(title: urgentTitle, style: .default) { (alert: UIAlertAction) -> Void in
//            if LPMessagingSDK.instance.isUrgent(conversationQuery) {
//                LPMessagingSDK.instance.dismissUrgent(conversationQuery)
//            } else {
//                LPMessagingSDK.instance.markAsUrgent(conversationQuery)
//            }
//        }
        
        
        //cancel option
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(resolveAction)
//        alertController.addAction(urgentAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
}
