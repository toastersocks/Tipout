//
//  TipoutModel.swift
//  Tipout
//
//  Created by James Pamplona on 5/29/15.
//  Copyright (c) 2015 James Pamplona. All rights reserved.
//


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
        
        var workerNames = workers.map { $0.id }
        workerNames.appendContentsOf(
            tipoutModel.workers.filter { self[$0.id] == nil }
                .map { $0.id })
        
        let combinedWorkers = workerNames.flatMap {
            (workerName: String) -> Worker? in
            
            guard let combinedWorker = self[workerName] + tipoutModel[workerName] else { return nil }
            /* If the worker's TipoutMethod is not .Function we need to change it to .Function so
             that their tipouts are not recalculated based on the combined tipout, and they can retain their original tipout amounts.
            */
            if case .Function = combinedWorker.method {
                return combinedWorker
            } else {
                return Worker(method: .Function({ combinedWorker.tipout }), id: combinedWorker.id)
            }
        }
        /**
        To combine by index rather than Worker name...
        
        var combinedWorkers = zip(workers, tipoutModel.workers).map(+)
        combinedWorkers.appendContentsOf(leftoverIndexes(x: workers, y: tipoutModel.workers))
        */
        
        let combinedTipoutModel = TipoutModel(roundToNearest: self.roundToNearest)
        combinedTipoutModel.totalFunction = { self.totalFunction() + tipoutModel.totalFunction() }
        
        combinedTipoutModel.workers = combinedWorkers
        
        return combinedTipoutModel
    }
    
    
    public dynamic var total: Double {
        set {
            willChangeValueForKey("total")
            // We're dealing with money, so truncate the total to 2 decimal places
            totalFunction = { truncate(newValue, toDecimalPlaces: 2) }
            assignTipoutFunctions()
            didChangeValueForKey("total")
        }
        get {
            return totalFunction()
        }
    }
    
    private dynamic var totalFunction: () -> Double
    
    
    
    dynamic public var workers = [Worker]() {
        didSet {
            assignTipoutFunctions()
        }
    }
    
    private func assignTipoutFunctions() {
        if !workers.isEmpty && total != 0.0 {
            
            let tipoutFuncs = calculateTipoutFunctions()
            for (index, function) in tipoutFuncs.enumerate() {
                workers[index].function = function
            }
        }
    }
    
    
    public dynamic var tipouts: [Double] {
        
        return workers.map { $0.tipout }
    }
    
    private var totalPercentageTipouts: Double {
        
        return workers
            .map { $0.method }
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
            * total
    }
    
    private var totalAmountTipouts: Double {
        return workers
            .map { $0.method }
            .filter {
                switch $0 {
                case .Amount:
                    return true
                default:
                    return false
                }
            }.map {
                (tipoutMethod: TipoutMethod) -> Double in
                switch tipoutMethod {
                case .Amount(let amount):
                    return amount
                default:
                    return 0.0
                }
            }.reduce(0, combine: + )
    }
    
    public var totalWorkersHours: Double {
        
        return workers
            .map { $0.method }
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
    
    private var totalFunctionTipouts: Double {
        
        return workers
            .map { $0.method }
            .filter {
                switch $0 {
                case .Function:
                    return true
                default:
                    return false
                }
            }.map {
                (tipoutMethod: TipoutMethod) -> Double in
                switch tipoutMethod {
                case .Function(let f):
                    return f()
                default:
                    return 0.0
                }
            }.reduce(0, combine: + )
    }
    
    
    // MARK: - Methods
    
    subscript(id: String) -> Worker? {
        return workers.filter { $0.id.localizedCaseInsensitiveCompare(id) == .OrderedSame }.first
    }
    
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
        
        var tipoutFuncs = workers.map { $0.method }
            .map {
                
                (tipoutMethod: TipoutMethod) -> TipoutCalcFunction in
                
                let function: TipoutCalcFunction
                
                switch tipoutMethod {
                    
                case .Percentage(let percentage):
                    
                    function = { self.round(self.total * percentage) }
                    
                case .Amount(let amount):
                    
                    function = { amount }
                    
                case .Hourly(let hours):
                    
                    function = { self.round((self.total - (self.totalPercentageTipouts + self.totalAmountTipouts + self.totalFunctionTipouts)) * (hours / self.totalWorkersHours)) }
                    
                case .Function(let f):
                    
                    function = f
                }
                
                
                // If we try to divide by zero, the result will be 'nan', 'Not a Number', so we have to check for this and return 0.0 if it is
                return isnan(function()) ? { 0.0 } : function
        }
        
        // Add any remainder to the first worker
        let remainder = calculateRemainder(tipoutFuncs)
        if remainder != 0.0 {
            tipoutFuncs[0] = { [tipoutFuncs] in tipoutFuncs[0]() + Tipout.round(calculateRemainder(tipoutFuncs), toNearest: 0.01) }
        }
        return tipoutFuncs
        
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
    
    class func keyPathsForValuesAffectingTipouts() -> Set<NSObject> {
        return Set(["workers", "total"])
    }
    
}

extension TipoutModel: CustomReflectable {
    
    public func customMirror() -> Mirror {
        return Mirror(self, children: [
            "tipoutStatus" : tipoutStatus,
            "total" : total,
            "workers" : workers,
            ], displayStyle: .Class,
            ancestorRepresentation: .Suppressed)
    }
}
