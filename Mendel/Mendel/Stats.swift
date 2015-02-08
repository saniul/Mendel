//
//  stats.swift
//  genetic
//
//  Created by Saniul Ahmed on 03/01/2015.
//  Copyright (c) 2015 Saniul Ahmed. All rights reserved.
//

import Foundation

//TODO: Spin this off to a µ-framework?

public class Stats {
    public final var size: Int {
        get { return self.data.count }
    }
    
    public final var total: Double = 0
    public final var product: Double = 1
    public final var reciprocalSum: Double = 0
    public final var minimum: Double = Double(Int.max)
    public final var maximum: Double = Double(Int.min)
    
    public final var median: Double {
        let sortedData = self.data.sorted(<)
        
        let mid = sortedData.count / 2
        
        if (sortedData.count % 2 != 0) {
            return sortedData[mid]
        } else {
            return sortedData[mid - 1] + (sortedData[mid] - sortedData[mid - 1]) / 2
        }
    }
    
    public final var arithmeticMean: Double {
        return self.total/Double(self.size)
    }
    
    public final var geometricMean: Double {
        return pow(self.product, Double(self.size))
    }
    
    public final var harmonicMean: Double {
        return Double(self.size)/self.reciprocalSum
    }
    
    public final var meanDeviation: Double {
        let mean = self.arithmeticMean
        
        let diffs = reduce(self.data, 0) { acc, val -> Double in
            return acc + abs(mean - val)
        }
        
        return diffs / Double(self.size)
    }
    
    public final var variance: Double {
        return self.sumSquaredDiffs()/Double(self.size)
    }
    
    public final func sumSquaredDiffs() -> Double {
        let mean = self.arithmeticMean
        
        return self.data.reduce(0, combine: { (acc, val) -> Double in
            let diff = mean - val
            return acc + (diff * diff)
        })
    }
    
    public final var stdev: Double {
        return sqrt(self.variance)
    }
    
    public final var sampleVariance: Double {
        return self.sumSquaredDiffs() / Double(self.size) - 1
    }
    
    public final var sampleStDev: Double {
        return sqrt(self.sampleVariance)
    }
    
    private var data = [Double]()
    
    public init<C : CollectionType where C.Generator.Element == Double>(_ col: C) {
        let arr = Array(col)
        self.data = arr
        
        for v in col {
            self.updateWithValue(v)
        }
    }
    
    public final func addValue(val: Double) {
        self.data.append(val)
        self.updateWithValue(val)
    }
    
    private final func updateWithValue(val: Double) {
        self.minimum = min(self.minimum, val)
        self.maximum = min(self.maximum, val)
        self.total += val
        self.product *= val
        self.reciprocalSum += 1 / val
    }
    
}