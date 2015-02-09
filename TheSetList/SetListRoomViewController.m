//
//  SetListRoomViewController.m
//  
//
//  Created by Andrew Friedman on 1/14/15.
//
//

#import "SetListRoomViewController.h"
#import "SetListTableViewCell.h"
#import <SIOSocket/SIOSocket.h>
#import "SocketKeeperSingleton.h"
#import "RadialGradiantView.h"
#import "SetListTableViewCell.h"
#import <SCAPI.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <MediaPlayer/MPMediaItem.h>
#import <MediaPlayer/MPNowPlayingInfoCenter.h>
#import <MediaPlayer/MPMediaQuery.h>
#import "AsyncImageView.h"

#define CLIENT_ID @"40da707152150e8696da429111e3af39"

@interface SetListRoomViewController ()
@property (strong, nonatomic) NSString *socketID;
@property (nonatomic) BOOL plusButtonIsSelected;
@property (strong, nonatomic) NSMutableIndexSet *selectedRows;
@property (strong, nonatomic) UIVisualEffectView *blurEffectView;
@property (strong, nonatomic) SIOSocket *socket;
@property (strong, nonatomic) NSDictionary *currentArtist;
@property (nonatomic) BOOL isRemoteHost;
@property (strong, nonatomic) NSTimer *timer;
@property (strong, nonatomic) NSMutableDictionary *dicForInfoCenter;
@property (nonatomic) BOOL remoteLabelPushed;
@property (nonatomic) BOOL remoteLabelSelected;
@property (nonatomic) BOOL leaveLabelPushed;
@property (nonatomic) BOOL leaveLabelSelected;
@end

@implementation SetListRoomViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    RadialGradiantView *radiantBackgroundView = [[RadialGradiantView alloc] initWithFrame:self.view.bounds];
    [self.setListBackgroundView addSubview:radiantBackgroundView];
    
    [[UIApplication sharedApplication]setStatusBarStyle:UIStatusBarStyleLightContent];
    
    //Set the text on the search bar to white.
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setTextColor:[UIColor whiteColor]];
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setKeyboardAppearance:UIKeyboardAppearanceDark];
    
    self.exitSettingsViewButton.transform = CGAffineTransformMakeRotation(M_PI/4);
    
    //Set the remotePasswords textfield font colors etc.
    [self.remotePasswordTextField setValue:[UIColor colorWithRed:0.325 green:0.313 blue:0.317 alpha:1] forKeyPath:@"_placeholderLabel.textColor"];
    self.remotePasswordTextField.tintColor = [UIColor whiteColor];
    self.remotePasswordTextField.delegate = self;
    self.remotePasswordTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    
    //Set the delegates for the search view.
    self.searchBar.delegate = self;
    self.searchTableView.delegate = self;
    self.searchTableView.dataSource = self;
    
    
    //Set the tableview position and functionality for if the user is not the host. No space between header and tableViews
    self.setListTableViewHeightConst.constant = 294;
    self.setListTableViewVertConst.constant = 0;
    
    
    //set the delegates for the set list view. 
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    
    self.tableView.layoutMargins = UIEdgeInsetsZero;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    //Set the number of the namespace/roomCode. Sent from creation VC.
    self.roomCodeLabel.text = self.roomCode;
    
    //Set the UUID for the user
    self.UUIDString = [[NSUserDefaults standardUserDefaults]objectForKey:@"UUID"];
    
    self.searchTracks = [[NSMutableArray alloc]init];
    self.tracks = [[NSArray alloc]init];
    self.currentArtist = [[NSMutableDictionary alloc]init];
    self.hostCurrentArtist = [[NSMutableDictionary alloc]init];
    
    self.longPressRec.minimumPressDuration = 0;
    
    //Add a blur effect view in order to blur the background upon opening the search view.
    UIVisualEffect *blurEffect;
    blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIVisualEffectView *visualEffectView;
    visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    visualEffectView.frame = self.searchBackgroundView.bounds;
    visualEffectView.alpha = 0;
    [self.setListView addSubview:visualEffectView];
    self.blurEffectView = visualEffectView;
    
    UIImage *plusImage = [UIImage imageNamed:@"plusButton"];
    [self.plusButton setBackgroundImage:plusImage forState:UIControlStateHighlighted |UIControlStateSelected];
    
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
    
    self.socket = [[SocketKeeperSingleton sharedInstance]socket];
    self.socketID = [[SocketKeeperSingleton sharedInstance]socketID];
    
    NSString *roomCodeAsHost = [[SocketKeeperSingleton sharedInstance]hostRoomCode];
    /////////HOST/////////
    if ([[SocketKeeperSingleton sharedInstance]isHost]) {
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receiveHostSongAddedNotification:)
                                                     name:kQueueAdd
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receiveUserJoinedNotification:)
                                                     name:kUserJoined
                                                   object:nil];
        
        self.dicForInfoCenter = [[NSMutableDictionary alloc]init];
        NSLog(@"User is the host of this room");
        self.isHost = YES;
        [self viewForNoCurrentArtistAsHost];
        self.roomCodeLabel.text = roomCodeAsHost;
        
        if (!self.hostQueue) {
            self.hostQueue = [[NSMutableArray alloc]init];
        }
        if (!self.hostCurrentArtist) {
            self.hostCurrentArtist = [[NSMutableDictionary alloc]init];
        }
        
    }
    
    ///////NOT HOST///////
    else {
        // Add a notifcation observer and postNotification name for updating the tracks.
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receiveQueueUpdatedNotification:)
                                                     name:kQueueUpdated
                                                   object:nil];
        
        //Add a notifcation observer and postNotification name for updating current artist.
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receiveCurrentArtistUpdateNotification:)
                                                     name:kCurrentArtistUpdate
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receiveOnDisconnectNotification:)
                                                     name:kOnDisconnect
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receiveHostDisconnectNotification:)
                                                     name:kHostDisconnect
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receiveInitializeNotification:)
                                                     name:kInitialize
                                                   object:nil];
        
        if (!self.player)
        {
            self.player = [[AVPlayer alloc]init];
            self.player.allowsExternalPlayback = NO;
        }
        
        //Add some animations upon load up. Purple glow and tableview animation.
        double delay = .4;
        [self purpleGlowAnimationFromBottomWithDelay:&delay];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationBottom];
        
        //Set Current artist, if there is one.
        NSDictionary *currentArtist = [[SocketKeeperSingleton sharedInstance]currentArtist];
        [self setCurrentArtistFromCurrentArtist:currentArtist];
        
        
        //Set the current tracks, if there is one.
        NSArray *setListTracks = [[SocketKeeperSingleton sharedInstance]setListTracks];
        if (setListTracks) {
            self.tracks = setListTracks;
        }
    }
    
    self.setListView.alpha = 0;
    self.searchView.alpha = 0;
    
}
-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:YES];
    
    
    [UIView animateWithDuration:.5 delay:.35 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.searchView.alpha = 1;
        self.setListView.alpha = 1;
    } completion:^(BOOL finished) {
        //completed
    }];
    
    if (self.isHost){
        NSError *sessionError = nil;
        NSError *activationError = nil;
        [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error:&sessionError];
        [[AVAudioSession sharedInstance] setActive: YES error: &activationError];
        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
        [self becomeFirstResponder];
        NSLog(@"reciving remote control events and responder set");
    }
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:YES];
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [self resignFirstResponder];

}
-(BOOL)canBecomeFirstResponder
{
    return YES;
}

#pragma mark - Notification Center

-(void)receiveInitializeNotification:(NSNotification *)notificaiton
{
    NSLog(@"reconnected");
}

-(void)receiveUserJoinedNotification:(NSNotification *)notification
{
    NSString *userId = [[SocketKeeperSingleton sharedInstance]clientSocketID];
    
    if (self.hostCurrentArtist) {
        NSString *userId = [[SocketKeeperSingleton sharedInstance]clientSocketID];
        NSDictionary *argsCurrentDic = @{@"init":userId, @"data":self.hostCurrentArtist};
        NSArray *argsCurrentArray = @[argsCurrentDic];
        [self.socket emit:kCurrentArtistChange args:argsCurrentArray];
        
    }
    if (self.hostQueue) {
        
        NSDictionary *argsQueueDic = @{@"init" : userId, @"data" : self.hostQueue};
        NSArray *argsQueueArray = @[argsQueueDic];
        [self.socket emit:kQueueChange args:argsQueueArray];
        
    }
    
}

-(void)receiveHostSongAddedNotification:(NSNotification *)notification
{
    
    UIImage *pauseButtonImage = [UIImage imageNamed:@"Pause"];
    if (!self.hostRoomCodeLabel.hidden) {
        self.hostRoomCodeLabel.hidden = YES;
        self.hostCodeMessageLabel.hidden = YES;
    }

   NSDictionary *songAdded = [[SocketKeeperSingleton sharedInstance]songAdded];
    //if there is a current artist, add the song to the queue, else, make it the current artist.
    if ([self.hostCurrentArtist objectForKey:@"user"]) {
        
        [self.hostQueue addObject:songAdded];
        [self.tableView reloadData];
        //Emit the added song so the client can recieve it.
        NSArray *queueArray = @[self.hostQueue];
        [self.socket emit:kQueueChange args:queueArray];
        
    }
    //else, if there isnt a current artist, add the song as current artist.
    else
    {
        self.hostCurrentArtist = [songAdded mutableCopy];
        NSDictionary *songAddedForCurrent = self.hostCurrentArtist;
        [self setCurrentArtistFromCurrentArtist:songAddedForCurrent];
        [self playCurrentArtist:self.hostCurrentArtist];
        NSArray *songAddedArray = @[songAddedForCurrent];
        //emit the song for other clients to recieve and add to their current.
        [self.socket emit:kCurrentArtistChange args:songAddedArray];
        
        //Unhide host capabilities
        self.playPauseButton.hidden = NO;
        self.skipButton.hidden = NO;
        self.skipButtonPressed.hidden = NO;
        self.playButtonPressed.hidden = NO;
        [self.playPauseButton setBackgroundImage:pauseButtonImage forState:UIControlStateNormal];
        self.setListTableViewVertConst.constant = 0;
        self.setListTableViewHeightConst.constant = 264;

    }
}


-(void)receiveHostDisconnectNotification:(NSNotification *)notification
{
    NSLog(@"host disconnected notification fired");
    [self disconnectSocketAndPopOut];
}

-(void)receiveOnDisconnectNotification:(NSNotification *)notification
{
    NSLog(@"onDisconnect notification fired");
}

-(void)receiveCurrentArtistUpdateNotification:(NSNotification *)notification
{
    
    if (!self.isHost) {
        NSDictionary *currentArtist = [[SocketKeeperSingleton sharedInstance]currentArtist];
        [self setCurrentArtistFromCurrentArtist:currentArtist];
    }
    
    
}

- (void)receiveQueueUpdatedNotification:(NSNotification *)notification
{
    NSLog(@"recieved update B notification");
    if (!self.isHost) {
        self.tracks = [[SocketKeeperSingleton sharedInstance]setListTracks];
        [self.tableView reloadData];
    }
}

#pragma mark - TableView Delegate and DataSource

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *ReusableIdentifier = @"Cell";
    SetListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ReusableIdentifier forIndexPath:indexPath];
    
    cell.delegate = self;
    if (tableView.tag == 1) {
        
        //tableview for if the user is the host.
        if (self.isHost) {
            
            NSDictionary *track = [self.hostQueue objectAtIndex:indexPath.row];
            NSString *songTitle = [track objectForKey:@"title"];
            NSString *artist = [[track objectForKey:@"user"]objectForKey:@"username"];
            cell.artistLabel.text = artist;
            cell.songLabel.text = songTitle;
            
        }
        //set list table for if user is not the host.
        else
        {
            NSDictionary *track = [self.tracks objectAtIndex:indexPath.row];
            
            if ([[track objectForKey:@"UUID"]isEqualToString:self.UUIDString]) {
                cell.userSelectedSongImageView.hidden = NO;
            }
            else
            {
                cell.userSelectedSongImageView.hidden = YES;
            }
            
            NSString *songTitle = [track objectForKey:@"title"];
            NSString *artist = [[track objectForKey:@"user"]objectForKey:@"username"];
            
            cell.artistLabel.text = artist;
            cell.songLabel.text = songTitle;
            
        }
  
        }
        //search table view
            else if (tableView.tag == 2)
        {
            // Configure the cell...
            
            NSDictionary *track = [self.searchTracks objectAtIndex:indexPath.row];
            
            cell.searchSongTitle.text = [track objectForKey:@"title"];
            
            NSString *artistName = [[track objectForKey:@"user"]objectForKey:@"username"];
            cell.searchArtist.text = artistName;
            
            //Format the tracks duration into a string and set the label.
            int duration = [[track objectForKey:@"duration"]intValue];
            NSString *durationString = [self timeFormatted:duration];
            cell.searchDurationLabel.text = durationString;
            
            
            //If there is no picture available. Adds a Custom picture.
            if ([[track objectForKey:@"artwork_url"] isEqual:[NSNull null]]){
                
                cell.searchAlbumArtImage.image = [UIImage imageNamed:@"noAlbumArt.png"];
                
            }
            else{
                NSURL *artworkURL = [NSURL URLWithString:track[@"artwork_url"] ];
                [cell.searchAlbumArtImage sd_setImageWithURL:artworkURL placeholderImage:[UIImage imageNamed:@"noAlbumArt.png"]];
                
            }
            //if the row is selected make sure the check mark is the background image. 
            UIImage *checkImage = [UIImage imageNamed:@"check.png"];
            UIImage *plusImage  = [UIImage imageNamed:@"plusButton"];
            
            if ([self.selectedRows containsIndex:indexPath.row]) {
                [cell.addSongPlusImageView setImage:checkImage];
            }
            else {
                [cell.addSongPlusImageView setImage:plusImage];
            }
            cell.tag = indexPath.row;
        }
    
    return cell;
}


-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView.tag == 1) {
        if (self.isHost) {
            return [self.hostQueue count];
        }
        else return [self.tracks count];
    }
    else return [self.searchTracks count];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self.searchBar resignFirstResponder];
}

#pragma mark - Search Bar Configuration

-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    self.trackArtworkURLs = nil;
    NSString *search = [self.searchBar.text stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    [SCRequest performMethod:SCRequestMethodGET
                  onResource:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.soundcloud.com/tracks?client_id=%@&q=%@&format=json",CLIENT_ID, search]]
             usingParameters:nil
                 withAccount:nil
      sendingProgressHandler:nil
             responseHandler:^(NSURLResponse *response, NSData *data, NSError *error)
     {
         
         NSError *jsonError;
         NSJSONSerialization *jsonResponse = [NSJSONSerialization
                                              JSONObjectWithData:data
                                              options:0
                                              error:&jsonError];
         
         if (!jsonError && [jsonResponse isKindOfClass:[NSArray class]])
         {
             NSMutableArray *responseArray = [jsonResponse mutableCopy];
             NSMutableIndexSet *indexesToDelete = [NSMutableIndexSet indexSet];
             NSUInteger currentIndex = 0;
             for (NSDictionary *track in responseArray) {
                 if ([track objectForKey:@"streamable"] == [NSNumber numberWithBool:false]) {
                     [indexesToDelete addIndex:currentIndex];
                 }
                 currentIndex++;
             }
             [responseArray removeObjectsAtIndexes:indexesToDelete];
             self.searchTracks = responseArray;
             [self.searchTableView reloadData];
             //create a new indexset so that the tableview displays new plus images.
             self.selectedRows =[NSMutableIndexSet new];
         }
     }];
    
    
}

-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    self.searchBar.text = nil;
    self.searchTracks = nil;
    [self.searchTableView reloadData];
    [searchBar resignFirstResponder];
}

#pragma mark - Menu View and Gesture Recognizer Methods

-(IBAction)handleLongPress:(UILongPressGestureRecognizer *)recognizer
{
    recognizer.minimumPressDuration = 0;
    UIImage *sliderImage = [UIImage imageNamed:@"slider.png"];
    UIImage *menuImage = [UIImage imageNamed:@"menu-button.png"];
    self.menuView.alpha = 0;
    self.menuView.hidden = NO;
    self.searchView.hidden = YES;
    self.searchView.alpha = 0;
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        [UIView animateWithDuration:.3 animations:^{
            [self.sliderImageView setImage:sliderImage];
            self.blurEffectView.alpha = 1;
            self.menuView.alpha = 1;
            self.sliderImageView.center = CGPointMake(18 , 40);
            [self.sliderImageView setTransform:CGAffineTransformMakeScale(2.5f, 2.5f)];
        } completion:^(BOOL finished) {
        }];
    }
    else if (recognizer.state == UIGestureRecognizerStateChanged)
    {
        self.menuView.alpha = 1;
        self.menuView.hidden = NO;
        UIView *view = recognizer.view;
        CGPoint point = [recognizer locationInView:view];
        CGFloat sliderLoc = (self.sliderView.frame.origin.y + point.y) - (self.sliderView.frame.size.width / 2);
        [self.sliderView setFrame:CGRectMake(self.sliderView.frame.origin.x,
                                             sliderLoc,
                                             self.sliderView.frame.size.width,
                                             self.sliderView.frame.size.height)];
        
        CGFloat line1Loc = (self.sliderView.frame.origin.y - 595);
        [self.lineView1 setFrame:CGRectMake(self.lineView1.frame.origin.x,
                                            line1Loc,
                                            self.lineView1.frame.size.width,
                                            self.lineView1.frame.size.height)];
        CGFloat line2Loc = (self.sliderView.frame.origin.y + 75);
        [self.lineView2 setFrame:CGRectMake(self.lineView2.frame.origin.x,
                                            line2Loc,
                                            self.lineView2.frame.size.width,
                                            self.lineView2.frame.size.height)];
        
        
        if ((recognizer.view.center.y + point.y)>226 && (recognizer.view.center.y + point.y)<273) {
            
            [UIView animateWithDuration:.25 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
                [self.remoteLabel setFrame:CGRectMake(141, 236, 60, 20)];
                self.remoteLabel.alpha = 1;
                self.remoteLabelPushed = YES;
            } completion:^(BOOL finished) {
                //completion
            }];
        }
        else
        {
            if (self.remoteLabelPushed) {
                [UIView animateWithDuration:.25 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
                    [self.remoteLabel setFrame:CGRectMake(181, 236, 60, 20)];
                    self.remoteLabel.alpha = .5;
                    self.remoteLabelPushed = NO;
                } completion:^(BOOL finished) {
                    //completion
                }];
                
            }
        }
        
        if ((recognizer.view.center.y + point.y)>392 && (recognizer.view.center.y + point.y)<442) {
            
            [UIView animateWithDuration:.25 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
                [self.leaveLabel setFrame:CGRectMake(155,410, 46, 21)];
                self.leaveLabel.alpha = 1;
                self.leaveLabelPushed = YES;
            } completion:^(BOOL finished) {
                //completion
            }];
        }
        else
        {
            if (self.leaveLabelPushed) {
                [UIView animateWithDuration:.25 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
                    [self.leaveLabel setFrame:CGRectMake(195,410, 46, 21)];
                    self.leaveLabel.alpha = .5;
                    self.leaveLabelPushed = NO;
                } completion:^(BOOL finished) {
                    //completion
                }];
                
            }
        }
        
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded)
    {
        self.searchView.hidden = NO;
        self.purpleGlowImageView.alpha = 0;
        [UIView animateWithDuration:.3 animations:^{
            [self.sliderView setFrame:CGRectMake(263,
                                                 20,
                                                 self.sliderView.frame.size.width,
                                                 self.sliderView.frame.size.height)];
            
            CGFloat line1Loc = (self.sliderView.frame.origin.y - 595);
            [self.lineView1 setFrame:CGRectMake(self.lineView1.frame.origin.x,
                                                line1Loc,
                                                self.lineView1.frame.size.width,
                                                self.lineView1.frame.size.height)];
            CGFloat line2Loc = (self.sliderView.frame.origin.y + 75);
            [self.lineView2 setFrame:CGRectMake(self.lineView2.frame.origin.x,
                                                line2Loc,
                                                self.lineView2.frame.size.width,
                                                self.lineView2.frame.size.height)];
            
            self.blurEffectView.alpha = 0;
            self.sliderImageView.alpha = .2;
            self.menuView.alpha = 0;
            [self.sliderImageView setTransform:CGAffineTransformMakeScale(1.0, 1.0)];
            self.sliderImageView.center = CGPointMake(30 , 25);
            self.searchView.alpha = 1;
        } completion:^(BOOL finished) {
            double time = 0;
            [self purpleGlowAnimationFromBottomWithDelay:&time];
            self.sliderImageView.alpha = 1;
            self.menuView.hidden = YES;
            [self.sliderImageView setImage:menuImage];
        }];
        
    }

}

#pragma mark - Custom Buttons

- (IBAction)displaySearchViewButtonPressed:(UIButton *)sender {
    if (!self.plusButtonIsSelected) {
        self.purpleGlowImageView.alpha = 0;
        self.sliderView.hidden = YES;
        [self.purpleGlowImageView.layer setAffineTransform:CGAffineTransformMakeScale(1, -1)];
        self.purpleGlowVertConst.constant = -189;
        self.plusButton.transform = CGAffineTransformMakeRotation(M_PI/4);
        [[UIApplication sharedApplication]setStatusBarHidden:YES];
        [UIView animateWithDuration:.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.searchViewVertConst.constant = 0;
            self.searchBackgroundView.alpha = 1;
            self.blurEffectView.alpha = 1;
            [self.view layoutIfNeeded];
        }
                         completion:^(BOOL finished) {
                             self.plusButtonIsSelected = YES;
                             //animation will show the glow apear from the top and fade/slide in.
                             [UIView animateWithDuration:.8 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                                 self.purpleGlowImageView.alpha = 1;
                                 self.purpleGlowVertConst.constant = 0;
                             } completion:^(BOOL finished) {
                                 //
                             }];
                             
                         }];
    
    
    }
    else {//if plusbutton is selected
        self.purpleGlowImageView.alpha = 0;
        self.sliderView.hidden = NO;
        [self.purpleGlowImageView.layer setAffineTransform:CGAffineTransformMakeScale(-1, 1)];
        self.purpleGlowVertConst.constant = -338;
        self.plusButton.transform = CGAffineTransformMakeRotation(-M_PI / 2);
        [[UIApplication sharedApplication]setStatusBarHidden:NO];
        [UIView animateWithDuration:.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.searchViewVertConst.constant = 509;
            self.searchBackgroundView.alpha = 0;
            self.blurEffectView.alpha = 0;
            [self.view layoutIfNeeded];
        }
                         completion:^(BOOL finished) {
                            self.plusButtonIsSelected = NO;
                             //animation makes the glow fade/slide in from bottom
                             //animation makes the glow fade/slide in from bottom
                             [UIView animateWithDuration:.8 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                                 self.purpleGlowImageView.alpha = 1;
                                 self.purpleGlowVertConst.constant = -149;
                             } completion:^(BOOL finished) {
                                 //animation complete
                             }];
                         }];
    }
    
    [self.searchBar resignFirstResponder];
}

-(void)addSongButtonPressedOnCell:(id)sender
{
    NSInteger index =  ((UITableViewCell *)sender).tag;
    NSMutableDictionary *track = [self.searchTracks objectAtIndex:index];
    [self.selectedRows addIndex:index];
    NSString *UUIDString = self.UUIDString;
    NSDictionary *simpleTrack = @{@"title" : track[@"title"], @"user" :track[@"user"], @"stream_url": track[@"stream_url"], @"artwork_url" : track[@"artwork_url"], @"UUID" : UUIDString};
    NSArray *arrayWithTrack = @[simpleTrack];
    [self.socket emit:kQueueRequest args:arrayWithTrack];
    
}
#pragma mark - Remote Host Methods

- (IBAction)playPauseButtonPressed:(UIButton *)sender
{
    UIImage *playButtonImage = [UIImage imageNamed:@"Play"];
    UIImage *pauseButtonImage = [UIImage imageNamed:@"Pause"];
    UIImage *currentButton = [self.playPauseButton backgroundImageForState:UIControlStateNormal];
    if (self.isHost) {
        if([currentButton isEqual:pauseButtonImage])
        {
            [self.player pause];
            [self.playPauseButton setBackgroundImage:playButtonImage forState:UIControlStateNormal];
        } else {
            [self.player play];
            [self.playPauseButton setBackgroundImage:pauseButtonImage forState:UIControlStateNormal];
        }

    }
    
    //If the user is the host, allow them to togglepause the songs.
    if (self.isRemoteHost) {
        NSDictionary *togglePauseDic = @{@"action" : @"togglePause"};
        NSArray *argsArray = @[togglePauseDic];
        [self.socket emit:kRemoteAction args:argsArray];
    }
}

- (IBAction)skipButtonPressed:(UIButton *)sender
{
    
    if (self.isHost) {
        if (!self.hostQueue)
        {
            self.durationProgressView.hidden = NO;
        }else self.durationProgressView.hidden = YES;
        [self playNextSongInQueue];
    }
    //if the user is the host, allow them to skip songs.
    if (self.isRemoteHost) {
        NSDictionary *skipDic = @{@"action" : @"skip"};
        NSArray *argsArray = @[skipDic];
        [self.socket emit:kRemoteAction args:argsArray];
    }
}

//When remote text field returns
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    //Joing to the remote host, emit the password, if correct password allow the user to be the remote host and pause, play and skip songs.
    UIImage *playImage = [UIImage imageNamed:@"Play"];
    UIImage *pauseImage = [UIImage imageNamed:@"Pause"];
    NSString *remotePassword = self.remotePasswordTextField.text;
    NSDictionary *passwordDic = @{@"password" : remotePassword};
    NSArray *argsArray = @[passwordDic];
    [self.socket emit:kRemoteAdd args:argsArray];
    [self.socket on:kRemoteSet callback:^(NSArray *args) {
        
        NSDictionary *key = [args objectAtIndex:0];
        
        if ([key objectForKey:@"error"]) {
            self.remotePasswordInfoLabel.text = [key objectForKey:@"error"];
        }
        //if the password is a correct, and connection is successful, make the remote host's views appear.
        else{
            NSLog(@"Remote Host Connection Succesful");
            self.isRemoteHost = YES;
            
            __weak typeof(self) weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.remotePasswordTextField resignFirstResponder];
            });
            [self.socket on:@"playing" callback:^(NSArray *args) {
                [self.playPauseButton setBackgroundImage:pauseImage forState:UIControlStateNormal];
            }];
            [self.socket on:@"paused" callback:^(NSArray *args) {
                 [self.playPauseButton setBackgroundImage:playImage forState:UIControlStateNormal];
            }];
            
            self.playPauseButton.hidden = NO;
            self.skipButton.hidden = NO;
            self.playButtonPressed.hidden = NO;
            self.skipButtonPressed.hidden = NO;
            [self exitSettingsAnimation];
            self.remotePasswordTextField.hidden = YES;
            self.remotePasswordInfoLabel.text = @"Remote connected";
            [UIView animateWithDuration:.1 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self.setListTableViewVertConst.constant = 0;
                self.setListTableViewHeightConst.constant = 264;
            } completion:^(BOOL finished) {
                
            }];
            
        }
        

    }];

    return YES;
}

- (IBAction)setListlogoPressed:(UIButton *)sender
{
    //Bring up the remote view with an animation, and blur the background. Hide the search view.
    self.settingsView.hidden = NO;
    self.searchView.hidden = YES;
    [UIView animateWithDuration:.5 animations:^{
        self.blurEffectView.alpha = 1;
        self.roomCodeLabel.alpha = 1;
        self.roomCodeTextLabel.alpha = 1;
        self.whiteBorderView1.alpha  = 1;
        self.whiteBorderView2.alpha = 1;
        self.remotePasswordInfoLabel.alpha = 1;
        self.leaveRoomButton.alpha = 1;
        self.remoteImageView.alpha = 1;
        self.exitSettingsViewButton.alpha = 1;
        self.remotePasswordTextField.alpha = 1;
        }];
    
}
- (IBAction)exitSettingsButtonPressed:(UIButton *)sender
{
    [self exitSettingsAnimation];
    double time = .3;
    [self purpleGlowAnimationFromBottomWithDelay:&time];
    [self.remotePasswordTextField resignFirstResponder];
}

- (IBAction)leaveRoomButtonPressed:(UIButton *)sender
{
    [self disconnectSocketAndPopOut];
}

#pragma mark - Helper Methods


-(void)viewForNoCurrentArtistAsHost
{
    NSString *roomCodeAsHost = [[SocketKeeperSingleton sharedInstance]hostRoomCode];
    if (self.isHost)
    {
    self.currentSongLabel.text = @"";
    self.currentArtistLabel.text = @"";
    self.durationProgressView.hidden = YES;
    self.currentArtistViewBackground.hidden = YES;
    self.currentAlbumArtImage.image = [UIImage imageNamed:@""];
    self.currentArtistViewBackground.hidden = YES;
    self.playPauseButton.hidden = YES;
    self.skipButton.hidden = YES;
    self.playButtonPressed.hidden = YES;
    self.skipButtonPressed.hidden = YES;
    self.hostCodeMessageLabel.hidden = NO;
    self.hostRoomCodeLabel.hidden = NO;
    self.hostRoomCodeLabel.text = roomCodeAsHost;
    }
}

-(void)viewForNoCurrentArtistAsGuest
{
    if (!self.isHost) {
        self.currentSongLabel.text = @"";
        self.currentArtistLabel.text = @"";
        self.durationProgressView.hidden = YES;
        self.currentArtistViewBackground.hidden = YES;
        self.currentAlbumArtImage.image = [UIImage imageNamed:@""];
        self.currentArtistViewBackground.hidden = YES;
        self.playPauseButton.hidden = YES;
        self.skipButton.hidden = YES;
        self.playButtonPressed.hidden = YES;
        self.skipButtonPressed.hidden = YES;
    }
}

//for formating the tracks durations.
- (NSString *)timeFormatted:(int)totalSeconds
{
    int temp = (int)totalSeconds / 1000;
    int seconds = temp % 60;
    int minutes = temp / 60;
    
    if (seconds < 10) {
        return [NSString stringWithFormat:@"%i:0%i", minutes, seconds];
    }else
        return [NSString stringWithFormat:@"%i:%i", minutes, seconds];
}



-(void)disconnectSocketAndPopOut
{
    //stop the music.
    [self.player pause];
    self.player = nil;
    
    //Release objects from queue.
    self.hostQueue = nil;
    self.searchTracks = nil;
    self.hostCurrentArtist = nil;
    self.currentArtist = nil;
    
    //invalidate the timer
    [self.timer invalidate];
    
    //remove observers from notifications.
    [[NSNotificationCenter defaultCenter]removeObserver:self name:kQueueUpdated     object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:kCurrentArtistUpdate object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:kOnDisconnect     object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:kHostDisconnect object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:kQueueAdd    object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:kUserJoined object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:[self.player currentItem]];
    
    //close the socket.
    [self.socket close];
    //pop out
    
    [UIView animateWithDuration:.35 animations:^{
        self.setListView.alpha = 0;
        self.settingsView.alpha = 0;
        self.blurEffectView.alpha = 0;
    } completion:^(BOOL finished) {
        [self.navigationController popToRootViewControllerAnimated:NO];
    }];
    
}

-(void)exitSettingsAnimation
{
    self.plusButton.alpha = 0;
    self.searchView.hidden = NO;
    [UIView animateWithDuration:.3 animations:^{
        self.blurEffectView.alpha = 0;
        self.roomCodeLabel.alpha = 0;
        self.roomCodeTextLabel.alpha = 0;
        self.whiteBorderView1.alpha  = 0;
        self.whiteBorderView2.alpha = 0;
        self.remotePasswordInfoLabel.alpha = 0;
        self.leaveRoomButton.alpha = 0;
        self.remoteImageView.alpha = 0;
        self.exitSettingsViewButton.alpha = 0;
        self.remotePasswordTextField.alpha = 0;
        self.plusButton.alpha = 1;
        
    } completion:^(BOOL finished) {
        self.settingsView.hidden = YES;
        if (self.isRemoteHost) {
            UIImage *purpleHostIndicator = [UIImage imageNamed:@"remote-enabled.png"];
            self.remoteImageView.image = purpleHostIndicator;
            self.remoteImageVertConst.constant = 201;
            self.remoteLabelVertConst.constant = 230;
        }

        [self purpleGlowImageView];
    }];

}

-(void)purpleGlowAnimationFromBottomWithDelay:(NSTimeInterval *)delay
{
    self.purpleGlowImageView.alpha = 0;
    self.purpleGlowVertConst.constant = -338;
    self.searchBackgroundView.alpha = 0;
    [UIView animateWithDuration:1.0 delay:*delay options:UIViewAnimationOptionCurveEaseOut animations:^
     {
         self.purpleGlowImageView.alpha = 1;
         self.purpleGlowVertConst.constant = -149;
     }
     
                     completion:^(BOOL finished) {
                     }];

}

-(void)setCurrentArtistFromCurrentArtist:(NSDictionary *)currentArtist {
    
    NSDictionary *track = currentArtist;
    //If there is no current track, clear the current artist display.
    if (track == NULL) {
        if (self.isHost) {
            [self viewForNoCurrentArtistAsHost];
        }
        else [self viewForNoCurrentArtistAsGuest];
    }
    //else, If there is a current track, display its contents as current user
    else
    {
        if (![track objectForKey:@"user"])
        {
            if (self.isHost) {
                [self viewForNoCurrentArtistAsHost];
            }
            else [self viewForNoCurrentArtistAsGuest];
        }
        else
        {
            self.currentArtistViewBackground.hidden = NO;
            self.hostCodeMessageLabel.hidden = YES;
            self.currentSongLabel.text = [track objectForKey:@"title"];
            self.currentArtistLabel.text = [[track objectForKey:@"user"]objectForKey:@"username"];
            //If there is no picture available. Adds a Custom picture.
            //Init the cell image with the track's artwork.
            NSURL *artworkURL = [NSURL URLWithString:[track objectForKey:@"highRes"]];
            [self.currentAlbumArtImage sd_setImageWithURL:artworkURL];
        }
    }
}

#pragma mark - Playing Songs

- (void)updateTime {
    
    UIImage *pauseButtonImage = [UIImage imageNamed:@"Pause"];
    float duration = CMTimeGetSeconds(self.player.currentItem.duration);
    float current = CMTimeGetSeconds(self.player.currentTime);
    
    self.durationProgressView.progress = (current/duration);
    if (self.durationProgressView.progress == 0)
    {
        [self.playPauseButton setBackgroundImage:pauseButtonImage forState:UIControlStateNormal];
    }
    
}

-(void)playCurrentArtist:(NSDictionary *)currentArtist
{
    NSString *streamString = [currentArtist objectForKey:@"stream_url"];
    NSString *urlString = [NSString stringWithFormat:@"%@?client_id=%@", streamString,CLIENT_ID];
    NSURL *URLFromString = [NSURL URLWithString:urlString];
    self.player = [AVPlayer playerWithURL:URLFromString];
    self.player.allowsExternalPlayback = NO;
    [self.player play];
    self.durationProgressView.hidden = NO;
     [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemDidFinishPlaying:) name:AVPlayerItemDidPlayToEndTimeNotification object:[self.player currentItem]];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:.05 target:self selector:@selector(updateTime) userInfo:nil repeats:YES];
    
    Class playingInfoCenter = NSClassFromString(@"MPNowPlayingInfoCenter");
    
    if (playingInfoCenter) {
        float playerDuration = CMTimeGetSeconds(self.player.currentItem.duration);
        float playerCurrent = CMTimeGetSeconds(self.player.currentTime);
        NSURL *artworkURL = [NSURL URLWithString:currentArtist[@"highRes"]];
        [self.dicForInfoCenter removeAllObjects];
        [self.dicForInfoCenter setObject:currentArtist[@"title"] forKey:MPMediaItemPropertyTitle];
        [self.dicForInfoCenter setObject:currentArtist[@"user"][@"username"] forKey:MPMediaItemPropertyArtist];
        [self.dicForInfoCenter setObject:[NSNumber numberWithFloat:playerDuration] forKey:MPMediaItemPropertyPlaybackDuration];
        [self.dicForInfoCenter setObject:[NSNumber numberWithFloat:playerCurrent] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
        [self.dicForInfoCenter setObject:[NSNumber numberWithFloat:1.0f] forKey:MPNowPlayingInfoPropertyPlaybackRate];
        [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:artworkURL options:kNilOptions
    progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        //size;
    } completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
        MPMediaItemArtwork *albumArt = [[MPMediaItemArtwork alloc]initWithImage:image];
        [self.dicForInfoCenter setObject:albumArt forKey:MPMediaItemPropertyArtwork];
        [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:self.dicForInfoCenter];
    }];
        [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:self.dicForInfoCenter];
        
    }
    
}

-(void)remoteControlReceivedWithEvent:(UIEvent *)event
{
    if (event.type == UIEventTypeRemoteControl) {
        
        if (event.type == UIEventTypeRemoteControl)
        {
            if (event.subtype == UIEventSubtypeRemoteControlPlay)
            {
                [self playPauseButtonPressed:nil];
            }
            else if (event.subtype == UIEventSubtypeRemoteControlPause)
            {
                [self playPauseButtonPressed:nil];
            }
            else if (event.subtype == UIEventSubtypeRemoteControlNextTrack)
            {
                [self skipButtonPressed:nil];
            }
            
        }
    }
}


-(void)itemDidFinishPlaying:(NSNotification *) notification {
    //if there are no tracks in queue
    if (![self.hostQueue count]) {
        NSLog(@"nothing in queue upon song finishing");
        [[NSNotificationCenter defaultCenter]removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:[self.player currentItem]];
        [self.hostCurrentArtist removeAllObjects];
        [self setCurrentArtistFromCurrentArtist:self.hostCurrentArtist];
        NSArray *argsCurrentArray = @[self.hostCurrentArtist];
        [self.socket emit:kCurrentArtistChange args:argsCurrentArray];
    }
    else {
        [self playNextSongInQueue];
        [self setCurrentArtistFromCurrentArtist:self.hostCurrentArtist];
    };
}

-(void)playNextSongInQueue
{
    if ([self.hostQueue count]) {
        [self.timer invalidate];
        [[NSNotificationCenter defaultCenter]removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:[self.player currentItem]];
        UIImage *pausedButtonImage = [UIImage imageNamed:@"Pause"];
        //Rearange tracks and current songs and emit them to the sever.
        NSDictionary *currentTrack = [self.hostQueue objectAtIndex:0];
        self.hostCurrentArtist = [currentTrack mutableCopy];
        [self.hostQueue removeObjectAtIndex:0];
        [self.tableView reloadData];
        
        [self playCurrentArtist:self.hostCurrentArtist];
        
        [self.playPauseButton setBackgroundImage:pausedButtonImage forState:UIControlStateNormal];
        self.durationProgressView.hidden = NO;
        self.timer = [NSTimer scheduledTimerWithTimeInterval:.05 target:self selector:@selector(updateTime) userInfo:nil repeats:YES];

        NSArray *argsWithQueue = @[self.hostQueue];
        NSArray *arrayWithTrack = @[currentTrack];
        [self setCurrentArtistFromCurrentArtist:self.hostCurrentArtist];
        [self.socket emit:kCurrentArtistChange args:arrayWithTrack];
        [self.socket emit:kQueueChange args:argsWithQueue];
       
    }
}


-(void)didReceiveMemoryWarning
{
    NSLog(@"Memory warning!");
}

@end
