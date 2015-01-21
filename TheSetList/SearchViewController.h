//
//  SearchViewController.h
//  TheSetList
//
//  Created by Andrew Friedman on 1/18/15.
//  Copyright (c) 2015 Andrew Friedman. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SearchViewController : UIViewController <UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) IBOutlet UILabel *nameSpaceLabel;

@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
- (IBAction)exitButtonPressed:(UIButton *)sender;

@property (strong, nonatomic) NSArray *tracks;
@property (strong,nonatomic) NSString *roomCode; 

@end
