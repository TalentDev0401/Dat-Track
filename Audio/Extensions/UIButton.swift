//
//  UIButton.swift
//  Audio
//
//  Created by Talent on 02.03.2020.
//  Copyright © 2020 Audio. All rights reserved.
//

import Foundation

//MARK: Button rounded
extension UIButton {
    
    func CornerRadiusBtn() {
        
        // Set button corner radius.
        self.layer.cornerRadius = 10
       
        // Set button border width.
//        self.layer.borderWidth = 2
       
        // Set button border color to green.
//        self.layer.borderColor = UIColor.green.cgColor
        
        self.clipsToBounds = true
    }
    
    func CircleBtn() {
            
        self.layer.borderWidth=1.0
        self.layer.masksToBounds = false
//        btn.layer.borderColor = UIColor.white.cgColor
        self.layer.cornerRadius = self.frame.size.height/2
        self.clipsToBounds = true
    }
    
}
