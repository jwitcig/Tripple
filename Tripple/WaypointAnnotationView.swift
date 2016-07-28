//
//  WaypointAnnotationView.swift
//  Tripple
//
//  Created by Developer on 7/19/16.
//  Copyright © 2016 JwitApps. All rights reserved.
//

import MapKit
import UIKit

class WaypointAnnotationView: MKAnnotationView {

    static var reuseIdentifier: String? {
        return "WaypointAnnotationView"
    }
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        
        self.addSubview(NSBundle.mainBundle().loadNibNamed("WaypointAnnotationView", owner: self, options: nil).first! as! UIView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.addSubview(NSBundle.mainBundle().loadNibNamed("WaypointAnnotationView", owner: self, options: nil).first! as! UIView)
    }
    
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
    
    }

}
