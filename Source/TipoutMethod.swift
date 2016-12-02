//
//  TipoutMethod.swift
//  Tipout
//
//  Created by James Pamplona on 10/9/15.
//  Copyright © 2015 James Pamplona. All rights reserved.
//

import Foundation

public enum TipoutMethod {
    case percentage(Double)
    case amount(Double)
    case hourly(Double)
    case function(() -> Double)
    
    public init?(method: String, value: Any) {

        switch method {
        case "hours" where value as? Double != nil, "Hours" where value as? Double != nil, "hourly" where value as? Double != nil, "Hourly" where value as? Double != nil:
            self = .hourly(value as! Double)
        case "percentage" where value as? Double != nil, "Percentage" where value as? Double != nil:
            self = .percentage(value as! Double)
        case "amount" where value as? Double != nil, "Amount" where value as? Double != nil:
            self = .amount(value as! Double)
        case "function" where value is () -> Double, "Function" where value is () -> Double:
            self = .function(value as! () -> Double)
        default:
            return nil
        }

    }
}

extension TipoutMethod: Equatable {}

public func ==(lhs: TipoutMethod, rhs: TipoutMethod) -> Bool {
    switch (lhs, rhs) {
    case (.percentage(let leftValue), .percentage(let rightValue)) where leftValue == rightValue:
        return true
    case (.amount(let leftValue), .amount(let rightValue)) where leftValue == rightValue:
        return true
    case (.hourly(let leftValue), .hourly(let rightValue)) where leftValue == rightValue:
        return true
    case (.function(let leftValue), .function(let rightValue)) where leftValue() == rightValue():
        return true
    default:
        return false
    }
}

extension TipoutMethod: Hashable {
    public var hashValue: Int {
        switch self {
        case .percentage(let value):
            return 0.hashValue ^ value.hashValue
        case .amount(let value):
            return 1.hashValue ^ value.hashValue
        case .hourly(let value):
            return 2.hashValue ^ value.hashValue
        case .function(let value):
            return 3.hashValue ^ value().hashValue
        }
    }
}

extension TipoutMethod: CustomDebugStringConvertible {
    public var debugDescription: String {
        var descString = ""
        //        print("TipoutMethod.", terminator: "", toStream: &descString)
        print(".", terminator: "", to: &descString)
        
        switch self {
        case .percentage(let percent):
            print("Percentage(\(percent))", to: &descString)
        case .amount(let amount):
            print("Amount(\(amount))", to: &descString)
        case .hourly(let hours):
            print("Hourly(\(hours))", to: &descString)
        case .function(let f):
            print("Function(\(f) (With a value of \(f()))", to: &descString)
        }
        
        return descString
    }
}
