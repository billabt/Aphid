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
    
    let group: DispatchGroup = DispatchGroup()
    
}

extension Future {
    
    func onSuccess(_ callback: ((T)->Void)) -> Future {
        let future = Future()
        self.successCallback = callback
        return future
    }
    
    func onError(_ callback: ((ErrorProtocol)->Void)) -> Future {
        let future = Future()
        self.errorCallback = callback
        return future
    }
    
    func resolve( _ result: Result<T> ) {
        
        switch result {
        case .success(let value):
            self.successCallback?( value )
        case .failure(let error):
            self.errorCallback?(error)
        
        }
        
        
    }
}


func square(a: Int, oncompletion: (Result<Int>)-> Void ) {
    oncompletion( .success(a * a) )
}

func ~> <T> (first: T, f: (T, (Result<T>)->Void) -> Void ) -> Future<T> {
    
    let future = Future<T>()
    
    queue.async() {
        
        f(first) {
            future.resolve($0)
        }
    }
    
    return future

}

func ~> <T> (first: Future<T>, f: (T, (T)->Void) -> Void) -> Future<T> {
    
    let future = Future<T>()
    
//    queue.async() {
//        
//        f(first.result!) {
//            future.resolve($0)
//            
//        }
//    }
    
    return Future()
    
}

