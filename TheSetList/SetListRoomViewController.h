//
//  SetListRoomViewController.h
//  
//
//  Created by Andrew Friedman on 1/14/15.
//
//

#import <UIKit/UIKit.h>
#import "SetListTableViewCell.h"

@interface SetListRoomViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, SetListCellDelegate>
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UILabel *currentSongLabel;
@property (strong, nonatomic) IBOutlet UILabel *currentArtistLabel;
@property (strong, nonatomic) IBOutlet UILabel *nameSpaceLabel;
@property (strong, nonatomic) IBOutlet UIImageView *currentAlbumArtImage;
@property (strong, nonatomic) IBOutlet UILabel *nextLabel;
@property (strong, nonatomic) IBOutlet UIView *setListView;
@property (strong, nonatomic) NSArray *tracks;
@property (strong, nonatomic) IBOutlet UIView *setListBackgroundView;
@property (strong, nonatomic) NSString *roomCode;

@property (strong, nonatomic) IBOutlet UIView *searchBackgroundView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *searchViewVertConst;
@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) IBOutlet UIButton *plusButton;
@property (strong, nonatomic) IBOutlet UITableView *searchTableView;
@property (strong, nonatomic) NSArray *searchTracks;
@property (strong, nonatomic) IBOutlet UIView *searchView;

- (IBAction)displaySearchViewButtonPressed:(UIButton *)sender;

@end
