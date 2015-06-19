//
//  TipoutModel.swift
//  Tippy
//
//  Created by James Pamplona on 5/29/15.
//  Copyright (c) 2015 James Pamplona. All rights reserved.
//

import UIKit

private func round(num: Double, #toNearest: Double) -> Double {
    return round(num / toNearest) * toNearest
}

public class TipoutModel: NSObject {
    
    // MARK: - Properties
    
    private var roundToNearest: Double = 0.0
    
    
    public dynamic var total: Double = 0.0
    
    public dynamic var kitchenTipout: Double {
        var tipout = round((total * 0.3))
        tipout = total - (tipout + round(total - tipout)) + tipout
        return tipout
    }
    
    public dynamic var workersHours = [Double](count: 5, repeatedValue: 0.0)
    
    public dynamic var workersTipOuts: [Double] {
        
        let tipouts = workersHours.map {
            (workerHours: Double) -> Double in
            let tipout = self.round(((self.total - self.kitchenTipout) / self.totalWorkersHours * workerHours))
            // If we try to divide by zero, the result will be 'nan', 'Not a Number', so we have to check for this and return 0.0 if it is
            return isnan(tipout) ? 0.0 : tipout
        }
        return tipouts
    }
    
    public var totalWorkersHours: Double {
        return workersHours.reduce(0, combine: {$0 + $1})
    }
    
    // MARK: - Methods
    

    private func round(num: Double) -> Double {
        return Tippy.round(num, toNearest: roundToNearest)
    }
    
    
    // MARK: - Init
    
    public init(roundToNearest: Double) {
        self.roundToNearest = roundToNearest
        super.init()
    }
    
    public convenience override init() {
        self.init(roundToNearest: 0.0)
    }
    
    
    // MARK: - KVO
    class func keyPathsForValuesAffectingKitchenTipout() -> Set<NSObject> {
        return Set(["total"])
    }
    
    class func keyPathsForValuesAffectingTotalWorkersHours() -> Set<NSObject> {
        return Set(["workersHours"])
    }
    
    class func keyPathsForValuesAffectingWorkersTipOuts() -> Set<NSObject> {
        return Set(["workersHours", "total"])
    }
    
}
