//
//  TipoutModel.swift
//  Tipout
//
//  Created by James Pamplona on 5/29/15.
//  Copyright (c) 2015 James Pamplona. All rights reserved.
//


public func +(lhs: TipoutModel, rhs: TipoutModel) -> TipoutModel {
    return lhs.combineWith(tipoutModel: rhs)
}



public class TipoutModel: NSObject {
    
    public enum TipoutStatus {
        case over
        case under
        case even
    }
    
    
    internal typealias TipoutCalcFunction = () -> Double
    
    // MARK: - Properties
    
    private var roundToNearest: Double = 0.0
    
    public var tipoutStatus: TipoutStatus {
        let totalTips = tipouts.reduce(0, + )
        switch totalTips {
            
        case _ where totalTips > total:
            return .over
            
        case _ where totalTips < total:
            return .under
            
        case _ where totalTips == total:
            return .even
            
        default:
            abort()
        }
    }
    
    public func combineWith(tipoutModel: TipoutModel) -> TipoutModel {
        
        var workerNames = workers.map { $0.id }
        workerNames.append(
            contentsOf: tipoutModel.workers.filter { self[$0.id] == nil }
                .map { $0.id })
        
        let combinedWorkers = workerNames.flatMap {
            (workerName: String) -> Worker? in
            
            guard let combinedWorker = self[workerName] + tipoutModel[workerName] else { return nil }
            /* If the worker's TipoutMethod is not .Function we need to change it to .Function so
             that their tipouts are not recalculated based on the combined tipout, and they can retain their original tipout amounts.
            */
            if case .function = combinedWorker.method {
                return combinedWorker
            } else {
                return Worker(method: .function({ combinedWorker.tipout }), id: combinedWorker.id)
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
    
    
    @objc public dynamic var total: Double {
        set {
            willChangeValue(forKey: "total")
            // We're dealing with money, so truncate the total to 2 decimal places
            totalFunction = { truncate(num: newValue, toDecimalPlaces: 2) }
            assignTipoutFunctions()
            didChangeValue(forKey: "total")
        }
        get {
            return totalFunction()
        }
    }
    
    @objc private dynamic var totalFunction: () -> Double
    
    
    
    @objc dynamic public var workers = [Worker]() {
        didSet {
            assignTipoutFunctions()
            //            self.tipoutFunctions = tipoutFuncs
        }
    }
    
    private func assignTipoutFunctions() {
        if !workers.isEmpty && total != 0.0 {
            
            let tipoutFuncs = calculateTipoutFunctions()
            for (index, function) in tipoutFuncs.enumerated() {
                workers[index].function = function
            }
        }
    }
    
    
    @objc public dynamic var tipouts: [Double] {
        
        return workers.map { $0.tipout }
    }
    
    private var totalPercentageTipouts: Double {
        
        return workers
            .map { $0.method }
            .filter {
                switch $0 {
                case .percentage:
                    return true
                default:
                    return false
                }
            }.map {
                (tipoutMethod: TipoutMethod) -> Double in
                switch tipoutMethod {
                case .percentage(let percent):
                    return percent
                default:
                    return 0.0
                }
            }.reduce(0, + )
            * total
    }
    
    private var totalAmountTipouts: Double {
        return workers
            .map { $0.method }
            .filter {
                switch $0 {
                case .amount:
                    return true
                default:
                    return false
                }
            }.map {
                (tipoutMethod: TipoutMethod) -> Double in
                switch tipoutMethod {
                case .amount(let amount):
                    return amount
                default:
                    return 0.0
                }
            }.reduce(0, + )
    }
    
    public var totalWorkersHours: Double {
        
        return workers
            .map { $0.method }
            .filter {
                switch $0 {
                case .hourly:
                    return true
                default:
                    return false
                }
            }.map {
                (tipoutMethod: TipoutMethod) -> Double in
                switch tipoutMethod {
                case .hourly(let hours):
                    return hours
                default:
                    return 0.0
                }
            }.reduce(0, + )
        
    }
    
    private var totalFunctionTipouts: Double {
        
        return workers
            .map { $0.method }
            .filter {
                switch $0 {
                case .function:
                    return true
                default:
                    return false
                }
            }.map {
                (tipoutMethod: TipoutMethod) -> Double in
                switch tipoutMethod {
                case .function(let f):
                    return f()
                default:
                    return 0.0
                }
            }.reduce(0, + )
    }
    
    
    // MARK: - Methods
    
    subscript(id: String) -> Worker? {
        return workers.filter { $0.id == id }.first
    }
    
    private func round(num: Double) -> Double {
        return num.round(toNearest: roundToNearest)
    }
    
    private func calculateTipoutFunctions() -> [TipoutCalcFunction] {
        
        let calculateRemainder = { [total] (tipoutFuncs: [TipoutCalcFunction]) -> Double in
            if tipoutFuncs.isEmpty {
                return 0.0
            }
            
            let totalTipouts = tipoutFuncs.reduce(0, { $0 + $1() })
            return total - totalTipouts
        }
        
        var tipoutFuncs = workers.map { $0.method }
            .map {
                
                (tipoutMethod: TipoutMethod) -> TipoutCalcFunction in
                
                let function: TipoutCalcFunction
                
                switch tipoutMethod {
                    
                case .percentage(let percentage):
                    
                    function = { self.round(num: self.total * percentage) }
                    
                case .amount(let amount):
                    
                    function = { amount }
                    
                case .hourly(let hours):
                    
                    function = { self.round(num: (self.total - (self.totalPercentageTipouts + self.totalAmountTipouts + self.totalFunctionTipouts)) * (hours / self.totalWorkersHours)) }
                    
                case .function(let f):
                    
                    function = f
                }
                
                
                // If we try to divide by zero, the result will be 'nan', 'Not a Number', so we have to check for this and return 0.0 if it is
                return function().isNaN ? { 0.0 } : function
        }
        
        // Add any remainder to the first worker
        let remainder = calculateRemainder(tipoutFuncs)
        if remainder != 0.0 {
            tipoutFuncs[0] = { [tipoutFuncs] in tipoutFuncs[0]() + calculateRemainder(tipoutFuncs).round(toNearest: 0.01) }
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
        return Set(["workers", "total"]) as Set<NSObject>
    }
    
}

extension TipoutModel: CustomReflectable {
    
    public var customMirror: Mirror {
        return Mirror(self, children: [
            "tipoutStatus" : tipoutStatus,
            "total" : total,
            "workers" : workers,
            ], displayStyle: .`class`,
            ancestorRepresentation: .suppressed)
    }
}
