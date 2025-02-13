//
//  ViewController.swift
//  SampleApp-Swift
//
//  Created by Nimrod Shai on 2/23/16.
//  Copyright © 2016 LivePerson. All rights reserved.
//

import UIKit
import LPMessagingSDK
import LPAMS
import LPInfra
import LPMonitoring

class MessagingViewController: UIViewController {

    //MARK: - UI Properties
    @IBOutlet var accountTextField: UITextField!
    @IBOutlet var firstNameTextField: UITextField!
    @IBOutlet var lastNameTextField: UITextField!
    @IBOutlet var windowSwitch: UISwitch!
    @IBOutlet var authenticationSwitch: UISwitch!
    
    //MARK: - Properties
    private var pageId: String?
    private var campaignInfo: LPCampaignInfo?
    
    private var windowSwitchValue: Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: "WindowSwitch")
            UserDefaults.standard.synchronize()
        }
        get { return UserDefaults.standard.bool(forKey: "WindowSwitch") }
    }
    
    private var authenticationSwitchValue: Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: "AuthenticationSwitch")
            UserDefaults.standard.synchronize()
        }
        get { return UserDefaults.standard.bool(forKey: "AuthenticationSwitch") }
    }
    
    private var conversationViewController: ConversationViewController?
    
    // Enter Your Code if using Autherization type 'Code'
    private let authenticationCode: String? = nil
    
    // Enter Your JWT if using Autherization type 'Implicit'
    private let authenticationJWT: String? = nil
    
    //MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Enter Your Account Number
        self.accountTextField.text = "ENTER_ACCOUNT"
        
        self.windowSwitch.isOn = windowSwitchValue
        self.authenticationSwitch.isOn = authenticationSwitchValue
        
        LPMessagingSDK.instance.delegate = self
        self.setSDKConfigurations()
//        LPMessagingSDK.instance.setLoggingLevel(level: .INFO)
    }

    //MARK: - IBActions
    @IBAction func resignKeyboard() {
        self.view.endEditing(true)
    }
    
    @IBAction func windowSwitchChanged(_ sender: UISwitch) {
        windowSwitchValue = sender.isOn
    }
    
    @IBAction func authenticationSwitchChanged(_ sender: UISwitch) {
        authenticationSwitchValue = sender.isOn
    }
    
    @IBAction func initSDKsClicked(_ sender: Any) {
        defer { self.view.endEditing(true) }
        
        guard let accountNumber = self.accountTextField.text, !accountNumber.isEmpty else {
            print("missing account number!")
            return
        }
        
        initLPSDKwith(accountNumber: accountNumber)
    }

    @IBAction func showConversation() {
        defer { self.view.endEditing(true) }
        
        guard let accountNumber = self.accountTextField.text, !accountNumber.isEmpty else {
            print("missing account number!")
            return
        }
        
        //Window Mode
        if windowSwitchValue {
            self.conversationViewController = nil
        } else {
            //for ViewController Mode ONLY
            self.conversationViewController = ConversationViewController()
            self.conversationViewController?.accountNumber = accountNumber
            self.conversationViewController?.conversationQueryProtocol = LPMessagingSDK.instance.getConversationBrandQuery(accountNumber)
        }
 
        showConversationFor(accountNumber: accountNumber, authenticatedMode: authenticationSwitchValue)
        
        //do not forget to push the controller (for ViewController Mode ONLY)
        if self.conversationViewController != nil {
            self.navigationController?.pushViewController(self.conversationViewController!, animated: true)
        }
    }
    
    @IBAction func logoutClicked(_ sender: Any) {
        logoutLPSDK()
    }
}

// MARK: - LPMessagingSDK Helpers
extension MessagingViewController {
    /**
     This method sets the SDK configurations.
     
     For example:
         Change background color of remote user (such as Agent)
         Change background color of user (such as Consumer)
     
    for more information on `defaultConfiguration` see: https://developers.liveperson.com/mobile-app-messaging-sdk-for-ios-customization-and-branding-customizing-the-sdk.html
     */
    private func setSDKConfigurations() {
        let configurations = LPConfig.defaultConfiguration
        
        /* the below  lets you enter a UIBarButton to the navigation bar (in window mode).
         When the button is pressed it will call the following delegate method: LPMessagingSDKCustomButtonTapped */
        configurations.customButtonImage = UIImage(named: "phone_icon")
    }
    
    private func getUnreadMessageCount() {
        guard let accountNumber = self.accountTextField.text, !accountNumber.isEmpty else {
            print("missing account number!")
            return
        }
        
        let conversationQuery = LPMessagingSDK.instance.getConversationBrandQuery(accountNumber)
        LPMessagingSDK.getUnreadMessagesCount(conversationQuery, completion: { (count) in
            print("unread message count: \(count)")
        }) { (error) in
            print("unread message count - error: \(error.localizedDescription)")
        }
    }
    
    /**
     This method initialize the messaging SDK
     
     for more information on `initialize` see:
         https://developers.liveperson.com/mobile-app-messaging-sdk-for-ios-sdk-apis-messaging-api.html#initialize
     */
    private func initLPSDKwith(accountNumber: String) {
        let appInstallID: String = "6ede89e2-6a28-4812-827b-31ee35838bf2"
        
        let monitoringInitParams = LPMonitoringInitParams(appInstallID: appInstallID)
        
        do {
            try LPMessagingSDK.instance.initialize(accountNumber, monitoringInitParams: monitoringInitParams)
        } catch let error as NSError {
            print("initialize error: \(error)")
        }
    }
    
    /**
     This method shows the conversation screen. It considers different modes:
     
     Window Mode:
     - Window           - Shows the conversation screen in a new window created by the SDK. Navigation bar is included.
     - View controller  - Shows the conversation screen in a view controller of your choice.
     
     Authentication Mode:
     - Authenticated    - Conversation history is saved and shown.
     - Unauthenticated  - Conversation starts clean every time.
     
     for more information on `showconversation` see:
         https://developers.liveperson.com/mobile-app-messaging-sdk-for-ios-sdk-apis-messaging-api.html#showconversation
     */
    private func showConversationFor(accountNumber: String, authenticatedMode: Bool) {
        //ConversationParamProtocol
        let conversationQuery = LPMessagingSDK.instance.getConversationBrandQuery(accountNumber)
        
        //LPConversationHistoryControlParam
        let controlParam = LPConversationHistoryControlParam(historyConversationsStateToDisplay: .none,
                                                             historyConversationsMaxDays: -1,
                                                             historyMaxDaysType: .startConversationDate)

        //LPAuthenticationParams
        var authenticationParams: LPAuthenticationParams?
       // if authenticatedMode {
            authenticationParams = LPAuthenticationParams(authenticationCode: authenticationCode,
                                                          jwt: authenticationJWT,
                                                          redirectURI: nil,
                                                          certPinningPublicKeys: nil,
                                                          authenticationType: .unauthenticated)
       // }
        
        // update Account number and ConversationQuery (for ViewController Mode ONLY)
        if self.conversationViewController != nil {
            self.conversationViewController?.accountNumber = accountNumber
            self.conversationViewController?.conversationQueryProtocol = conversationQuery
        }
        
        //LPWelcomeMessageParam
        let welcomeMessageParam = LPWelcomeMessage(message: "Hi", frequency: .FirstTimeConversation)

        //Get Engagement
        // **************** Beginning of code to set the engagement and the SDE
        
        let entryPoints = [] as [String]
        let engagementAttributes = [
                    ["type": "ctmrinfo",
                    "info": ["customerId": "12161216"]] // <----- replace the hardcoded value 12161216 with the customer's CIS
        ]
        
        let monitoringParams = LPMonitoringParams(entryPoints: entryPoints, engagementAttributes: engagementAttributes)
        
        let identity = LPMonitoringIdentity(consumerID: nil, issuer: nil)
        
        LPMonitoringAPI.instance.getEngagement(identities: [identity], monitoringParams: monitoringParams, completion: { [weak self] (getEngagementResponse) in
            
            print("# of Campaigns received \(String(describing: getEngagementResponse.engagementDetails?.count))")
            print("received get engagement response with pageID: \(String(describing: getEngagementResponse.pageId)), campaignID: \(String(describing: getEngagementResponse.engagementDetails?.first?.campaignId)), engagementID: \(String(describing: getEngagementResponse.engagementDetails?.first?.engagementId))")
            
            // Save PageId for future reference
            self?.pageId = getEngagementResponse.pageId
            
            if let campaignID = getEngagementResponse.engagementDetails?.first?.campaignId,
                let engagementID = getEngagementResponse.engagementDetails?.first?.engagementId,
                let contextID = getEngagementResponse.engagementDetails?.first?.contextId,
                let sessionID = getEngagementResponse.sessionId,
                let visitorID = getEngagementResponse.visitorId {
                
                self?.campaignInfo = LPCampaignInfo(campaignId: campaignID, engagementId: engagementID, contextId: contextID, sessionId: sessionID, visitorId: visitorID)
                
            } else {
                self?.campaignInfo = nil   // If the conversation is open the contextId is nil. The if statement above fails.
                print("no campaign info found!")
            }
            
            // Start the conversation
            
            //LPConversationViewParams
            let conversationViewParams = LPConversationViewParams(conversationQuery: LPMessagingSDK.instance.getConversationBrandQuery(accountNumber, campaignInfo: self?.campaignInfo),
                  containerViewController: nil,
                  isViewOnly: false,
                  conversationHistoryControlParam: controlParam,
                  welcomeMessage: welcomeMessageParam)
            
            LPMessagingSDK.instance.showConversation(conversationViewParams, authenticationParams: authenticationParams)

            self?.setUserDetails()
        }) { (error) in
            print("get engagement error: \(error.userInfo.description)")
        }
        // **************** End of code to set the engagement and the SDE
    }
    
    /**
     This method sets the user details such as first name, last name, profile image and phone number.
     
     for more info on `setUserProfile` see:
         https://developers.liveperson.com/mobile-app-messaging-sdk-for-ios-sdk-apis-messaging-api.html#setuserprofile
     */
    private func setUserDetails() {
        let user = LPUser(firstName: self.firstNameTextField.text!,
                          lastName: self.lastNameTextField.text!,
                          nickName: "my nick name",
                          uid: nil,
                          profileImageURL: "https://i-cdn.phonearena.com/images/article/68919-image/Emoji-usage-soars-according-to-Instagram.jpg",
                          phoneNumber: nil,
                          employeeID: "1111-1111")
        LPMessagingSDK.instance.setUserProfile(user, brandID: self.accountTextField.text!)
    }
    
    /**
     This method logouts from Monitoring and Messaging SDKs - all the data will be cleared
     
     for more info on `logout` see:
         https://developers.liveperson.com/mobile-app-messaging-sdk-for-ios-methods-logout.html
     */
    private func logoutLPSDK() {
        LPMessagingSDK.instance.logout(completion: {
            print("successfully logout from MessagingSDK")
        }) { (error) in
            print("failed to logout from MessagingSDK - error: \(error)")
        }
    }
    
    
    /**
     This method gets an engagement using LPMonitoingAPI
     - NOTE: CampaignInfo will be saved in the response in order to start a conversation later (showConversation method from LPMessagingSDK)
     
     for more information on `showconversation` see:
        https://developers.liveperson.com/mobile-app-messaging-sdk-for-ios-sdk-apis-monitoring-api.html#getengagement
    */
    private func getEngagement(entryPoints: [String], engagementAttributes: [[String:Any]]) {
        //resetting pageId and campaignInfo
        self.pageId = nil
        self.campaignInfo = nil
        
        let monitoringParams = LPMonitoringParams(entryPoints: entryPoints, engagementAttributes: engagementAttributes)
        
        let identity = LPMonitoringIdentity(consumerID: nil, issuer: nil)
        
        LPMonitoringAPI.instance.getEngagement(identities: [identity], monitoringParams: monitoringParams, completion: { [weak self] (getEngagementResponse) in
            
            print("# of Campaigns received \(String(describing: getEngagementResponse.engagementDetails?.count))")
            print("received get engagement response with pageID: \(String(describing: getEngagementResponse.pageId)), campaignID: \(String(describing: getEngagementResponse.engagementDetails?.first?.campaignId)), engagementID: \(String(describing: getEngagementResponse.engagementDetails?.first?.engagementId))")
            
            // Save PageId for future reference
            self?.pageId = getEngagementResponse.pageId
            
            if let campaignID = getEngagementResponse.engagementDetails?.first?.campaignId,
                let engagementID = getEngagementResponse.engagementDetails?.first?.engagementId,
                let contextID = getEngagementResponse.engagementDetails?.first?.contextId,
                let sessionID = getEngagementResponse.sessionId,
                let visitorID = getEngagementResponse.visitorId {
                self?.campaignInfo = LPCampaignInfo(campaignId: campaignID, engagementId: engagementID, contextId: contextID, sessionId: sessionID, visitorId: visitorID)
            } else {
                print("no campaign info found!")
            }
        }) { (error) in
            print("get engagement error: \(error.userInfo.description)")
        }
    }
}

//MARK: - LPMessagingSDKdelegate

/**
 for more info on `LPMessagingSDKdelegate` see:
     https://developers.liveperson.com/mobile-app-messaging-sdk-for-ios-sdk-apis-callbacks-index.html#lpmessagingsdkdelegate
 */
extension MessagingViewController: LPMessagingSDKdelegate {
    
    /**
    This delegate method is required.
    It is called when authentication process fails
    */
    func LPMessagingSDKAuthenticationFailed(_ error: NSError) {
        NSLog("Error: \(error)")
    }
    
    /**
    This delegate method is required.
    It is called when the SDK version you're using is obselete and needs an update.
    */
    func LPMessagingSDKObseleteVersion(_ error: NSError) {
        NSLog("Error: \(error)")
    }
    
    /**
    This delegate method is optional.
    It is called each time the SDK receives info about the agent on the other side.
    
    Example:
    You can use this data to show the agent details on your navigation bar (in view controller mode)
    */
    func LPMessagingSDKAgentDetails(_ agent: LPUser?) {
        guard self.conversationViewController != nil else { return }

        let name: String = agent?.nickName ?? ""
        self.conversationViewController?.title = name
    }
    
    /**
    This delegate method is optional.
    It is called each time the SDK menu is opened/closed.
    */
    func LPMessagingSDKActionsMenuToggled(_ toggled: Bool) {
        
    }
    
    /**
    This delegate method is optional.
    It is called each time the agent typing state changes.
    */
    func LPMessagingSDKAgentIsTypingStateChanged(_ isTyping: Bool) {
        
    }
    
    /**
    This delegate method is optional.
    It is called after the customer satisfaction page is submitted with a score.
    */
    func LPMessagingSDKCSATScoreSubmissionDidFinish(_ accountID: String, rating: Int) {
    
    }
    
    /**
    This delegate method is optional.
    If you set a custom button, this method will be called when the custom button is clicked.
    */
    func LPMessagingSDKCustomButtonTapped() {
        
    }
    
    /**
    This delegate method is optional.
    It is called whenever an event log is received.
    */
    func LPMessagingSDKDidReceiveEventLog(_ eventLog: String) {
        
    }
    
    /**
    This delegate method is optional.
    It is called when the SDK has connections issues.
    */
    func LPMessagingSDKHasConnectionError(_ error: String?) {
        NSLog("Error: \(String(describing: error))")
    }

    /**
     This delegate method is required.
     It is called when the token which used for authentication is expired
     */
    func LPMessagingSDKTokenExpired(_ brandID: String) {
        NSLog("LPMessagingSDKTokenExpired")
    }
    
    /**
     This delegate method is required.
     It lets you know if there is an error with the sdk and what this error is
     */
    func LPMessagingSDKError(_ error: NSError) {
        NSLog("Error: \(error)")
    }
    
    /**
     This delegate method is optional.
     It is called when the conversation view controller removed from its container view controller or window.
     */
    func LPMessagingSDKConversationViewControllerDidDismiss() {
        
    }
    
    /**
     This delegate method is optional.
     It is called when a new conversation has started, from the agent or from the consumer side.
     */
    func LPMessagingSDKConversationStarted(_ conversationID: String?) {
        
    }
    
    /**
     This delegate method is optional.
     It is called when a conversation has ended, from the agent or from the consumer side.
     */
    func LPMessagingSDKConversationEnded(_ conversationID: String?) {
        
    }
    
    /**
     This delegate method is optional.
     It is called when the customer satisfaction survey is dismissed after the user has submitted the survey/
     */
    func LPMessagingSDKConversationCSATDismissedOnSubmittion(_ conversationID: String?) {
        
    }
    
    /**
     This delegate method is optional.
     It is called each time connection state changed for a brand with a flag whenever connection is ready.
     Ready means that all conversations and messages were synced with the server.
     */
    func LPMessagingSDKConnectionStateChanged(_ isReady: Bool, brandID: String) {
        
    }
    
    /**
     This delegate method is optional.
     It is called when the user tapped on the agent’s avatar in the conversation and also in the navigation bar within window mode.
     */
    func LPMessagingSDKAgentAvatarTapped(_ agent: LPUser?) {
        
    }
    
    /**
     This delegate method is optional.
     It is called when the Conversation CSAT did load
    */
    func LPMessagingSDKConversationCSATDidLoad(_ conversationID: String?) {
        
    }
    
    /**
     This delegate method is optional.
     It is called when the Conversation CSAT skipped by the consumer
     */
    func LPMessagingSDKConversationCSATSkipped(_ conversationID: String?) {
        
    }
    
    /**
     This delegate method is optional.
     It is called when the user is opening photo sharing gallery/camera and the persmissions denied
    */
    func LPMessagingSDKUserDeniedPermission(_ permissionType: LPPermissionTypes) {
        
    }
}
