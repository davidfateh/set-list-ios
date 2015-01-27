//
//  RadialGradiantView.m
//  TheSetList
//
//  Created by Andrew Friedman on 1/21/15.
//  Copyright (c) 2015 Andrew Friedman. All rights reserved.
//

#import "RadialGradiantView.h"

@implementation RadialGradiantView

- (void)drawRect:(CGRect)rect {
    
    //// General Declarations
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //// Color Declarations
    UIColor* gradientColor = [UIColor colorWithRed: 0.086 green: 0.086 blue: 0.086 alpha: 1];
    UIColor* gradientColor2 = [UIColor colorWithRed: 0.135 green: 0.135 blue: 0.135 alpha: 1];
    
    //// Gradient Declarations
    CGFloat gradientLocations[] = {0, 1};
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)@[(id)gradientColor.CGColor, (id)gradientColor2.CGColor], gradientLocations);
    
    //// Radial Gradiant Drawing
    UIBezierPath* radialGradiantPath = [UIBezierPath bezierPathWithRect: CGRectMake(0, 0, 320, 568)];
    CGContextSaveGState(context);
    [radialGradiantPath addClip];
    CGContextDrawRadialGradient(context, gradient,
                                CGPointMake(160, 284), 214.37,
                                CGPointMake(160, 284), 37.62,
                                kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
    CGContextRestoreGState(context);
    
    
    //// Cleanup
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);

}


@end
