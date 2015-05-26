//
//  genetic.swift
//  genetic
//
//  Created by Saniul Ahmed on 22/12/2014.
//  Copyright (c) 2014 Saniul Ahmed. All rights reserved.
//

import Foundation

//MARK: Core Types

//Types of individuals to be evolved have to conform to this type
public protocol IndividualType {
}

//The Genetic Engine protocol
public protocol Engine {
    //The type that's being evolved
    typealias Individual : IndividualType
    //A collection of Individuals
    typealias Population = [Individual]
    //A collection of Individuals and their respective fitness scores
    typealias EvaluatedPopulation = [Score<Individual>]
    
    //MARK: Core function types
    
    //Used to instantiate a new arbitrary Individual
    typealias Factory = () -> Individual
    
    //Used to ge a fitness score for an Individual in a given Population
    typealias Evaluation = (Individual, Population) -> Fitness
    
    //Selection Function - used to select the next iteration's Population from
    //the current EvaluatedPopulation
    typealias Selection = (EvaluatedPopulation, FitnessKind, Int) -> Population
    
    //The Genetic Operator that is going to be called to modify the selected Population
    typealias Operator = Population -> Population
    
    //Termination predicate. When it returns yes, the evolution process is stopped
    typealias Termination = IterationData<Individual> -> Bool
    
    ////////////////////////////////////////////////////////////////////////////
    
    var fitnessKind: FitnessKind { get }
    
    var factory: Factory { get }
    
    var evaluation: Evaluation { get }
    
    var selection: Selection { get }
    
    var op: Operator { get }
    
    var termination: Termination? { get }
    
    //Called after each evolution step. Useful to update UI/inform user.
    var iteration: (IterationData<Individual> -> Void)? { get }
    
    //Starts the evolution process. This is a blocking call, it won't return until
    //`termination` returns true – make sure you aren't blocking UI.
    func evolve() -> Individual
}

//Represents the relationship between two fitness values
//Defines whether a greater Fitness value should be considered better or worse
public enum FitnessKind {
    case Natural
    case Inverted
    
    var comparisonOp:(lhs: Fitness, rhs: Fitness) -> Bool {
        switch self {
        case .Natural :
            return (>)
        case .Inverted:
            return (<)
        }
    }
    
    func adjustedFitness(fitness: Fitness) -> Fitness {
        switch self {
        case .Natural:
            return fitness
        case .Inverted:
            if fitness == 0 {
                return Double.infinity
            } else {
                return 1.0/fitness
            }
        }
    }
}

public typealias Fitness = Double
//Represents an evaluated individual
public struct Score<Individual : IndividualType> : Printable {
    let fitness: Fitness
    let individual: Individual
    
    public var description: String {
        return "\(self.individual):\(self.fitness)"
    }
    
    func fitterIndividual(fitnessKind:FitnessKind, other: Score<Individual>) -> Individual {
        if fitnessKind.comparisonOp(lhs: self.fitness, rhs: other.fitness) {
            return self.individual
        } else {
            return other.individual
        }
    }
}

//Provides various stats regarding the current state of evolution
public struct IterationData<I : IndividualType> : Printable {
    init(iterationNum: Int, pop:[Score<I>], fitnessKind: FitnessKind, config: Configuration) {
        self.iterationNum = iterationNum
        
        let bestScore = pop.first!
        
        self.bestCandidate = bestScore.individual
        self.bestCandidateFitness = bestScore.fitness
        
        let stats = Stats(pop.map { $0.fitness })
        
        self.fitnessMean = stats.arithmeticMean
        self.fitnessStDev = stats.stdev
        
        self.fitnessKind = fitnessKind
    }
    
    public let iterationNum: Int
    
    public let bestCandidate: I
    public let bestCandidateFitness: Fitness
    
    public let fitnessMean: Fitness
    public let fitnessStDev: Fitness
    
    public let fitnessKind: FitnessKind
    
    public var description: String {
        return "#\(iterationNum):\(bestCandidate)"
    }
}

//MARK: Genetic Engine helper functions
//These can be used by various concrete implementations of the Engine protocol

//Generates an initial population using the provided factory function
public func primordialSoup<I : IndividualType>(size: Int, factory:()->I) -> [I] {
    return (0..<size).map { _ -> I in
        factory()
    }
}

//Evaluates the population using the provided evaluation function
//This used to be a nice little function but got really ugly after being modified to
//support concurrent computation by partitioning the population
public func evaluatePopulation<I : IndividualType>(population: [I], withStride stride: Int, evaluation:(I, [I]) -> Fitness) -> [Score<I>] {
    let queue = dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)
    
    var scores = [Score<I>]()
    scores.reserveCapacity(population.count)
    
    let writeQueue = dispatch_queue_create("scores write queue", DISPATCH_QUEUE_SERIAL)
    
    let group = dispatch_group_create()
    
    //TODO: write this in a more swifty way
    let iterations = Int(population.count/stride)
    func evaluatePopulationClosure(idx: Int) -> (Void) {
        var j = Int(idx) * stride
        let j_stop = j + stride
        do {
            dispatch_group_enter(group)
            let ind = population[j]
            let fitness = evaluation(ind, population)
            dispatch_async(writeQueue) {
                scores.append(Score(fitness: fitness, individual: ind))
                dispatch_group_leave(group)
            }
            j++
        } while (j < j_stop);
    }
    dispatch_apply(iterations, queue, evaluatePopulationClosure)
    //handle the remainder
    dispatch_group_enter(group)
    dispatch_async(queue) {
        let startIdx = Int(iterations) * stride
        let remainder = lazy(population[startIdx..<population.count]).map { ind -> Score<I> in
            return Score(fitness: evaluation(ind, population), individual: ind)
        }
        dispatch_async(writeQueue) {
            scores.extend(remainder)
            dispatch_group_leave(group)
        }
    }
    
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER)
    
    return scores
}

//Sorts the evaluated population based on the provided fitness kind
public func sortEvaluatedPopulation<I : IndividualType>(population: [Score<I>], fitnessKind:FitnessKind) -> [Score<I>] {
    let sorted = population.sorted { return fitnessKind.comparisonOp(lhs: $0.fitness, rhs: $1.fitness) }
    
    let fitnesses = population.map { $0.fitness }
    
    return sorted
}

//MARK: Generational Engine

//A Simple generational genetic engine implementation
public class SimpleEngine<I : IndividualType> : Engine {
    
    //These type definitions have to be repeated here, even though we already
    //described them in Engine :( Not sure why...
    //TODO: find out why
    
    //MARK: Engine
    typealias Individual = I
    
    typealias Factory = () -> Individual
    
    typealias Population = [Individual]
    typealias EvaluatedPopulation = [Score<Individual>]
    
    typealias Evaluation = (Individual, Population) -> Fitness
    typealias Operator = Population -> Population
    typealias Selection = (EvaluatedPopulation, FitnessKind, Int) -> Population
    
    typealias Termination = IterationData<Individual> -> Bool
    
    public let factory: Factory
    public let fitnessKind: FitnessKind
    public let selection: Selection
    public let op: Operator
    
    public let evaluation: Evaluation
    
    public var termination: Termination?
    
    public var iteration: (IterationData<Individual> -> Void)?
    
    ////////////////////////////////////////////////////////////////////////////
    
    public init(factory: Factory,
        evaluation: Evaluation,
        fitnessKind: FitnessKind,
        selection: Selection,
        op: Operator) {
            self.factory = factory
            self.evaluation = evaluation
            self.fitnessKind = fitnessKind
            self.selection = selection
            self.op = op
            self.config = Configuration()
    }
    
    public var config: Configuration
    
    //The core work function. This runs on the calling thread, blocking it
    //while the evolution is running.
    //TODO: Clean up the implementation (avoid repetition, more functional style...)
    public func evolve() -> Individual {
        let pop = primordialSoup(self.config.size, self.factory)
        
        var evaluatedPop = evaluatePopulation(pop, withStride:25, self.evaluation)
        var sortedEvaluatedPop = sortEvaluatedPopulation(evaluatedPop, self.fitnessKind)
        
        var iterationIdx = 0
        
        var data = IterationData(iterationNum: iterationIdx, pop: sortedEvaluatedPop, fitnessKind: self.fitnessKind, config: self.config)
        self.iteration?(data)
        
        while (self.termination == nil || self.termination!(data) == false) {
            evaluatedPop = step(sortedEvaluatedPop)

            sortedEvaluatedPop = sortEvaluatedPopulation(evaluatedPop, self.fitnessKind)
            
            iterationIdx++
            
            data = IterationData(iterationNum: iterationIdx, pop: sortedEvaluatedPop, fitnessKind: self.fitnessKind, config: self.config)
            self.iteration?(data)
        }
        
        return data.bestCandidate
    }
    
    //Evolution iteration logic
    func step(pop: EvaluatedPopulation) -> EvaluatedPopulation {
        let elites = map(pop[0..<self.config.eliteCount]) { $0.individual }
        
        let normalCount = pop.count - elites.count
        
        var selectedPop = self.selection(pop, self.fitnessKind, normalCount)

        //TODO: parametrize?
        while selectedPop.count < normalCount {
            selectedPop += Selections.Random(pop, fitnessKind: self.fitnessKind, count: normalCount - selectedPop.count)
        }
        
        var mutatedPop = self.op(Array(selectedPop[0..<selectedPop.count]))
        
        //TODO: parametrize?
        while mutatedPop.count < normalCount {
            mutatedPop.append(self.factory())
        }
        
        let newPop = elites + mutatedPop
        
        let newEvaluatedPop = evaluatePopulation(newPop, withStride:25, self.evaluation)
        
        return newEvaluatedPop
    }
}

//SimpleEngine parametrization
public struct Configuration {
    public init() {
    }
    
    public var size = 250
    public var eliteCount = 1
}