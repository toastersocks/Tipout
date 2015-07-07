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


private func moveDecimal(num: Int, places: Int) -> Double {
    let factor = pow(Double(10), Double(places))
    return Double(num) / factor

}


private func bigDecimalGenerator() -> FOXGenerator {
    let bounds = 999999999999999
    let numGenerator = FOXChoose(-bounds, bounds)
    
    return FOXMap(numGenerator) {
        let num = $0 as! Int
        return moveDecimal(num, 5)
    }
    
}


private func generateBigMixedDouble(f: Double -> Bool) -> FOXGenerator {
  
    return forAll(bigDecimalGenerator()) {
        (mixedNum: AnyObject!) -> Bool in
        println(mixedNum)
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
    override func spec() {
        
        describe("a TipoutModel") {
            var tipoutModel: TipoutModel!
            
            beforeEach {
                tipoutModel = TipoutModel(roundToNearest: 0.25)
            }
            describe("its total") {
                
                it("its total should be equal to the total of all worker tipouts") {
                    tipoutModel.setWorkers([.Percentage(0.3), .Hourly(4), .Hourly(3), .Hourly(1)])
                    let property = generateBigMixedDouble() {
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
                        tipoutModel.setWorkers([.Percentage(0.3), .Hourly(1)])
                        tipoutModel.total = 100
                        expect(tipoutModel.tipouts[0]) == 30.0
                    }
                }
            }
            
            describe("the properties of a tipout") {
                xit("should be assignable in any order") {
                    tipoutModel.total = 100.6
                    tipoutModel.setWorkers([.Percentage(0.3), .Hourly(3)])
                }
            }
            
        }
    }
}