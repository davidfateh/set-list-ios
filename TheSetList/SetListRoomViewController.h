//
//  SetListRoomViewController.h
//  
//
//  Created by Andrew Friedman on 1/14/15.
//
//

#import <UIKit/UIKit.h>
#import "SetListTableViewCell.h"
#import <AVFoundation/AVFoundation.h>
#import "Constants.h"
#import <AVFoundation/AVFoundation.h>

@interface SetListRoomViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, SetListCellDelegate, UITextFieldDelegate, AVAudioPlayerDelegate>

//SET LIST properties and methods. 
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UILabel *currentSongLabel;
@property (strong, nonatomic) IBOutlet UILabel *currentArtistLabel;
@property (strong, nonatomic) IBOutlet UIImageView *currentAlbumArtImage;
@property (strong, nonatomic) IBOutlet UIView *setListView;
@property (strong, nonatomic) NSMutableArray *tracks;
@property (strong, nonatomic) IBOutlet UIView *currentArtistViewBackground;
@property (strong, nonatomic) IBOutlet UIView *setListBackgroundView;
@property (strong, nonatomic) NSString *roomCode;
@property (strong, nonatomic) NSString *UUIDString; 

//SEARCH VIEW properties and methods
@property (strong, nonatomic) IBOutlet UIView *searchBackgroundView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *searchViewVertConst;
@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) IBOutlet UIButton *plusButton;
@property (strong, nonatomic) IBOutlet UITableView *searchTableView;
@property (strong, nonatomic) NSMutableArray *searchTracks;
@property (strong, nonatomic) IBOutlet UIView *searchView;
@property (strong, nonatomic) IBOutlet UIImageView *purpleGlowImageView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *purpleGlowVertConst;
@property (strong, nonatomic) NSArray *trackArtworkURLs;
- (IBAction)displaySearchViewButtonPressed:(UIButton *)sender;



//HOST Properties and methods
@property (nonatomic) BOOL isHost;
@property (strong, nonatomic) IBOutlet UIProgressView *durationProgressView;
- (IBAction)playPauseButtonPressed:(UIButton *)sender;
- (IBAction)skipButtonPressed:(UIButton *)sender;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *setListTableViewHeightConst;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *setListTableViewVertConst;
@property (strong, nonatomic) IBOutlet UILabel *hostRoomCodeLabel;
@property (strong, nonatomic) IBOutlet UIImageView *skipImage;
@property (strong, nonatomic) IBOutlet UIImageView *playPauseImage;
@property (strong, nonatomic) IBOutlet UILabel *hostCodeMessageLabel;
@property (strong, nonatomic) NSMutableArray *hostQueue;
@property (strong, nonatomic) NSMutableDictionary *hostCurrentArtist;
@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) NSData *trackData;
@property (strong, nonatomic) IBOutlet UIButton *playButtonPressed;
@property (strong, nonatomic) IBOutlet UIButton *skipButtonPressed;


//MENU VIEW properties and methods
@property (strong, nonatomic) IBOutlet UIImageView *sliderImageView;
@property (strong, nonatomic) IBOutlet UIView *sliderView;
@property (strong, nonatomic) IBOutlet UIView *menuView;
@property (strong, nonatomic) IBOutlet UILongPressGestureRecognizer *longPressRec;
@property (strong, nonatomic) IBOutlet UIView *lineView1;
@property (strong, nonatomic) IBOutlet UIView *lineView2;
@property (strong, nonatomic) IBOutlet UILabel *remoteLabel;
@property (strong, nonatomic) IBOutlet UILabel *leaveLabel;
-(IBAction)handleLongPress:(UILongPressGestureRecognizer *)recognizer;

//REMOTE PASSWORD VIEW properties and methods
@property (strong, nonatomic) IBOutlet UIView *remoteCodeView;
@property (strong, nonatomic) IBOutlet UITextField *remoteTextField;
@property (strong, nonatomic) IBOutlet UILabel *remoteTextLabel;
@property (strong, nonatomic) IBOutlet UIImageView *exitRemotePlusImage;

- (IBAction)exitRemoteButtonPressed:(UIButton *)sender;




@end
