//
//  SetListRoomViewController.h
//  
//
//  Created by Andrew Friedman on 1/14/15.
//
//

#import <UIKit/UIKit.h>
#import "SetListTableViewCell.h"

@interface SetListRoomViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, SetListCellDelegate, UITextFieldDelegate>

//SET LIST properties and methods. 
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UILabel *currentSongLabel;
@property (strong, nonatomic) IBOutlet UILabel *currentArtistLabel;
@property (strong, nonatomic) IBOutlet UIImageView *currentAlbumArtImage;
@property (strong, nonatomic) IBOutlet UIView *setListView;
@property (strong, nonatomic) NSArray *tracks;
@property (strong, nonatomic) IBOutlet UIView *currentArtistViewBackground;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *remoteLabelVertConst;
@property (strong, nonatomic) IBOutlet UILabel *emptyQueueLabel;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *remoteImageVertConst;
@property (strong, nonatomic) IBOutlet UIView *setListBackgroundView;
@property (strong, nonatomic) NSString *roomCode;

//SEARCH VIEW properties and methods
@property (strong, nonatomic) IBOutlet UIView *searchBackgroundView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *searchViewVertConst;
@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) IBOutlet UIButton *plusButton;
@property (strong, nonatomic) IBOutlet UITableView *searchTableView;
@property (strong, nonatomic) NSArray *searchTracks;
@property (strong, nonatomic) IBOutlet UIView *searchView;
@property (strong, nonatomic) IBOutlet UIImageView *purpleGlowImageView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *purpleGlowVertConst;
- (IBAction)displaySearchViewButtonPressed:(UIButton *)sender;



//HOST Properties and methods
@property (strong, nonatomic) IBOutlet UIButton *skipButton;
- (IBAction)playPauseButtonPressed:(UIButton *)sender;
- (IBAction)skipButtonPressed:(UIButton *)sender;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *setListTableViewHeightConst;
- (IBAction)setListlogoPressed:(UIButton *)sender;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *setListTableViewVertConst;
@property (strong, nonatomic) IBOutlet UIButton *playPauseButton;


//SETTINGS VIEW properties and methods
@property (strong, nonatomic) IBOutlet UIView *settingsView;
@property (strong, nonatomic) IBOutlet UITextField *remotePasswordTextField;
@property (strong, nonatomic) IBOutlet UIImageView *remoteImageView;
@property (strong, nonatomic) IBOutlet UIButton *exitSettingsViewButton;
@property (strong, nonatomic) IBOutlet UIView *whiteBorderView2;
@property (strong, nonatomic) IBOutlet UILabel *remotePasswordInfoLabel;
@property (strong, nonatomic) IBOutlet UILabel *roomCodeTextLabel;
@property (strong, nonatomic) IBOutlet UIView *whiteBorderView1;
@property (strong, nonatomic) IBOutlet UILabel *roomCodeLabel;
@property (strong, nonatomic) IBOutlet UIButton *leaveRoomButton;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *leaveRoomButtonVertConst;
- (IBAction)exitSettingsButtonPressed:(UIButton *)sender;
- (IBAction)leaveRoomButtonPressed:(UIButton *)sender;








@end
