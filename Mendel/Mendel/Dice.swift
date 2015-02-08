//
//  dice.swift
//  genetic
//
//  Created by Saniul Ahmed on 05/01/2015.
//  Copyright (c) 2015 Saniul Ahmed. All rights reserved.
//

import Foundation

public typealias Probability = Float

@inline(__always) public func coinFlip() -> Bool {
    return arc4random_uniform(2) == 0
}

@inline(__always) public func roll(probability: Probability) -> Bool {
    if (probability == 1.0) {
        return true
    } else if (probability == 0.0) {
        return false
    }
    
    let roll = randomP()
    return probability > roll
}

@inline(__always) func randomP() -> Probability {
    return random(from:0.0, to: 1.0)
}

@inline(__always) func random(#from: Int, #to: Int) -> Int {
    return from + Int(arc4random_uniform(UInt32(to-from)))
}

@inline(__always) func random(#from:Float, #to: Float) -> Float {
    return from + (to-from)*(Float(arc4random()) / Float(UInt32.max))
}

@inline(__always) func random(#from:Double, #to: Double) -> Double {
    return from + (to-from)*(Double(arc4random()) / Double(UInt32.max))
}

func pickRandom<T>(from array: Array<T>) -> T {
    return array[Int(arc4random_uniform(UInt32(array.count)))]
}

@inline(__always) func withProbability<Result>(probability: Probability, f: () -> Result) -> Result? {
    if roll(probability) {
        return f()
    }
    
    return nil
}

@inline(__always) func chooseWithProbability<Result>(probability: Probability, f: () -> Result, g: () -> Result) -> Result {
    if roll(probability) {
        return f()
    } else {
        return g()
    }
}

@inline(__always) func pickFromRange<T>(range:Range<T>, withProbability probability: Probability) -> [T] {
    var selected = [T]()
    for i in range {
        withProbability(probability) {
            selected.append(i)
        }
    }
    
    return selected
}

