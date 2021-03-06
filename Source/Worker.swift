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
    @objc public dynamic let id: String
    @objc internal dynamic var function: TipoutModel.TipoutCalcFunction
    @objc public dynamic var tipout: Double {
        return function()
    }
    
    // MARK: - Inits
    internal init(method: TipoutMethod = .amount(0.0), id: String = "", function: @escaping TipoutModel.TipoutCalcFunction) {
        self.method = method
        self.id = id
        self.function = function
    }

    public convenience init(method: TipoutMethod = .amount(0.0), id: String = "") {
        self.init(method: method, id: id, function: { 0.0 })
    }
    
    // MARK: KVO
    class func keyPathsForValuesAffectingTipout() -> Set<NSObject> {
        return Set(["function"]) as Set<NSObject>
    }
}

// MARK: - Extensions

private extension Worker {
    func combine(worker: Worker) -> Worker {
        let combinedFunc = { [tipout] in tipout + worker.tipout }
        
        return Worker(method: .function(combinedFunc), id: self.id, function: combinedFunc)
    }
    
    func combine(worker: Worker?) -> Worker {
        if let worker = worker {
            return combine(worker: worker)
        } else {
            return self
        }
    }
}

extension Worker {
    public override var hashValue: Int {
        return id.hashValue ^ method.hashValue ^ tipout.hashValue
    }
    public override var hash: Int {
        return hashValue
    }
    
    func isEqualToWorker(object: AnyObject?) -> Bool {
        guard let worker = object as? Worker else { return super.isEqual(object) }
        if self.id == worker.id && self.method == worker.method && self.tipout == worker.tipout {
            return true
        } else {
            return false
        }
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let worker = object as? Worker else { return super.isEqual(object) }
        return (self.id == worker.id && self.method == worker.method && self.tipout == worker.tipout)
    }
}

extension Worker/*: CustomDebugStringConvertible*/ {
    public override var debugDescription: String {
        var descString = ""
        print("{", to: &descString)
        print("id = \(id)", to: &descString)
        print("method = \(method)", to: &descString)
        print("tipout = \(tipout)", to: &descString)
        print("}", to: &descString)
        return descString
    }
}

extension Worker: CustomReflectable {
    
    public var customMirror: Mirror {
        return Mirror(self, children: [
            "method" : "\(method)",
            "id" : id,
            "tipout" : tipout
            ], displayStyle: .`struct`,
            ancestorRepresentation: .suppressed)
    }
}

// MARK: - Operators

public func +(lhs: Worker, rhs: Worker) -> Worker {
    return lhs.combine(worker: rhs)
}

public func +(lhs: Worker?, rhs: Worker?) -> Worker? {
    if let lhs = lhs {
        return lhs.combine(worker: rhs)
    } else {
        return rhs
    }
}

public func +(lhs: Worker, rhs: Worker?) -> Worker {
    return lhs.combine(worker: rhs)
}

public func +(lhs: Worker?, rhs: Worker) -> Worker {
    if let lhs = lhs {
        return lhs.combine(worker: rhs)
    } else {
        return rhs
    }
}
