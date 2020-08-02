//
//  NoTrackFoundViewController.swift
//  Audio
//
//  Created by TeamPlayer on 1/14/20.
//  Copyright © 2020 Audio. All rights reserved.
//

import UIKit

class NoTrackFoundViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func onBtnClose(_ sender: UIButton) {
        
        navigationController?.popToViewController(ofClass: HomeViewController.self)
    }
    
    @IBAction func onBtnTryAgain(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
