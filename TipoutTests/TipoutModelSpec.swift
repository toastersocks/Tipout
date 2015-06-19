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
import NimbleFox
import Quick


private func generateDouble(f: Double -> Bool) -> FOXGenerator {
    return forAll(FOXDouble()) {
        (floatNum: AnyObject!) -> Bool in
        return f(floatNum as! Double)
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

//return FOXMap(dictionaryGenerator) {
//    (data) -> TipoutMethod! in
//    switch data[kEnumValueString] {
//    case "Hourly":
//        if let doubleVal = data[kAssociatedValue] as? Double {
//            return TipoutMethod.Hourly(doubleVal)
//        }
//    case
//    }
//    FOXElements([TipoutMethod.Hourly(FOXDouble()), TipoutMethod.Percentage(FOXDouble())])
//}

//private func generateTipoutMethod()


class TipoutSpec: QuickSpec {
    override func spec() {
        
        describe("a TipoutModel") {
            var tipoutModel: TipoutModel!
            
            beforeEach {
                tipoutModel = TipoutModel(roundToNearest: 0.25)
            }
            describe("its total") {
                
                it("its total should be equal to the total of all worker tipouts") {
                    tipoutModel.setWorkers([.Percentage(0.3), .Hourly(4), .Hourly(3), .Hourly(1)])
                    let property = generateDouble() {
                        (num: Double) in
                        tipoutModel.total = num
                        
                        return tipoutModel.tipouts.reduce(0, combine: + ) == tipoutModel.total
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
                        tipoutModel.setWorkers([.Percentage(0.3)])
                        tipoutModel.total = 100
                        expect(tipoutModel.tipouts[0]) == 30.0
                    }
                }
            }
        }
    }
}

//class TipoutModelSpec: QuickSpec {
//    override func spec() {
//
//        describe("a TipoutModel") {
//            var tipoutModel: TipoutModel!
//
//            beforeEach {
//                tipoutModel = TipoutModel(roundToNearest: 0.25)
//
//                tipoutModel.workersHours = [4.0, 3.0, 1.0]
//            }
//
//            describe("its total") {
//                it("should be equal to the total of all worker tipouts") {
//                    let property = generateDouble() {
//                        (num: Double) in
//                        tipoutModel.total = num
//
//                        return tipoutModel.workersTipOuts.reduce(tipoutModel.kitchenTipout, combine:{ $0 + $1 }) == tipoutModel.total
//                    }
////                    expect(tipoutModel.total).to(equal(tipoutModel.workersTipOuts.reduce(tipoutModel.kitchenTipout, combine:{ $0 + $1 })))
//                    expect(property).to(hold())
//                }
//            }
//
//            /**
//            *  Sanity check
//            */
//            describe("its kitchen tipout") {
//                context("when the total tips are 100") {
//                    it("should be 30") {
//                        tipoutModel.total = 100.0
//                        expect(tipoutModel.kitchenTipout) == 30.0
//                    }
//                }
//            }
//        }
//    }
//}