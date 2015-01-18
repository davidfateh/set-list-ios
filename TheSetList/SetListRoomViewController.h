//
//  SetListRoomViewController.h
//  
//
//  Created by Andrew Friedman on 1/14/15.
//
//

#import <UIKit/UIKit.h>

@interface SetListRoomViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIImageView *nextSongAlbumArtImage;
@property (strong, nonatomic) IBOutlet UILabel *nextSongLabel;
@property (strong, nonatomic) IBOutlet UILabel *currentSongLabel;
@property (strong, nonatomic) IBOutlet UILabel *currentArtistLabel;
@property (strong, nonatomic) IBOutlet UILabel *nameSpaceLabel;
@property (strong, nonatomic) IBOutlet UIImageView *currentAlbumArtImage;

@property (strong,nonatomic) NSArray *tracks; 

@end
