//
//  TipoutMethod.swift
//  Tipout
//
//  Created by James Pamplona on 10/9/15.
//  Copyright © 2015 James Pamplona. All rights reserved.
//

import Foundation

public enum TipoutMethod {
    case Percentage(Double)
    case Amount(Double)
    case Hourly(Double)
    case Function(() -> Double)
    
    public init?(method: String, value: Any) {

        switch method {
        case "hours", "Hours", "hourly", "Hourly" where value as? Double != nil:
            self = Hourly(value as! Double)
        case "percentage", "Percentage" where value as? Double != nil:
            self = Percentage(value as! Double)
        case "amount", "Amount" where value as? Double != nil:
            self = Amount(value as! Double)
        case "function", "Function" where value is () -> Double:
            self = Function(value as! () -> Double)
        default:
            return nil
        }

    }
}

extension TipoutMethod: Equatable {}

public func ==(lhs: TipoutMethod, rhs: TipoutMethod) -> Bool {
    switch (lhs, rhs) {
    case (.Percentage(let leftValue), .Percentage(let rightValue)) where leftValue == rightValue:
        return true
    case (.Amount(let leftValue), .Amount(let rightValue)) where leftValue == rightValue:
        return true
    case (.Hourly(let leftValue), .Hourly(let rightValue)) where leftValue == rightValue:
        return true
    case (.Function(let leftValue), .Function(let rightValue)) where leftValue() == rightValue():
        return true
    default:
        return false
    }
}

extension TipoutMethod: Hashable {
    public var hashValue: Int {
        switch self {
        case .Percentage(let value):
            return 0.hashValue ^ value.hashValue
        case .Amount(let value):
            return 1.hashValue ^ value.hashValue
        case .Hourly(let value):
            return 2.hashValue ^ value.hashValue
        case .Function(let value):
            return 3.hashValue ^ value().hashValue
        }
    }
}

extension TipoutMethod: CustomDebugStringConvertible {
    public var debugDescription: String {
        var descString = ""
        //        print("TipoutMethod.", terminator: "", toStream: &descString)
        print(".", terminator: "", toStream: &descString)
        
        switch self {
        case Percentage(let percent):
            print("Percentage(\(percent))", toStream: &descString)
        case .Amount(let amount):
            print("Amount(\(amount))", toStream: &descString)
        case .Hourly(let hours):
            print("Hourly(\(hours))", toStream: &descString)
        case .Function(let f):
            print("Function(\(f) (With a value of \(f()))", toStream: &descString)
        }
        
        return descString
    }
}