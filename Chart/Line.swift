//
//  AreaChart.swift
//  Chart
//
//  Created by Daher Alfawares on 5/9/16.
//  Copyright © 2016 Daher Alfawares. All rights reserved.
//

import UIKit

@IBDesignable class Line : UIView {
    
    // area view model
    class Model {
        var values : [Quote]
        
        init( values : [Quote] ){
            self.values = values
        }
    }
    
    class RangeCalculator {
        
        private var values  : [Quote]
        private var maximum : Double = 0
        private var minimum : Double = 999999999999
        private var start   : Date
        
        init(values : [Quote], start : Date){
            self.values = values
            self.start  = start
            
            //create the maximum.
            for value in values {
                
                if value.Date.timeIntervalSince(start) < 0 {
                    continue
                }
                
                // maximum
                if maximum < value.Close {
                    maximum = value.Close
                }
                
                if minimum > value.Close {
                    minimum = value.Close
                }
            }
        }
        
        func min()->Double { return minimum }
        func max()->Double { return maximum }
    }
    
    class Calculator {
        
        private var values  : [Quote]
        private var maximum : Double
        private var minimum : Double
        private var start   : Date
        
        init(values : [Quote], start : Date, min : Double, max : Double ){
            self.values  = values
            self.start   = start
            self.minimum = min
            self.maximum = max
        }
        
        func norms() -> [Double] {
            var norms : [Double] = []

            // each value
            for (_,value) in values.enumerated() {
                
                if value.Date.timeIntervalSince(start) < 0 {
                    continue
                }
                
                // set value
                norms.append((value.Close-minimum)/(maximum-minimum))
            }
            
            return norms
        }
    }
    
    @IBInspectable var fillColor   : UIColor = UIColor.black()
    @IBInspectable var strokeColor : UIColor = UIColor.black()
    
    override func draw(_ rect: CGRect) {
        
        guard let current = current else { return }
        fillColor.setFill()
        strokeColor.setStroke()
        
        let calculator = Calculator(values: current, start: start, min: minimum, max: maximum)
        let norms = calculator.norms()
        
       
        let width  = Double(rect.size.width )
        let height = Double(rect.size.height)
        
        // create path
        let path = UIBezierPath()
        // reset path position
        path.move(to: CGPoint(x: 0, y: Double(rect.size.height)))
        
        for (i,value) in norms.enumerated() {

            let x = width  * Double(i) / Double(norms.count-1)
            let y = height - Double(rect.size.height) * value
            
            path.addLine(to: CGPoint(x:x,y:y))
        }
        
        path.addLine(to: CGPoint(x: rect.size.width, y: rect.size.height))
        path.close()
        path.fill()
        path.stroke()
    }
    
    class AnimationCurve {
        private var target : Double
        private var origin : Double
        
        init( origin: Double, target: Double ){
            self.origin = origin
            self.target = target
        }
        
        func linear(dt:Double, duration:Double) -> Double {
            var r = Double( dt / duration )
            
            if r > 1 { r = 1 }
            if r < 0 { r = 0 }
            
            let Oi = Double(origin)
            let Ti = Double(target)
            
            let Vi = Oi + r * ( Ti - Oi )
            
        
            return Vi
        }
    }
    
    // Animations
    private var current             : [Quote]?
    private var start               : Date = Date()
    private var minimum             : Double = 0
    private var maximum             : Double = 0
    
    private var minAnimationCurve   : AnimationCurve!
    private var maxAnimationCurve   : AnimationCurve!
    private var startAnimationCurve : AnimationCurve!
    
    private var displayLink    : CADisplayLink!
    private var startTime      : TimeInterval = 0
    private var duration       : TimeInterval = 1
    
    func setValues(_ values:[Quote], animated:Bool, startFrom: Date){
        if animated, let _ = current {
            
            startAnimationCurve = AnimationCurve(origin: start.timeIntervalSince1970, target: startFrom.timeIntervalSince1970)
            minAnimationCurve   = AnimationCurve(origin: minimum, target: RangeCalculator(values: current!, start: startFrom).min())
            maxAnimationCurve   = AnimationCurve(origin: maximum, target: RangeCalculator(values: current!, start: startFrom).max())
            
            displayLink     = CADisplayLink(target: self, selector: #selector(Line.animateMe))
            startTime       = 0
            
            displayLink?.add(to: RunLoop.main, forMode: RunLoopMode.defaultRunLoopMode)
            
        } else {
            current   = values
            start     = startFrom
            minimum   = RangeCalculator(values: current!, start: startFrom).min()
            maximum   = RangeCalculator(values: current!, start: startFrom).max()
        }

        setNeedsDisplay()
    }
    
    func animateMe(){
        guard let _ = displayLink else { return }
        
        if startTime == 0 {
            startTime = (displayLink?.timestamp)!
            return
        }

        let t1 = self.startTime
        let t2 = displayLink.timestamp
        var dt = t2 - t1

        if dt > duration {
            displayLink?.invalidate()
            displayLink?.remove(from: RunLoop.main, forMode: RunLoopMode.defaultRunLoopMode)
            displayLink = nil
            
            // get a final accurate frame.
            dt = duration
        }

        let s = startAnimationCurve.linear(dt: dt, duration: duration)
        let m = minAnimationCurve.linear(dt: dt, duration: duration)
        let x = maxAnimationCurve.linear(dt: dt, duration: duration)
        
        start   = Date(timeIntervalSince1970: s)
        minimum = m
        maximum = x

        setNeedsDisplay()
    }
}


