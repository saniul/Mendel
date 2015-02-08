//
//  Operators.swift
//  genetic
//
//  Created by Saniul Ahmed on 20/01/2015.
//  Copyright (c) 2015 Saniul Ahmed. All rights reserved.
//

import Foundation

public struct Operators {
    public static func Replace<I : IndividualType>(factory:()->I)(pop:[I])->[I] {
        return (0..<pop.count).map { _ in return factory() }
    }
    
    public static func Identity<I : IndividualType>(pop:[I])->[I] {
        return pop
    }
    
    public static func Crossover<I : Crossoverable>(probability:Probability)(pop:[I])->[I] {
        var result = [I]()
        
        var generator = shuffle(pop).generate()
        
        while let a = generator.next() {
            if let b = generator.next() {
                let crossed: [I] = chooseWithProbability(probability,
                    {
                        return I.cross(a, b)
                    }, {
                        return [a,b]
                    }
                )
                
                result += crossed
            } else {
                result.append(a)
            }
        }
        
        return result
    }
    
    public static func Mutation<I : Mutatable>(probability:Probability)(pop:[I])->[I] {
        //Looks like the for loop is faster than map
        
        var result = [I]()
        result.reserveCapacity(pop.count)
        for var i = 0; i < pop.count; i++ {
            let mutated: I = chooseWithProbability(probability,
                {
                    return I.mutate(pop[i])
                }, {
                    return pop[i]
                }
            )
            result.append(mutated)
        }
        
        return result
    }
    
    public static func Parallel<I : IndividualType>(batchSize str:UInt)(op: [I]->[I])(pop:[I])->[I] {
        //TODO: parametrize shuffling
        let pop = shuffle(pop)
        
        let queue = dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)
        
        let writeQueue = dispatch_queue_create("collate queue", DISPATCH_QUEUE_SERIAL)
        
        let group = dispatch_group_create()
        
        var results = [I]()
        results.reserveCapacity(pop.count)
        
        let iterations = UInt(pop.count)/str
        
        //TODO: write this in a more swifty way
        dispatch_apply(iterations, queue) { idx in
            var j = Int(idx * str)
            let j_stop = j + Int(str)
            dispatch_group_enter(group)
            let partial = op(Array(pop[j..<j_stop]))
            dispatch_async(writeQueue) {
                results.extend(partial)
                dispatch_group_leave(group)
            }
        }
        
        //handle the remainder
        dispatch_group_enter(group)
        dispatch_async(queue) {
            let startIdx = Int(iterations * str)
            let remainder = op(Array(pop[startIdx..<pop.count]))
            
            dispatch_async(writeQueue) {
                results.extend(remainder)
                dispatch_group_leave(group)
            }
        }
        
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER)
        
        return results
    }
    
    public static func Pipe<I : IndividualType>(#lhs: [I] -> [I], rhs: [I] -> [I])(pop:[I])->[I] {
        return (lhs >>> rhs)(pop)
    }
    
    public static func Split<I : IndividualType>(#amount: Double, lhs: [I] -> [I], rhs: [I] -> [I])(pop:[I])->[I] {
        let count = Int(floor(amount * Double(pop.count)))
        let left = Array(pop[0..<count])
        let right = Array(pop[count..<pop.count])
        
        let leftResult = lhs(left)
        let rightResult = rhs(right)
        
        return leftResult + rightResult
    }
}

@inline(__always) public func >>><I : IndividualType>(lhs: [I] -> [I], rhs: [I] -> [I])->(pop:[I])->[I] {
    return Operators.Pipe(lhs: lhs, rhs: rhs)
}

public protocol Mutatable : IndividualType {
    class func mutate(individual: Self) -> Self
}

public protocol Crossoverable : IndividualType {
    class func cross(parent1: Self, _ parent2: Self) -> [Self]
}