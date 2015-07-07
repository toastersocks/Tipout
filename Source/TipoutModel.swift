//
//  TipoutModel.swift
//  Tippy
//
//  Created by James Pamplona on 5/29/15.
//  Copyright (c) 2015 James Pamplona. All rights reserved.
//

import UIKit

private func max<T: CollectionType>(x: T, y: T) -> T {
    return count(x) > count(y) ? x : y
}

private func truncate(num: Double, toDecimalPlaces decimalPlaces: Int) -> Double {
    let factor = pow(Double(10), Double(decimalPlaces))
    return trunc(num * factor) / factor
}

private func round(num: Double, #toNearest: Double) -> Double {
    return round(num / toNearest) * toNearest
}

public enum TipoutMethod {
    case Percentage(Double)
    case Hourly(Double)
}

public func +(lhs: TipoutModel, rhs: TipoutModel) -> TipoutModel {
    return lhs.combineWith(rhs)
}



public class TipoutModel: NSObject {
    
    public enum TipoutStatus {
        case Over
        case Under
        case Even
    }
    
    
    internal typealias TipoutCalcFunction = () -> Double
    
    // MARK: - Properties
    
    private var roundToNearest: Double = 0.0
    
    public var tipoutStatus: TipoutStatus {
        let totalTips = tipouts.reduce(0, combine: + )
        switch totalTips {
            
        case _ where totalTips > total:
            return .Over
            
        case _ where totalTips < total:
            return .Under
            
        case _ where totalTips == total:
            return .Even
            
        default:
            abort()
        }
    }
    
    public func combineWith(tipoutModel: TipoutModel) -> TipoutModel {
        
        // TODO: Do this without modifying the original values --that is ugly. What are the implications of this?
        
        // We need to make the tipoutFunctions arrays the same size in order for addition of two TipoutModels to be commutative
        
        let countDifference = self.tipoutFunctions.count - tipoutModel.tipoutFunctions.count
        switch countDifference {
        case _ where countDifference > 0:
            tipoutModel.tipoutFunctions.extend([TipoutCalcFunction](count: countDifference, repeatedValue: { 0.0 }))
        case _ where countDifference < 0:
            self.tipoutFunctions.extend([TipoutCalcFunction](count: abs(countDifference), repeatedValue: { 0.0 }))
        default:
            break
        }
        
        let combinedTipoutModel = TipoutModel(roundToNearest: self.roundToNearest)
        
        combinedTipoutModel.totalFunction = { self.totalFunction() + tipoutModel.totalFunction() }
        
        combinedTipoutModel.tipoutFunctions = map(enumerate(self.tipoutFunctions)) {
            
            (index, function) -> TipoutCalcFunction in
            return { function() + tipoutModel.tipoutFunctions[index]() }
        }
        return combinedTipoutModel
    }
    
    public dynamic var total: Double {
        set {
            willChangeValueForKey("total")
            // We're dealing with money, so truncate the total to 2 decimal places
            totalFunction = { truncate(newValue, toDecimalPlaces: 2) }
            tipoutFunctions = calculateTipoutFunctions()
            didChangeValueForKey("total")
        }
        get {
            return totalFunction()
        }
    }
    
    private dynamic var totalFunction: () -> Double
    
    
    
    private var workers = [TipoutMethod]() {
        didSet {
            var tipoutFuncs = calculateTipoutFunctions()
            self.tipoutFunctions = tipoutFuncs
        }
    }
    
    
    
    
    
    // TODO: Use a Result type for this or throw an error in Swift 2. -- or maybe allow it but just indicate the status in a property as a helpful warning?
    
    public dynamic var tipouts: [Double] {
        
        return tipoutFunctions.map { $0() }
    }
    
    internal var tipoutFunctions = [TipoutCalcFunction]()
    
    private var totalPercentage: Double {
        
        return workers
            .filter {
                switch $0 {
                case .Percentage:
                    return true
                default:
                    return false
                }
            }.map {
                (tipoutMethod: TipoutMethod) -> Double in
                switch tipoutMethod {
                case .Percentage(let percent):
                    return percent
                default:
                    return 0.0
                }
            }.reduce(0, combine: + )
    }
    
    public var totalWorkersHours: Double {
        
        return workers
            .filter {
                switch $0 {
                case .Hourly:
                    return true
                default:
                    return false
                }
            }.map {
                (tipoutMethod: TipoutMethod) -> Double in
                switch tipoutMethod {
                case .Hourly(let hours):
                    return hours
                default:
                    return 0.0
                }
            }.reduce(0, combine: + )
        
    }
    
    
    // MARK: - Methods
    
    private func round(num: Double) -> Double {
        return Tipout.round(num, toNearest: roundToNearest)
    }
    
    private func calculateTipoutFunctions() -> [TipoutCalcFunction] {
        
        let calculateRemainder = { [total] (tipoutFuncs: [TipoutCalcFunction]) -> Double in
            if tipoutFuncs.isEmpty {
                return 0.0
            }
            
            let totalTipouts = tipoutFuncs.reduce(0, combine: { $0 + $1() })
            return total - totalTipouts
        }
        
       var tipoutFuncs = workers.map {
            
            (tipoutMethod: TipoutMethod) -> TipoutCalcFunction in
            
            let function: TipoutCalcFunction 
            
            switch tipoutMethod {
                
            case .Percentage(let percentage):
                
                function = { self.round(self.total * percentage) }
                
            case .Hourly(let hours):
                
                function = { self.round((self.total - self.totalPercentage * self.total) * (hours / self.totalWorkersHours)) }
            }
            
            
            // If we try to divide by zero, the result will be 'nan', 'Not a Number', so we have to check for this and return 0.0 if it is
            return isnan(function()) ? { 0.0 } : function
        }
        
        // Add any remainder to the first worker
        let remainder = calculateRemainder(tipoutFuncs)
        if remainder != 0.0 {
            tipoutFuncs[0] = { [tipoutFuncs] in tipoutFuncs[0]() + calculateRemainder(tipoutFuncs) }
        }
        return tipoutFuncs
        
    }
    
    public func setWorkers(workers: [TipoutMethod]) {
        willChangeValueForKey("workers")
        
        self.workers = workers
        
        didChangeValueForKey("workers")
    }
    
    
    
    // MARK: - Init
    
    public init(roundToNearest: Double) {
        self.roundToNearest = roundToNearest
        self.totalFunction = { 0.0 }
        super.init()
    }
    
    public convenience override init() {
        self.init(roundToNearest: 0.0)
    }
    
    
    // MARK: - KVO
    
//    class func keyPathsForValuesAffectingTotalWorkersHours() -> Set<NSObject> {
//        
//        return Set(["workers"])
//        
//    }
    
    class func keyPathsForValuesAffectingTipouts() -> Set<NSObject> {
        return Set(["workers", "total"])
    }
    
}
