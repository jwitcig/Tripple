//
//  PinAnnotationView.swift
//  Tripple
//
//  Created by Developer on 7/19/16.
//  Copyright © 2016 JwitApps. All rights reserved.
//

import MapKit
import UIKit

class PinAnnotationView: MKAnnotationView {

    static var reuseIdentifier: String? {
        return "PinAnnotationView"
    }
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        
        self.addSubview(Bundle.main.loadNibNamed("PinAnnotationView", owner: self, options: nil)?.first! as! UIView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.addSubview(Bundle.main.loadNibNamed("PinAnnotationView", owner: self, options: nil)?.first! as! UIView)
    }
    
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
    
    }

}
