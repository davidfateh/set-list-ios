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
#import "CollectionViewCell.h"
#import "CurrentArtistHeader.h"
#import <CSStickyHeaderFlowLayout/CSStickyHeaderFlowLayout.h>


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
@property (strong, nonatomic) UINib *headerNib;
@property (strong, nonatomic) CurrentArtistHeader *currentArtistHeader;
@property (nonatomic) BOOL playerIsPlaying;
@end

@implementation SetListRoomViewController

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
    self.headerNib = [UINib nibWithNibName:@"AlwaysOnTopHeader" bundle:nil];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    RadialGradiantView *radiantBackgroundView = [[RadialGradiantView alloc] initWithFrame:self.view.bounds];
    [self.setListBackgroundView addSubview:radiantBackgroundView];
    
    [[UIApplication sharedApplication]setStatusBarStyle:UIStatusBarStyleLightContent];
    
    //Set the text on the search bar to white.
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setTextColor:[UIColor whiteColor]];
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setKeyboardAppearance:UIKeyboardAppearanceDark];
    
    
    
    CSStickyHeaderFlowLayout *layout = (id)self.collectionView.collectionViewLayout;
    
    if ([layout isKindOfClass:[CSStickyHeaderFlowLayout class]]) {
        layout.parallaxHeaderReferenceSize = CGSizeMake(self.view.frame.size.width, 233);
        layout.parallaxHeaderMinimumReferenceSize = CGSizeMake(self.view.frame.size.width, 100);
        layout.parallaxHeaderAlwaysOnTop = YES;
        
        // If we want to disable the sticky header effect
        layout.disableStickyHeaders = YES;
    }
    
    // Also insets the scroll indicator so it appears below the search bar
    self.collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 0, 0);
    
    [self.collectionView registerNib:self.headerNib
          forSupplementaryViewOfKind:CSStickyHeaderParallaxHeader
                 withReuseIdentifier:@"header"];
    
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    
    //Set the delegates for the search view.
    self.searchBar.delegate = self;
    self.searchTableView.delegate = self;
    self.searchTableView.dataSource = self;
    
    //Set the UUID for the user
    self.UUIDString = [[NSUserDefaults standardUserDefaults]objectForKey:@"UUID"];
    
    self.searchTracks = [[NSMutableArray alloc]init];
    self.guestQueue = [[NSMutableArray alloc]init];
    self.currentArtist = [[NSMutableDictionary alloc]init];
    self.hostCurrentArtist = [[NSMutableDictionary alloc]init];
    
    self.longPressRec.minimumPressDuration = 0;
    self.exitRemotePlusImage.transform = CGAffineTransformMakeRotation(M_PI/4);
    self.remoteTextField.tintColor = [UIColor whiteColor];
    self.remoteTextField.delegate = self;
    self.remoteTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    
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
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(skipPressedNotification:)
                                                     name:@"skipPressed"
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playPausePressedNotification:)
                                                     name:@"playPausePressed"
                                                   object:nil];

        if (!self.player)
        {
            self.player = [[AVPlayer alloc]init];
            self.player.allowsExternalPlayback = NO;
        }
        
        self.dicForInfoCenter = [[NSMutableDictionary alloc]init];
        NSLog(@"User is the host of this room");
        self.isHost = YES;
        self.playerIsPlaying = NO;
        self.hostRoomCodeLabel.text = roomCodeAsHost;
        self.hostRoomCodeLabel.hidden = NO;
        self.hostCodeMessageLabel.hidden = NO;
        
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
        
        //Add some animations upon load up. Purple glow and tableview animation.
        double delay = .4;
        [self purpleGlowAnimationFromBottomWithDelay:&delay];
        
        
        //Set the queue, if there is one.
        NSArray *setListTracks = [[SocketKeeperSingleton sharedInstance]setListTracks];
        NSMutableArray *tracks = [setListTracks mutableCopy];
        if (setListTracks) {
            self.guestQueue = tracks;
        }
        //if there is a current artist track, set it.
        NSDictionary *currentTrack = [[SocketKeeperSingleton sharedInstance]currentArtist];
        if (currentTrack)
        {
            self.currentArtist = currentTrack;
        }
        //reload the collection view to display the data.
        [self.collectionView reloadData];
    }
    
    self.setListView.alpha = 0;
    self.searchView.alpha = 0;
    self.sliderView.alpha = 0;
    
}
-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:YES];
    
    //fade animation in for a nice load in effect
    [UIView animateWithDuration:.5 delay:.35 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.searchView.alpha = 1;
        self.setListView.alpha = 1;
        self.sliderView.alpha = 1;
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

-(void)playPausePressedNotification:(NSNotification *)notificaiton
{
    [self playPauseButtonPressed];
}

-(void)skipPressedNotification:(NSNotification *)notificaiton
{
    [self skipButtonPressed];
}
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
    
    if (!self.hostRoomCodeLabel.hidden) {
        self.hostRoomCodeLabel.hidden = YES;
        self.hostCodeMessageLabel.hidden = YES;
    }

   NSDictionary *songAdded = [[SocketKeeperSingleton sharedInstance]songAdded];
    //if there is a current artist, add the song to the queue, else, make it the current artist.
    if ([self.hostCurrentArtist objectForKey:@"user"]) {
        
        [self.hostQueue addObject:songAdded];
        [self.collectionView reloadData];
        //Emit the added song so the client can recieve it.
        NSArray *queueArray = @[self.hostQueue];
        [self.socket emit:kQueueChange args:queueArray];
        
    }
    //else, if there isnt a current artist, add the song as current artist.
    else
    {
        self.collectionView.hidden = NO;
        self.hostCurrentArtist = [songAdded mutableCopy];
        NSDictionary *songAddedForCurrent = self.hostCurrentArtist;
        [self playCurrentArtist:self.hostCurrentArtist];
        NSArray *songAddedArray = @[songAddedForCurrent];
        //emit the song for other clients to recieve and add to their current.
        [self.socket emit:kCurrentArtistChange args:songAddedArray];
        
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
    NSLog(@"recieved current artist update");
    if (!self.isHost) {
        self.collectionView.hidden = NO;
        NSDictionary *currentArtist = [[SocketKeeperSingleton sharedInstance]currentArtist];
        self.currentArtist = currentArtist;
        [self.collectionView reloadData];
    }
}

- (void)receiveQueueUpdatedNotification:(NSNotification *)notification
{
    NSLog(@"recieved update B notification");
    if (!self.isHost) {
        NSArray *setListTracks = [[SocketKeeperSingleton sharedInstance]setListTracks];
        self.guestQueue = [setListTracks mutableCopy];
        [self.collectionView reloadData];
    }
}

#pragma mark - TableView Delegate and DataSource

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *ReusableIdentifier = @"Cell";
    SetListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ReusableIdentifier forIndexPath:indexPath];
    
    cell.delegate = self;
    
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
    
    
    return cell;
}


-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return  self.searchTracks.count;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self.searchBar resignFirstResponder];
}

#pragma mark UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (self.isHost) {
            return [self.hostQueue count];
        }
        else return [self.guestQueue count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    CollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell"
                                                forIndexPath:indexPath];
    //configure the cell for if the user is the host of the room.
    if ([self.hostQueue count])
    {
        cell.delegate = self;
        cell.deleteSongImageView.hidden = NO;
        cell.deleteSongButton.hidden = NO;
        NSDictionary *track = self.hostQueue[indexPath.row];
        cell.songTitleLabel.text = track[@"title"];
        cell.artistLabel.text = [[track objectForKey:@"user"]objectForKey:@"username"];
        cell.deleteSongImageView.transform = CGAffineTransformMakeRotation(M_PI/4);
        cell.tag = indexPath.row;
    }
    //configure the room for if the user is the guest of a room.
    else if ([self.guestQueue count])
    {
        NSDictionary *track = self.guestQueue[indexPath.row];
        cell.songTitleLabel.text = track[@"title"];
        cell.artistLabel.text = [[track objectForKey:@"user"]objectForKey:@"username"];
        if ([[track objectForKey:@"UUID"]isEqualToString:self.UUIDString]) {
            cell.purpleDotIndicator.hidden = NO;
        }
        else
        {
            cell.purpleDotIndicator.hidden = YES;
        }
    }
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    
    if ([kind isEqualToString:CSStickyHeaderParallaxHeader]) {
        CurrentArtistHeader *cell = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                               withReuseIdentifier:@"header"
                                                                      forIndexPath:indexPath];
        if (self.hostCurrentArtist[@"user"]) {
            
            cell.artistView.hidden = NO;
            NSDictionary *track = self.hostCurrentArtist;
            cell.songTitleLabel.text = track[@"title"];
            cell.artistLabel.text = [[track objectForKey:@"user"]objectForKey:@"username"];
            NSURL *artworkURL = [NSURL URLWithString:track[@"highRes"] ];
            [cell.artworkImage sd_setImageWithURL:artworkURL];
            
            if (self.playerIsPlaying) {
                cell.playPauseImageView.image = [UIImage imageNamed:@"Pause"];
            }
            else cell.playPauseImageView.image = [UIImage imageNamed:@"Play"];
        }
        
        else if (self.currentArtist[@"user"])
        {
            cell.controlsView.hidden = YES;
            cell.artistView.hidden = NO;
            NSDictionary *track = self.currentArtist;
            cell.songTitleLabel.text = track[@"title"];
            cell.artistLabel.text = [[track objectForKey:@"user"]objectForKey:@"username"];
            NSURL *artworkURL = [NSURL URLWithString:track[@"highRes"] ];
            [cell.artworkImage sd_setImageWithURL:artworkURL];
            
            if (self.isRemoteHost) {
                cell.controlsView.hidden = NO;
                if (self.playerIsPlaying)
                {
                    cell.playPauseImageView.image = [UIImage imageNamed:@"Pause"];
                }
                else cell.playPauseImageView.image = [UIImage imageNamed:@"Play"];
            }
        }
        
        return cell;
    }
    return nil;
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
    if (self.isHost) {
        self.remoteLabel.hidden = YES;
    }
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
        
        
        if ((recognizer.view.center.y + point.y)>226 && (recognizer.view.center.y + point.y)<273 && !self.isHost) {
            
            [UIView animateWithDuration:.25 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
                [self.remoteLabel setFrame:CGRectMake(141, 236, 60, 20)];
                self.remoteLabel.alpha = 1;
                self.remoteLabelPushed = YES;
            } completion:^(BOOL finished) {
                self.remoteLabelSelected = YES;
            }];
        }
        else
        {
            [self returnRemoteLabel];
        }
        
        if ((recognizer.view.center.y + point.y)>392 && (recognizer.view.center.y + point.y)<442) {
            
            [UIView animateWithDuration:.25 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
                [self.leaveLabel setFrame:CGRectMake(155,410, 46, 21)];
                self.leaveLabel.alpha = 1;
                self.leaveLabelPushed = YES;
            } completion:^(BOOL finished) {
                self.leaveLabelSelected = YES;
            }];
        }
        else
        {
            self.leaveLabelSelected = NO;
            [UIView animateWithDuration:.25 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
                [self.leaveLabel setFrame:CGRectMake(195,410, 46, 21)];
                self.leaveLabel.alpha = .5;
                self.leaveLabelPushed = NO;
            } completion:^(BOOL finished) {
                //completion
            }];
        }
        
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded)
    {
        self.searchView.hidden = NO;
        self.purpleGlowImageView.alpha = 0;
        
        //If the user has the remote selected, make the remote view appear and allow the user to put in the remote password.
        if (self.remoteLabelSelected && !self.isHost) {
            self.remoteCodeView.alpha = 0;
            self.remoteCodeView.hidden = NO;
            self.exitRemotePlusImage.hidden = YES;
            [UIView animateWithDuration:.3 animations:^{
                self.menuView.alpha = 0;
                self.sliderView.alpha = 0;
                self.remoteCodeView.alpha = 1;
                self.blurEffectView.alpha = 1;
            } completion:^(BOOL finished) {
                self.menuView.hidden = YES;
                if (!self.isRemoteHost) {
                    [self.remoteTextField becomeFirstResponder];
                }
                else
                {
                    self.remoteTextField.hidden = YES;
                }
                self.exitRemotePlusImage.center = CGPointMake(self.exitRemotePlusImage.center.x,
                                                              self.exitRemotePlusImage.center.y -75);
                self.exitRemotePlusImage.hidden = NO;
                [UIView animateWithDuration:.5 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                    self.exitRemotePlusImage.center = CGPointMake(self.exitRemotePlusImage.center.x, self.exitRemotePlusImage.center.y + 75);
                } completion:^(BOOL finished) {
                    [self returnMenuSlider];
                    [self returnRemoteLabel];
                }];
            }];

        }
        else if (self.leaveLabelSelected)
        {
            self.setListView.hidden = YES;
            self.searchView.hidden = YES;
            [UIView animateWithDuration:.1 animations:^{
                self.blurEffectView.alpha = 0;
                self.menuView.alpha = 0;
                self.sliderView.alpha = 0;
            } completion:^(BOOL finished) {
                self.menuView.hidden = YES;
                self.sliderView.hidden = YES;
                [self disconnectSocketAndPopOut];
            }];
        }
        
        
        
        
        
        else {
            //If the user does not have a selection, animate the slider back to its bar button position. Clear the menu view and animate the purple glow upon return.
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

-(void)deleteSongButtonPressedOnCell:(id)sender
{
    NSInteger index =  ((UICollectionViewCell *)sender).tag;
    [self.hostQueue removeObjectAtIndex:index];
    [self.collectionView reloadData];
}

#pragma mark - Remote Host Methods

//When remote text field returns
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    //Join to the remote host, emit the password, if correct password allow the user to be the remote host and pause, play and skip songs.
    NSString *remotePassword = self.remoteTextField.text;
    NSDictionary *passwordDic = @{@"password" : remotePassword};
    NSArray *argsArray = @[passwordDic];
    [self.socket emit:kRemoteAdd args:argsArray];
    [self.socket on:kRemoteSet callback:^(NSArray *args) {
        
        NSDictionary *key = [args objectAtIndex:0];
        
        if ([key objectForKey:@"error"]) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                self.remoteTextLabel.text = [key objectForKey:@"error"];
            });
        }
        
        //if the password is a correct, and connection is successful, make the remote host's views appear.
        else{
            NSLog(@"Remote Host Connection Succesful");
            
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(skipPressedNotification:)
                                                         name:@"skipPressed"
                                                       object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(playPausePressedNotification:)
                                                         name:@"playPausePressed"
                                                       object:nil];
            self.isRemoteHost = YES;
            __weak typeof(self) weakSelf = self;
            dispatch_sync(dispatch_get_main_queue(), ^{
                weakSelf.remoteTextLabel.text = @"Remote host enabled";
                [weakSelf.remoteTextField resignFirstResponder];
                [UIView animateWithDuration:.1 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                
                } completion:^(BOOL finished) {
                }];
                
                [weakSelf exitRemoteButtonPressed:nil];
            });
            
            [self.socket on:@"playing" callback:^(NSArray *args) {
                self.playerIsPlaying = YES;
                [self.collectionView reloadData];
            }];
            [self.socket on:@"paused" callback:^(NSArray *args)
            {
                self.playerIsPlaying = NO;
                [self.collectionView reloadData];
            }];
        }
    }];

    return YES;
}

#pragma mark - Helper Methods
-(void)returnMenuSlider
{
    UIImage *menuImage = [UIImage imageNamed:@"menu-button.png"];
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
    } completion:^(BOOL finished)
    {
        double time = 0;
        [self purpleGlowAnimationFromBottomWithDelay:&time];
        self.sliderView.alpha = 1;
        self.sliderImageView.alpha = 1;
        self.menuView.hidden = YES;
        [self.sliderImageView setImage:menuImage];
    }];
}

-(void)returnRemoteLabel
{
    self.remoteLabelSelected = NO;
    [UIView animateWithDuration:.25 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        [self.remoteLabel setFrame:CGRectMake(181, 236, 60, 20)];
        self.remoteLabel.alpha = .5;
        self.remoteLabelPushed = NO;
    } completion:^(BOOL finished) {
        //completion
    }];
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
    [[NSNotificationCenter defaultCenter]removeObserver:self name:@"skipPressed"    object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:@"playPausePressed" object:nil];
    
    //close the socket.
    [self.socket close];
    //pop out
    
    [UIView animateWithDuration:.35 animations:^{
        self.blurEffectView.alpha = 0;
    } completion:^(BOOL finished) {
        [self.navigationController popToRootViewControllerAnimated:NO];
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


#pragma mark - Playing Songs

- (void)updateTime {
    
    float duration = CMTimeGetSeconds(self.player.currentItem.duration);
    float current = CMTimeGetSeconds(self.player.currentTime);
    
    self.durationProgressView.progress = (current/duration);
    if (self.durationProgressView.progress == 0)
    {
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
    self.playerIsPlaying = YES;
    [self.collectionView reloadData];
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
        //download the artwork url and set it as the background of lockscreen when recievied.
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
                [self playPauseButtonPressed];
            }
            else if (event.subtype == UIEventSubtypeRemoteControlPause)
            {
                [self playPauseButtonPressed];
            }
            else if (event.subtype == UIEventSubtypeRemoteControlNextTrack)
            {
                [self skipButtonPressed];
            }
        }
    }
}
-(void)skipButtonPressed
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

-(void)playPauseButtonPressed
{
    if (self.isHost) {
        if(self.playerIsPlaying == YES)
        {
            [self.player pause];
            self.playerIsPlaying = NO;
        } else {
            [self.player play];
            self.playerIsPlaying = YES;
        }
        [self.collectionView reloadData];
    }
    //If the user is the host, allow them to togglepause the songs.
    if (self.isRemoteHost) {
        NSDictionary *togglePauseDic = @{@"action" : @"togglePause"};
        NSArray *argsArray = @[togglePauseDic];
        [self.socket emit:kRemoteAction args:argsArray];
    }
}


-(void)itemDidFinishPlaying:(NSNotification *) notification {
    //if there are no tracks in queue
    if (![self.hostQueue count]) {
        NSLog(@"nothing in queue upon song finishing");
        self.playerIsPlaying = NO;
        [[NSNotificationCenter defaultCenter]removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:[self.player currentItem]];
        [self.hostCurrentArtist removeAllObjects];
        NSArray *argsCurrentArray = @[self.hostCurrentArtist];
        [self.socket emit:kCurrentArtistChange args:argsCurrentArray];
    }
    else {
        [self playNextSongInQueue];
    };
}

-(void)playNextSongInQueue
{
    if ([self.hostQueue count]) {
        [self.timer invalidate];
        [[NSNotificationCenter defaultCenter]removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:[self.player currentItem]];
        //Rearange tracks and current songs and emit them to the sever.
        NSDictionary *currentTrack = [self.hostQueue objectAtIndex:0];
        self.hostCurrentArtist = [currentTrack mutableCopy];
        [self.hostQueue removeObjectAtIndex:0];
        [self.collectionView reloadData];
        
        [self playCurrentArtist:self.hostCurrentArtist];
        
        self.durationProgressView.hidden = NO;
        self.timer = [NSTimer scheduledTimerWithTimeInterval:.05 target:self selector:@selector(updateTime) userInfo:nil repeats:YES];

        NSArray *argsWithQueue = @[self.hostQueue];
        NSArray *arrayWithTrack = @[currentTrack];
        [self.socket emit:kCurrentArtistChange args:arrayWithTrack];
        [self.socket emit:kQueueChange args:argsWithQueue];
       
    }
}


-(void)didReceiveMemoryWarning
{
    NSLog(@"Memory warning!");
}

- (IBAction)exitRemoteButtonPressed:(UIButton *)sender
{
        [self.remoteTextField resignFirstResponder];
        [UIView animateWithDuration:.3 animations:^{
            self.remoteCodeView.alpha = 0;
            self.blurEffectView.alpha = 0;
        } completion:^(BOOL finished) {
            self.remoteCodeView.hidden = YES;
            self.remoteTextField.text = nil;
        }];
}

@end
