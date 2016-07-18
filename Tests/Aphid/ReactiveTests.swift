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
    
    func square(a: Int, oncompletion: (Result<Int>)-> Void ) {
        oncompletion( .success(a * a) )
    }
    
    struct AliceError : ErrorProtocol { }
    
    func notAlice(a: String, oncompletion: (Result<String>) -> Void) {
        
        if a == "Alice" {
            oncompletion( .failure(AliceError()) )
        } else {
            oncompletion(.success("Alice"))
        }
        
    }
    
    func testBasic() {
        
        let future = 5 ~> square
            
        let _ = future.onSuccess() {
            value in
            
            print (value)
        }
        
        sleep(1)
        
    }
    
    func testChaining() {
        
        let future = 5 ~> square ~> square
        
        future.onSuccess() { value in
            
            print (value)
        } 
        
    }
    
    func testNotAlice() {
        
        let future = "Alice" ~> notAlice
        
        future.onError() { error in 
            print("Error discovered!")
        }
    }

}
