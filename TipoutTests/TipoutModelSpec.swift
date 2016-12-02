//
//  TipoutModelSpec.swift
//  Tippy
//
//  Created by James Pamplona on 6/11/15.
//  Copyright (c) 2015 James Pamplona. All rights reserved.
//

import Foundation
import Tipout
import Fox
import Nimble
//import NimbleFox
import Quick

extension NSNumber {
    
    static prefix func - (num: NSNumber) -> NSNumber {
        return NSNumber(value: -num.intValue)
    }
}

private func generateDouble(_ f: @escaping (Double) -> Bool) -> FOXGenerator {
    return forAll(FOXDouble()) {
        (floatNum: Any!) -> Bool in
        return f(floatNum as! Double)
    } as! (AnyObject!) -> Bool as! FOXGenerator
}


private func moveDecimal(_ num: Int, places: Int) -> Double {
    let factor = pow(Double(10), Double(places))
    return Double(num) / factor

}


private func bigDecimalGenerator() -> FOXGenerator {
    let bounds: NSNumber = 999999999
    
    let numGenerator = FOXChoose(-bounds, bounds)
    
    return FOXMap(numGenerator) {
        let num = $0 as! Int
        return moveDecimal(num, places: 5)
    }
    
}


private func generateBigMixedDouble(_ f: @escaping (Double) -> Bool) -> FOXGenerator {
  
    return forAll(bigDecimalGenerator()) {
        (mixedNum: Any!) -> Bool in
        return f(mixedNum as! Double)
    }
}


func anyTipoutMethod() -> FOXGenerator {
    let kEnumValueString = "enumValueString"
    let kAssociatedValue = "associatedValue"
    return FOXDictionary([
        kEnumValueString: FOXElements(["Hourly", "Percentage"]),
        kAssociatedValue: FOXDouble()
        ])
    }


class TipoutSpec: QuickSpec {
    var wasObserved = false
    override func spec() {
        
        describe("a TipoutModel") {
            var tipoutModel: TipoutModel!
            
            beforeEach {
                tipoutModel = TipoutModel(roundToNearest: 0.25)
            }
            describe("its total") {
                
                it("its total should be equal to the total of all worker tipouts") {
                    tipoutModel.workers = [Worker(method: .percentage(0.3), id: "1"),Worker(method: .hourly(4), id: "2"), Worker(method: .hourly(3), id: "3"), Worker(method: .hourly(1), id: "4")]
                    let property = generateBigMixedDouble() {
                        (num: Double) in
                        tipoutModel.total = num
                        
                        return abs(tipoutModel.tipouts.reduce(0, + ) - tipoutModel.total) < 0.0001
                    }
                    expect(property).to(hold())
                }
            
            }
            
            /**
            *  Sanity check
            */
            describe("a worker's tipout") {
                context("when a worker's tipout is 30%, and the total is 100") {
                    it("should be 30") {
                        tipoutModel.workers = [Worker(method: .percentage(0.3), id: "1"), Worker(method: .hourly(1), id: "2")]
                        tipoutModel.total = 100
                        expect(tipoutModel.tipouts[0]) == 30.0
                    }
                }
            }
            
            describe("the properties") {
                

                it("should be assignable in any order and tipouts should be equivalent") {
                    tipoutModel.total = 100.6
                    tipoutModel.workers =      [Worker(method: .percentage(0.3), id: "1"), Worker(method: .hourly(3), id: "2"), Worker(method: .hourly(1), id: "3")]
                    
                    let tipoutModel2 = TipoutModel(roundToNearest: 0.25)
                    
                    tipoutModel2.workers = [Worker(method: .percentage(0.3), id: "1"), Worker(method: .hourly(3), id: "2"), Worker(method: .hourly(1), id: "3")]
                    tipoutModel2.total = 100.6
                    
                    expect(tipoutModel.tipouts) == tipoutModel2.tipouts
                }
                
                it("should be observable") {
                    tipoutModel.total = 100.6
                    tipoutModel.workers =      [Worker(method: .percentage(0.3), id: "1"), Worker(method: .hourly(3), id: "2"), Worker(method: .hourly(1), id: "3")]
                    
                    tipoutModel.addObserver(self, forKeyPath: "workers", options: .new, context: nil)
                    tipoutModel.workers[1] = Worker(method: .amount(5), id: "bob")
                    expect(self.wasObserved).toEventually(beTrue())
                    self.wasObserved = false
                    
                    tipoutModel.addObserver(self, forKeyPath: "total", options: .new, context: nil)
                    tipoutModel.total = 52.0
                    expect(self.wasObserved).toEventually(beTrue())
                }
            }
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let keyPath = keyPath else { return }
        switch keyPath {
            
        case "workers":
            if let newWorkers = change?[NSKeyValueChangeKey.newKey] as? Array<Worker> {
                print(newWorkers)
                wasObserved = true
            }
        case "total":
            if let newTotal = change?[NSKeyValueChangeKey.newKey] as? Double {
                print(newTotal)
                wasObserved = true
            }
        default:
            return
        }
    }
}



