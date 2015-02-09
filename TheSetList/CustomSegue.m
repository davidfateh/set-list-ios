//
//  CustomSegue.m
//  TheSetList
//
//  Created by Andrew Friedman on 2/8/15.
//  Copyright (c) 2015 Andrew Friedman. All rights reserved.
//

#import "CustomSegue.h"

@implementation CustomSegue
-(void) perform{
    [[[self sourceViewController] navigationController] pushViewController:[self   destinationViewController] animated:NO];
}
@end
