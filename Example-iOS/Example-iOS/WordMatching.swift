//
//  WordMatching.swift
//  genetic
//
//  Created by Saniul Ahmed on 04/01/2015.
//  Copyright (c) 2015 Saniul Ahmed. All rights reserved.
//

import Foundation

import Mendel

class WordMatchingLab {
    init() {
        
    }
    
    var engine: SimpleEngine<String>?
    
    var targetWord: String?
    
    var output: (IterationData<String> -> Void)?
    
    func doScience(target: String) {
        let targetWord = String(filter(target.uppercaseString) { character in
            let allASCII = reduce(String(character).unicodeScalars, true, { $0 && $1.value > 64 && $1.value < 90 } )
            return allASCII
            })
        
        self.targetWord = targetWord
        
        let length = count(targetWord)
        
        let engine = SimpleEngine<String>(
            factory: { return String.arbitraryOfLength(length) },
            evaluation: { str, _ in
                return distanceFromTargetWord(targetWord)(word: str)
            },
            fitnessKind: FitnessKind.Inverted,
            selection: Selections.RouletteWheel,
            op: Operators.Parallel(batchSize: 10)(op: Operators.Crossover(0.4) >>> Operators.Mutation(1))
        )
        
        engine.config.size = 100
        engine.config.eliteCount = 1
        engine.termination = TerminationConditions.NumberOfIterations(4000) ||| { $0.bestCandidate == targetWord }
        
        engine.iteration = self.output
        
        self.engine = engine
        
        let result = engine.evolve()
    }
    
    func stop() {
        self.engine?.termination = { _ in return true }
        self.engine = nil
    }
}

//MARK: Data structures

extension String : IndividualType {
}

extension String {
    var characters: [Character] {
        var result: [Character] = []
        for c in self {
            result += [c]
        }
        return result
    }
}

extension String : Mutatable {
    public static func mutate(individual: String) -> String {
        return drift(individual)
    }
    
    //by-letter drift
    static func drift(word: String) -> String {
        var characters = word.characters
        
        let from = Int(arc4random_uniform(UInt32(characters.count)))
        let charScalar = Int(lazy(String(characters[from]).unicodeScalars).first!.value)
        
        var newChar = coinFlip() ? charScalar + 1 : charScalar - 1
        if newChar > 89 {
            newChar = 0
        } else if newChar < 65 {
            newChar = 89
        }
        
        characters.replaceRange(Range(start:from, end: from+1), with: [Character(UnicodeScalar(newChar))])
        
        return String(characters)
    }
}

extension String : Crossoverable {
    public static func cross(parent1: String, _ parent2: String) -> [String] {
        let wordA = parent1.characters
        let wordB = parent2.characters
        
        var countA = count(wordA)
        var countB = count(wordB)
        
        if countA != countB {
            println("\(countA)!=\(countB)")
        }
        
        let c = countA
        var p1 = Int(arc4random_uniform(UInt32(c)))
        var p2 = Int(arc4random_uniform(UInt32(c)))
        if (p1 > p2) {
            swap(&p1, &p2)
        }
        
        let subRange = Range<Int>(start: p1, end: p2)
        var childB = wordB
        childB.replaceRange(subRange, with: wordA[subRange])
        var childA = wordA
        childA.replaceRange(subRange, with: wordB[subRange])
        
        return [String(childA), String(childB)]
    }
}

func distanceFromTargetWord(targetWord: String)(word: String) -> Fitness {
    let zip = Zip2(targetWord.unicodeScalars, word.unicodeScalars)
    
    func square(int:Int) -> Int { return int*int }
    
    let errors = lazy(zip).map { (targetScalar, actualScalar) -> Int in
        return Int(UInt8(targetScalar.value)) - Int(UInt8(actualScalar.value))
        }.map(square)
    
    let sum = reduce(errors, 0, +)
    
    return sqrt(Double(sum))
}

//MARK: Random/Arbitrary Instances

extension UnicodeScalar {
    static func arbitrary() -> UnicodeScalar {
        return UnicodeScalar(65+arc4random_uniform(90-65))
    }
}

extension Character {
    static func arbitrary() -> Character {
        return Character(UnicodeScalar.arbitrary())
    }
}

extension Int {
    static func arbitrary() -> Int {
        return Int(arc4random_uniform(UInt32.max))
    }
}

extension String {
    static func arbitrary() -> String {
        let length = Int.arbitrary()
        
        return self.arbitraryOfLength(length)
    }
    
    static func arbitraryOfLength(length: Int) -> String {
        let randomCharacters = tabulate(length) { _ in
            Character.arbitrary()
        }
        
        let result = reduce(randomCharacters, "") { $0 + String($1) }
        
        return result
    }
}

func tabulate<A>(times: Int, f: Int -> A) -> [A] {
    return (0..<times).map(f)
}
