//
//  std.swift
//  genetic
//
// Based on FunSwift Book's appendix code

import Foundation

//The compose operator provides function composition.
func >>> <A, B, C>(f: A -> B, g: B -> C) -> A -> C {
    return { x in g(f(x)) }
}

//Shuffle collection
func shuffle<C: MutableCollectionType where C.Index == Int>(var list: C) -> C {
    let c = count(list)
    for i in 0..<(c - 1) {
        let j = Int(arc4random_uniform(UInt32(c - i))) + i
        swap(&list[i], &list[j])
    }
    return list
}

//The iterateWhile function repeatedly applies a function while the condition holds.
func iterateWhile<A>(condition: A -> Bool,
    initialValue: A,
    next: A -> A?) -> A {
        
        if let x = next(initialValue) {
            if condition(x) {
                return iterateWhile(condition, x, next)
            }
        }
        return initialValue
}

//Taken from https://gist.github.com/josephlord/e6298c724c0edadc3042#file-scanl1-swift
func scanl1<A>(input:[A], combiningF:(A,A)->A)->[A] {
    var running:A? = nil
    return map(input) { (nv:A)->A in
        if let curr:A = running {
            let newVal = combiningF(curr, nv)
            running = newVal
            return newVal
        } else {
            running = nv
            return nv
        }
    }
}

func insertionPoint<C : CollectionType where C.Generator.Element : Comparable, C.Index == Int>(domain: C, searchItem: C.Generator.Element) -> C.Index {
    var lowerIndex = domain.startIndex
    var upperIndex = domain.endIndex - 1
    
    while (true) {
        var currentIndex = (lowerIndex + upperIndex)/2
        let item = domain[currentIndex]
        
        if (domain[currentIndex] == searchItem) {
            return currentIndex
        } else if (lowerIndex >= upperIndex) {
            return lowerIndex
        } else {
            if (domain[currentIndex] > searchItem) {
                upperIndex = currentIndex.predecessor()
            } else {
                lowerIndex = currentIndex.successor()
            }
        }
    }
}

infix operator >>> {
associativity left
}

infix operator &&& {
associativity left
precedence 120
}

infix operator ||| {
associativity left
precedence 120
}