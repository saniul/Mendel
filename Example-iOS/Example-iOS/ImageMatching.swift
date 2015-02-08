//
//  ImageMatching.swift
//  genetic
//
//  Created by Saniul Ahmed on 04/01/2015.
//  Copyright (c) 2015 Saniul Ahmed. All rights reserved.
//

import Foundation
import QuartzCore
import ImageIO
import UIKit

import Mendel

public class ImageMatchingLab {
    var referenceImageURL: NSURL!
    var outputImageSize: CGSize?
    var output: ((CGImageRef, Int) -> Void)?
    
    var engine: SimpleEngine<Painting>?
    
    public init () {
    }
    
    func doScience() {
        var engine = SimpleEngine<Painting>(
            //125 triangles
            factory: { return Painting.arbitraryOfLength(125) },
            evaluation: distanceFromTargetImageAtURL(self.referenceImageURL),
            fitnessKind: FitnessKind.Inverted,
            selection: Selections.RouletteWheel,
            //Mutation is at 100%, since we control the by-gene probabilities
            //at the individual level
            op: Operators.Parallel(batchSize: 10)(Operators.Crossover(0.5) >>> Operators.Mutation(1))
        )
        self.engine = engine
        
        var config = Configuration()
        config.size = 100
        config.eliteCount = 1
        
        engine.config = config
        
        //Never terminate
        engine.termination = { _ in return false }
        
        engine.iteration = { data in
            let best = data.bestCandidate
            
            if let size = self.outputImageSize {
                self.output?(best.imageOfSize(size), data.iterationNum)
            }
        }
        
        engine.evolve()
    }
    
    func stop() {
        self.engine?.termination = { _ in return true }
        self.engine = nil
    }
}

//MARK: Structures

struct Painting : IndividualType {
    let genes: [Gene]
    
    init(_ genes: [Gene]) {
        self.genes = genes
    }
    
    func drawInContext(context: CGContextRef, size: CGSize) {
        CGContextSetFillColorWithColor(context, UIColor.blackColor().CGColor)
        CGContextFillRect(context, CGRect(origin: CGPointZero, size: size))
        for gene in self.genes {
            gene.drawInContext(context, size: size)
        }
    }
}

struct Gene {
    let color: Color
    let triangle: Triangle
    
    func drawInContext(context: CGContextRef, size: CGSize) {
        //        CGContextSaveGState(context)
        CGContextSetRGBFillColor(context, CGFloat(color.r)/255, CGFloat(color.g)/255, CGFloat(color.b)/255, CGFloat(color.a)/255)
        triangle.drawInContext(context, size:size)
        //        CGContextRestoreGState(context)
    }
}

struct Color {
    let r,g,b,a: UInt8
}

struct Triangle {
    let a: CGPoint
    let b: CGPoint
    let c: CGPoint
    
    func drawInContext(context: CGContextRef, size: CGSize) {
        let sA = self.a.scaledUnitPoint(size)
        let sB = self.b.scaledUnitPoint(size)
        let sC = self.c.scaledUnitPoint(size)
        
        //        CGContextSaveGState(context);
        CGContextMoveToPoint(context, sA.x, sA.y);
        CGContextAddLineToPoint(context, sB.x, sB.y);
        CGContextAddLineToPoint(context, sC.x, sC.y);
        CGContextClosePath(context);
        CGContextFillPath(context);
        //        CGContextRestoreGState(context);
    }
}

extension CGPoint {
    func scaledUnitPoint(size:CGSize) -> CGPoint {
        return CGPoint(x: self.x*size.width, y: self.y*size.height)
    }
}

//MARK: Crossover and Mutation

//TODO: Generalize finite sequence based crossover
extension Painting : Crossoverable {
    static func cross(parent1: Painting, _ parent2: Painting) -> [Painting] {
        let wordA = parent1.genes
        let wordB = parent2.genes
        
        var count = countElements(wordA)
        var p1 = Int(arc4random_uniform(UInt32(count)))
        var p2 = Int(arc4random_uniform(UInt32(count)))
        if (p1 > p2) {
            swap(&p1, &p2)
        }
        
        let subRange = Range<Int>(start: p1, end: p2)
        var childB = wordB
        childB.replaceRange(subRange, with: wordA[subRange])
        var childA = wordA
        childA.replaceRange(subRange, with: wordB[subRange])
        
        return [self(childA), self(childB)]
    }
}

//TODO: Generalize finite sequence based mutation
extension Painting : Mutatable {
    static func mutate(individual:Painting) -> Painting {
        var dna = [Gene]()
        dna.reserveCapacity(individual.genes.count)
        for gene in individual.genes {
            if roll(0.1) {
                dna.append(Gene.mutate(gene))
            } else {
                dna.append(gene)
            }
        }
        
        return Painting(dna)
    }
}

extension Gene : Mutatable {
    @inline(__always) static func mutate(individual: Gene) -> Gene {
        let color = roll(0.1) ? Color.mutate(individual.color) : Color.drift(individual.color)
        let triangle = roll(0.1) ? Triangle.mutate(individual.triangle) : Triangle.drift(individual.triangle)
        
        return Gene(color: color, triangle: triangle)
    }
}

extension Color {
    @inline(__always) static func mutate(individual: Color) -> Color {
        let mR = UInt8.arbitrary()
        let mG = UInt8.arbitrary()
        let mB = UInt8.arbitrary()
        let mA = UInt8.arbitrary()
        
        return Color(r: mR, g: mG, b: mB, a: mA)
    }
    
    @inline(__always) static func drift(individual: Color) -> Color {
        let op : (UInt8, UInt8)->UInt8 = coinFlip() ? (&+) : (&-)
        
        let mR = op(individual.r, 1)
        let mG = op(individual.g, 1)
        let mB = op(individual.b, 1)
        let mA = op(individual.a, 1)
        
        return Color(r: mR, g: mG, b: mB, a: mA)
    }
}

extension Triangle {
    @inline(__always) static func arbitrary() -> Triangle {
        return Triangle(a: CGPoint.randomUnit(), b: CGPoint.randomUnit(), c: CGPoint.randomUnit())
    }
}

extension Triangle {
    @inline(__always) static func mutate(individual:Triangle) -> Triangle {
        let mA = CGPoint.randomUnit()
        let mB = CGPoint.randomUnit()
        let mC = CGPoint.randomUnit()
        
        return Triangle(a: mA, b: mB, c: mC)
    }
    
    @inline(__always) static func drift(individual: Triangle) -> Triangle {
        let mA = CGPoint.drift(individual.a)
        let mB = CGPoint.drift(individual.b)
        let mC = CGPoint.drift(individual.c)
        
        return Triangle(a: mA, b: mB, c: mC)
    }
}

extension CGPoint {
    @inline(__always) static func drift(individual: CGPoint) -> CGPoint {
        let op : (CGFloat, CGFloat)->CGFloat = coinFlip() ? (+) : (-)
        
        let newPoint = CGPoint(x: min(1.5,max(-0.5,op(individual.x, 0.01))), y: min(1.5,max(-0.5,op(individual.y, 0.01))))
        return newPoint
    }
}

// MARK: Fitness calculation

struct Pixel {
    let red: UInt8
    let blue: UInt8
    let green: UInt8
    let alpha: UInt8
}

private func distance(a: Pixel, b: Pixel) -> Fitness {
    let r = Fitness(a.red) - Fitness(b.red)
    let g = Fitness(a.green) - Fitness(b.green)
    let b = Fitness(a.blue) - Fitness(b.blue)
    
    return r*r + g*g + b*b
}

private func distanceFromTargetImageAtURL(imageURL: NSURL) -> (Painting, [Painting]) -> Fitness {
    let dataProvider = CGDataProviderCreateWithURL(imageURL)
    let options = [
        (kCGImageSourceThumbnailMaxPixelSize as NSString): 75 as CFNumberRef,
        (kCGImageSourceCreateThumbnailFromImageIfAbsent as NSString): true
    ]
    
    let imageSource = CGImageSourceCreateWithDataProvider(dataProvider, options)
    
    var count = CGImageSourceGetCount(imageSource)
    
    let targetImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options)!
    let img = UIImage(CGImage: targetImage)!
    
    let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGBitmapInfo(CGImageAlphaInfo.NoneSkipLast.rawValue)
    let width = targetImage.width
    let height = targetImage.height
    let bytesPerRow = width * 4
    
    let length = Int(width)*Int(height)

    let buffer = UnsafeMutablePointer<Pixel>.alloc(length)
    let targetcontext = CGBitmapContextCreate(buffer, width, height, 8, bytesPerRow, colorSpace, bitmapInfo)
    CGContextSetFillColorWithColor(targetcontext, UIColor.blackColor().CGColor)
    CGContextDrawImage(targetcontext, CGRect(origin: CGPointZero, size: targetImage.size), targetImage)
    
    let distance = distanceFromTargetImageData(buffer, withSize: targetImage.size)
    
    return distance
}

private func distanceFromTargetImageData(targetData: UnsafeMutablePointer<Pixel>, withSize size: CGSize) -> (Painting, [Painting]) -> Fitness {
    return { painting, _ in
        let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(CGImageAlphaInfo.NoneSkipLast.rawValue)
        let width = Int(size.width)
        let height = Int(size.height)
        let bytesPerRow = UInt(width) * 4
        
        let context = CGBitmapContextCreate(nil, UInt(width), UInt(height), 8, bytesPerRow, colorSpace, bitmapInfo)
//        CGContextSetShouldAntialias(context, false);
        painting.drawInContext(context, size: size)
        
        var data = unsafeBitCast(CGBitmapContextGetData(context), UnsafeMutablePointer<Pixel>.self)
        
        var sum = 0.0
        for var y = 0; y < height; ++y {
            for var x = 0; x < width; ++x {
                let targetpx = targetData[Int(x + y * width)]
                let px = data[Int(x + y * width)]
                let dist = distance(targetpx, px)
                sum += dist
            }
        }
        
        
        return sqrt(sum)
    }
}

//MARK: Rendering

extension Painting {
    func imageOfSize(size: CGSize) -> CGImageRef {
        let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(CGImageAlphaInfo.NoneSkipLast.rawValue)
        let width = UInt(size.width)
        let height = UInt(size.height)
        let bytesPerRow = UInt(width) * 4
        let context = CGBitmapContextCreate(nil, width, height, 8, bytesPerRow, colorSpace, bitmapInfo)
//        CGContextSetShouldAntialias(context, false);
        self.drawInContext(context, size: size)
        return CGBitmapContextCreateImage(context)
    }
}

//MARK: Random/Arbitrary Instances

extension Painting {
    static func arbitraryOfLength(length: Int) -> Painting {
        let dna : [Gene] = (0..<length).map { _ in
            return Gene.arbitrary()
        }
        
        return self(dna)
    }
}

extension Gene {
    @inline(__always) static func arbitrary() -> Gene {
        let color = Color.arbitrary()
        let triangle = Triangle.arbitrary()
        
        return self(color: color, triangle: triangle)
    }
}

extension Color {
    @inline(__always) static func arbitrary() -> Color {
        return Color(r: UInt8.arbitrary(), g: UInt8.arbitrary(), b: UInt8.arbitrary(), a: UInt8.arbitrary())
    }
}

extension UInt8 {
    @inline(__always) static func arbitrary() -> UInt8 {
        return UInt8(arc4random_uniform(UInt32(UInt8.max)))
    }
}

extension CGFloat {
    @inline(__always) static func random(#from:CGFloat, to: CGFloat) -> CGFloat {
        return from + (to-from)*(CGFloat(arc4random()) / CGFloat(UInt32.max))
    }
    
    @inline(__always) static func randomUnit() -> CGFloat {
        return self.random(from: 0, to: 1)
    }
}

extension CGPoint {
    @inline(__always) static func random(#from:CGFloat, to: CGFloat) -> CGPoint {
        return CGPoint(x: CGFloat.random(from: from, to: to), y: CGFloat.random(from: from, to: to))
    }
    
    @inline(__always) static func randomUnit() -> CGPoint {
        return self.random(from: -0.5, to: 1.5)
    }
}

//MARK: Utilities

extension CGImageRef {
    var size: CGSize {
        return CGSize(width: CGFloat(CGImageGetWidth(self)), height: CGFloat(CGImageGetHeight(self)))
    }
    
    var height: UInt {
        return CGImageGetHeight(self)
    }
    
    var width: UInt {
        return CGImageGetWidth(self)
    }
}