//
//  ReactiveTests.swift
//  Aphid
//
//  Created by Robert F. Dickerson on 7/17/16.
//
//

import Foundation

import XCTest
@testable import Aphid

class ReactiveTests: XCTestCase {
    
    func testBasic() {
        
        let future = 5 ~> square
            
        let _ = future.onSuccess() {
            value in
            
            print (value)
        }
        
    }
    
//    func testChaining() {
//        
//        let future = 5 ~> square ~> square
//        
//        let _ = future.onSuccess() { value in
//            
//            print (value)
//        }
//        
//    }

}
