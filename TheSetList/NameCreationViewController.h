//
//  NameCreationViewController.h
//  TheSetList
//
//  Created by Andrew Friedman on 1/13/15.
//  Copyright (c) 2015 Andrew Friedman. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NameCreationViewController : UIViewController <UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UILabel *theSetListLabel;
@property (strong, nonatomic) IBOutlet UITextField *roomCodeTextField;
@property (strong, nonatomic) IBOutlet UIView *backgroundView;

- (IBAction)hostRoomButtonPressed:(UIButton *)sender;

@end
