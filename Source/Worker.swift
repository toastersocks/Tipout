//
//  Worker.swift
//  Tipout
//
//  Created by James Pamplona on 8/3/15.
//  Copyright (c) 2015 James Pamplona. All rights reserved.
//

import Foundation

// This is a class instead of a struct to work around a swift bug where a property observer on an array of structs is triggered when a property of one of it's struct elements is updated, even though the array property itself is not modified
public class Worker: NSObject {
    // MARK: - Properties
    
    public let method: TipoutMethod
    public dynamic let id: String
    internal dynamic var function: TipoutModel.TipoutCalcFunction
    public dynamic var tipout: Double {
        return function()
    }
    
    // MARK: - Inits
   internal init(method: TipoutMethod = .Amount(0.0), id: String = "", function: TipoutModel.TipoutCalcFunction) {
        self.method = method
        self.id = id
        self.function = function
    }

    public convenience init(method: TipoutMethod = .Amount(0.0), id: String = "") {
        self.init(method: method, id: id, function: { 0.0 })
    }
    
    // MARK: KVO
    class func keyPathsForValuesAffectingTipout() -> Set<NSObject> {
        return Set(["function"])
    }
}

// MARK: - Extensions

private extension Worker {
    func combine(worker: Worker) -> Worker {
        let combinedFunc = { [tipout] in tipout + worker.tipout }
        
        return Worker(method: .Function(combinedFunc), id: self.id, function: combinedFunc)
    }
    
    func combine(worker: Worker?) -> Worker {
        if let worker = worker {
            return combine(worker)
        } else {
            return self
        }
    }
}



extension Worker: CustomDebugStringConvertible {
    public override var debugDescription: String {
        var descString = ""
        print("{", toStream: &descString)
        print("id = \(id)", toStream: &descString)
        print("method = \(method)", toStream: &descString)
        print("tipout = \(tipout)", toStream: &descString)
        print("}", toStream: &descString)
        return descString
    }
}

// MARK: - Operators

public func +(lhs: Worker, rhs: Worker) -> Worker {
    return lhs.combine(rhs)
}

public func +(lhs: Worker?, rhs: Worker?) -> Worker? {
    if let lhs = lhs {
        return lhs.combine(rhs)
    } else {
        return rhs
    }
}

public func +(lhs: Worker, rhs: Worker?) -> Worker {
    return lhs.combine(rhs)
}

public func +(lhs: Worker?, rhs: Worker) -> Worker {
    if let lhs = lhs {
        return lhs.combine(rhs)
    } else {
        return rhs
    }
}