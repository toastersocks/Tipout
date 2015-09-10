//
//  Worker.swift
//  Tipout
//
//  Created by James Pamplona on 8/3/15.
//  Copyright (c) 2015 James Pamplona. All rights reserved.
//

import Foundation

// This is a class instead of a struct to work around a swift bug where a property observer on an array of structs is triggered when a property of one of it's struct elements is updated, even though the array property itself is not modified
public class Worker {
    public let method: TipoutMethod
    public let id: String
    internal var function: TipoutModel.TipoutCalcFunction
    public var tipout: Double {
        return function()
    }
    

   internal init(method: TipoutMethod = .Amount(0.0), id: String = "", function: TipoutModel.TipoutCalcFunction = { 0.0 }) {
        self.method = method
        self.id = id
        self.function = function
    }
    
    public convenience init(method: TipoutMethod = .Amount(0.0), id: String = "") {
        self.init(method: method, id: id, function: { 0.0 })
    }
    
}


public extension Worker {
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
    public var debugDescription: String {
        var descString = ""
        print("{", toStream: &descString)
        print("id = \(id)", toStream: &descString)
        print("method = \(method)", toStream: &descString)
        print("tipout = \(tipout)", toStream: &descString)
        print("}", toStream: &descString)
        return descString
    }
}

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