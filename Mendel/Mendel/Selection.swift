//
//  Selection.swift
//  genetic
//
//  Created by Saniul Ahmed on 20/01/2015.
//  Copyright (c) 2015 Saniul Ahmed. All rights reserved.
//

import Foundation

public struct Selections {
    public static func Truncation<I : IndividualType>(truncationPoint: Double)(pop: [Score<I>], fitnessKind: FitnessKind, count: Int) -> [I] {
        let truncationCount = Int(floor(truncationPoint * Double(pop.count)))
        
        let slice = pop[0..<count]
        
        let result = Array(slice)
        
        return map(result) { $0.individual }
    }
    
    public static func Random<I : IndividualType>(pop: [Score<I>], fitnessKind: FitnessKind, count: Int) -> [I] {
        var selected = [I]()
        
        for _ in 0..<count {
            selected.append(pickRandom(from:pop).individual)
        }
        
        return selected
    }
    
    public static func Tournament<I : IndividualType>(size: Int)(pop: [Score<I>], fitnessKind: FitnessKind, count: Int) -> [I] {
        var selection = [I]()
        
        let sortLambda = { (a: Score<I>, b:Score<I>) -> Bool in
            return fitnessKind.comparisonOp(lhs: a.fitness, rhs: b.fitness)
        }
        
        iterateWhile({ return $0 < count }, 0) { i in
            let individuals = (0..<size).map { _ -> Score<I> in return pickRandom(from: pop) }
            let sorted = individuals.sorted(sortLambda)
            selection.append(sorted.first!.individual)
            
            return selection.count
        }
        
        return selection
    }
    
    public static func RouletteWheel<I : IndividualType>(pop: [Score<I>], fitnessKind: FitnessKind, count: Int) -> [I] {
        let fitnesses = pop.map { $0.fitness }
        
        let cumulative = scanl1(fitnesses) { acc, val -> Double in
            acc + fitnessKind.adjustedFitness(val)
        }
        
        var selection = [I]()
        
        while selection.count < count {
            let randomFitness = Double(randomP()) * cumulative.last!
            let idx = insertionPoint(fitnesses, randomFitness)
            selection.append(pop[idx].individual)
        }
        
        return selection
    }
    
    public static func StochasticUniversalSampling<I : IndividualType>(pop: [Score<I>], fitnessKind: FitnessKind, count: Int) -> [I] {
        let adjustedFitnesses = pop.map { score -> Fitness in
            return fitnessKind.adjustedFitness(score.fitness)
        }
        
        let sum = adjustedFitnesses.reduce(0, (+))
        
        let startOffset = Double(random(from: 0.0, to: 1.0))
        
        var cumulativeExpectation: Double = 0
        
        var idx = 0
        
        var selection = [I]()
        
        for score in pop {
            let adjusted = fitnessKind.adjustedFitness(score.fitness)
            cumulativeExpectation += adjusted / sum * Double(count)
            
            while (cumulativeExpectation > startOffset + Double(idx)) {
                selection.append(score.individual);
                idx++;
            }
        }
        
        return selection
    }
    
    public static func SigmaScaling<I : IndividualType>(pop: [Score<I>], fitnessKind: FitnessKind, count: Int) -> [I] {
        let fitnesses = pop.map { $0.fitness }
        
        let stats: Stats = Stats(fitnesses)
        
        let mean = stats.arithmeticMean
        let stdev = stats.stdev
        
        let scaledPop = pop.map { score -> Score<I> in
            let scaled = self.sigmaScaled(score.fitness, mean: mean, stdev: stdev)
            return Score<I>(fitness: scaled, individual: score.individual)
        }
        
        return StochasticUniversalSampling(scaledPop, fitnessKind: fitnessKind, count: count)
    }
    
    private static func sigmaScaled(fitness: Double, mean: Double, stdev: Double) -> Double {
        if stdev == 0 {
            return 1
        } else {
            let scaled = 1 + (fitness - mean) / (2 * stdev)
            return scaled > 0 ? scaled : 0.1
        }
    }
    
    public static func RankSelection<I : IndividualType>(pop: [Score<I>], fitnessKind: FitnessKind, count: Int) -> [I] {
        let mappedPop = map(enumerate(pop)) { idx, score -> Score<I> in
            return Score(fitness: self.rankMapped(idx+1, populationSize: pop.count), individual: score.individual)
        }
        
        return StochasticUniversalSampling(mappedPop, fitnessKind: fitnessKind, count: count)
    }
    
    private static func rankMapped(rank: Int, populationSize: Int) -> Double {
        return Double(populationSize - rank)
    }
}
