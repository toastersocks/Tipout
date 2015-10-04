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
import NimbleFox
import Quick


class WorkerSpec: QuickSpec {
    var wasObserved = false
    override func spec() {
        
        describe("a Worker") {
            var worker: Worker!
            
            beforeEach {
                worker = Worker(method: .Amount(100.0), id: "0")
            }
            describe("it's properties") {
                it(" should be observable") {
                    worker.addObserver(self, forKeyPath: "tipout", options: .New, context: nil)
                    worker.function = { 80.0 }
                    expect(self.wasObserved).to(beTrue())
                    self.wasObserved = false
                    
                    worker.addObserver(self, forKeyPath: "id", options: [.Initial, .New], context: nil)
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
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        guard let keyPath = keyPath else { return }
        
        switch keyPath {
        case "tipout":
            if let total = change?[NSKeyValueChangeNewKey] as? Double {
                debugPrint(total)
                wasObserved = true
            }
        case "id":
            if let id = change?[NSKeyValueChangeNewKey] as? String {
                debugPrint(id)
                wasObserved = true
            }
        case "method":
            if let method = change?[NSKeyValueChangeNewKey] as? TipoutMethod {
                debugPrint(method)
                wasObserved = true
            }
        default: return
        }
    }
}
