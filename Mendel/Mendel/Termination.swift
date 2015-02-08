//
//  Termination.swift
//  genetic
//
//  Created by Saniul Ahmed on 20/01/2015.
//  Copyright (c) 2015 Saniul Ahmed. All rights reserved.
//

import Foundation

//MARK: Termination

public struct TerminationConditions {
    public static func NumberOfIterations<I : IndividualType>(maxNum: Int)(data:IterationData<I>) -> Bool {
        return data.iterationNum >= maxNum
    }
    
    public static func OnDate<I : IndividualType>(date: NSDate)(data:IterationData<I>) -> Bool {
        return NSDate().earlierDate(date) == date
    }
    
    public static func FitnessThreshold<I : IndividualType>(threshold: Fitness, fitnessKind: FitnessKind)(data:IterationData<I>) -> Bool {
        return fitnessKind.comparisonOp(lhs: data.bestCandidateFitness, rhs: threshold)
    }
    
    public static func ReferenceIndividual<I : IndividualType where I : Comparable>(reference: I)(data:IterationData<I>) -> Bool {
        return data.bestCandidate == reference
    }
    
    @inline(__always) public static func Or<I : IndividualType>(#lhs: ((data:IterationData<I>) -> Bool), rhs: ((data:IterationData<I>) -> Bool))(data:IterationData<I>) -> Bool {
        return lhs(data: data) || rhs(data: data)
    }
    
    @inline(__always) public static func And<I : IndividualType>(#lhs: ((data:IterationData<I>) -> Bool), rhs: ((data:IterationData<I>) -> Bool))(data:IterationData<I>) -> Bool {
        return lhs(data: data) && rhs(data: data)
    }
    
    //TODO: Figure out a nice way to pass down the number of iterations that haven't passed the test so far
    //    static func AverageFitnessStagnation<I : IndividualType>(stagnantIterationsThreshold: Int)(data:IterationData<I>) -> Bool {
    //        return false
    //    }
    
    //TODO: Figure out a nice way to pass down the number of iterations that haven't passed the test so far
    //    static func BestCandidateStagnation<I : IndividualType>(stagnantIterationsThreshold: Int)(data:IterationData<I>) -> Bool {
    //        return false
    //    }
}

@inline(__always) public func &&&<I : IndividualType>(lhs: ((data:IterationData<I>) -> Bool), rhs: ((data:IterationData<I>) -> Bool)) -> (IterationData<I>) -> Bool {
    return TerminationConditions.And(lhs: lhs, rhs: rhs)
}

@inline(__always) public func |||<I : IndividualType>(lhs: ((data:IterationData<I>) -> Bool), rhs: ((data:IterationData<I>) -> Bool)) -> (IterationData<I>) -> Bool {
    return TerminationConditions.Or(lhs: lhs, rhs: rhs)
}