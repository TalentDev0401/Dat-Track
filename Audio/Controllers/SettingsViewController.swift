//
//  SettingsViewController.swift
//  Audio
//
//  Created by TeamPlayer on 1/14/20.
//  Copyright © 2020 Audio. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {

    @IBOutlet weak var switchAutoMode: UISwitch!
    
    var homeVCDelegate  : HomeVCDelegate?
    var autoMode        : Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        switchAutoMode.isOn = autoMode
    }
    
    @IBAction func onBtnBack(_ sender: UIBarButtonItem) {
        if autoMode != switchAutoMode.isOn {
            self.homeVCDelegate?.didAutoModeChanged(switchAutoMode.isOn)
        }
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func TermsAndConditions(_ sender: Any) {
        
        guard let url = URL(string: "https://www.dat-track.com/tou") else {
          return //be safe
        }

        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
    
    @IBAction func PrivacyPolicy(_ sender: Any) {
        
        guard let url = URL(string: "https://www.dat-track.com/privacy-page") else {
          return //be safe
        }

        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }

    }

}
