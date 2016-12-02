//
//  WorkerSpec.swift
//  Tipout
//
//  Created by James Pamplona on 9/16/15.
//  Copyright © 2015 James Pamplona. All rights reserved.
//

import Foundation
@testable import Tipout
import Fox
import Nimble
//import NimbleFox
import Quick


class WorkerSpec: QuickSpec {
    var wasObserved = false
    override func spec() {
        
        describe("a Worker") {
            var worker: Worker!
            
            beforeEach {
                worker = Worker(method: .amount(100.0), id: "0")
            }
            describe("it's properties") {
                it(" should be observable") {
                    worker.addObserver(self, forKeyPath: "tipout", options: .new, context: nil)
                    worker.function = { 80.0 }
                    expect(self.wasObserved).to(beTrue())
                    self.wasObserved = false
                    
                    worker.addObserver(self, forKeyPath: "id", options: [.initial, .new], context: nil)
                    expect(self.wasObserved).to(beTrue())
                    self.wasObserved = false
                    
                    // NOTE: we can't do this because Worker's `method` property is not representable in objC
                    /*worker.addObserver(self, forKeyPath: "method", options: [.Initial, .New], context: nil)
                    expect(self.wasObserved).toEventually(beTrue())
                    self.wasObserved = false*/
                    
                }
            }
            
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let keyPath = keyPath else { return }
        
        switch keyPath {
        case "tipout":
            if let total = change?[NSKeyValueChangeKey.newKey] as? Double {
                debugPrint(total)
                wasObserved = true
            }
        case "id":
            if let id = change?[NSKeyValueChangeKey.newKey] as? String {
                debugPrint(id)
                wasObserved = true
            }
        case "method":
            if let method = change?[NSKeyValueChangeKey.newKey] as? TipoutMethod {
                debugPrint(method)
                wasObserved = true
            }
        default: return
        }
    }
}
