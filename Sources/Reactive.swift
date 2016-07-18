//
//  Reactive.swift
//  Aphid
//
//  Created by Robert F. Dickerson on 7/17/16.
//
//

import Foundation
import Dispatch

infix operator |> {associativity left precedence 100}


func |> <T>(lhs: T, rhs: (T)->T) -> T {
    return rhs(lhs)
}

enum Result<T> {
    case success(T)
    case failure(ErrorProtocol)
}

let queue = DispatchQueue(label: "Future Queue")


//class Promise<T> {
//    
//    var result: T? = nil
//
//    var future: Future<T>
//    
//    func resolve(_ result: T) {
//        
//        self.result = result
//        self.callback?(result)
//        
//    }
//}


class Future<T>  {
    
    var successCallback: ((T) -> Void)? = nil
    var errorCallback: ((ErrorProtocol) -> Void)? = nil
    
    var f: ((T, (Result<T>)->Void) -> Void)? = nil
    
    var next: Future? = nil
    
}

extension Future {
    
    func onSuccess(_ callback: ((T)->Void)) {
        self.successCallback = callback
    }
    
    func onError(_ callback: ((ErrorProtocol)->Void)) {
        self.errorCallback = callback
    }
    
    func then(f: (T, (Result<T>)->Void) -> Void) -> Future {
        let future = Future()
        self.next = future
        return future
    }
    
    func process(_ value: T) {
        queue.async() {
            self.f?(value) {
                self.resolve($0)
            }
        }
    }
    
    func notify( _ result: Result<T> ) {
        
        switch result {
            case .success(let value):
                process(value)
            case .failure:
                self.resolve(result)
        }
    }
    
    func resolve( _ result: Result<T> ) {
        
        switch result {
        case .success(let value):
            self.successCallback?( value )
        case .failure(let error):
            self.errorCallback?(error)
        }
        
        next?.notify( result )
        
    }
}

func ~> <T> (first: T, f: (T, (Result<T>)->Void) -> Void ) -> Future<T> {
    
    let future = Future<T>()
    
    future.f = f
    
    future.notify(.success(first))
    
    return future

}

func ~> <T> (first: Future<T>, f: (T, (Result<T>)->Void) -> Void) -> Future<T> {
    
    return first.then(f: f)
    
}

