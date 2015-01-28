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

#define CLIENT_ID @"40da707152150e8696da429111e3af39"

@interface SetListRoomViewController ()
@property (strong, nonatomic) NSString *socketID;
@property (nonatomic) BOOL plusButtonIsSelected;
@property (strong, nonatomic) NSMutableIndexSet *selectedRows;
@property (strong, nonatomic) UIVisualEffectView *blurEffectView;
@property (strong, nonatomic) SIOSocket *socket;
@property (nonatomic) BOOL ishost;

@end

@implementation SetListRoomViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.socket = [[SocketKeeperSingleton sharedInstance]socket];
    
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
    
    //Set the tableview position for if the user is not the host. No space between header and tableView. 
    self.setListTableViewHeightConst.constant = 218;
    self.setListTableViewVertConst.constant = 274;

    
    //set the delegates for the set list view. 
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.tableView.layoutMargins = UIEdgeInsetsZero;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    //Set the number of the namespace/roomCode; 
    self.roomCodeLabel.text = self.roomCode;
    
    
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
    [self.plusButton setBackgroundImage:plusImage forState:UIControlStateNormal];
    
    
    //Add a notifcation observer and postNotification name for updating the tracks.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveUpdateBNotification:)
                                                 name:@"qUpdateB"
                                               object:nil];
    [[NSNotificationCenter defaultCenter]postNotificationName:@"qUpdateB" object:nil];
    
    
    
    //Add a notifcation observer and postNotification name for updating current artist.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveUpdateCurrentArtistBNotification:)
                                                 name:@"currentArtistB"
                                               object:nil];
    [[NSNotificationCenter defaultCenter]postNotificationName:@"currentArtistB" object:nil];

    self.socketID =[[SocketKeeperSingleton sharedInstance]socketID];
    
}



#pragma mark - Notification Center

-(void)receiveUpdateCurrentArtistBNotification:(NSNotification *)notification
{
    // Do parse respone data method and update yourTableViewData
    
    NSDictionary *currentArtist = [[SocketKeeperSingleton sharedInstance]currentArtist];
    
    NSDictionary *track = currentArtist;
    
    //If there is no current track, set the label to inform the user.
    if ([track isEqual:[NSNull null]]) {
        self.currentSongLabel.text = @"No current song";
        self.currentArtistLabel.text = @"";
        
    }
    
    //else, display the current songs info
    else
    {
        self.currentSongLabel.text = [track objectForKey:@"title"];
        self.currentArtistLabel.text = [[track objectForKey:@"user"]objectForKey:@"username"];
        
        //If there is no picture available. Adds a Custom picture.
        
        //Init the cell image with the track's artwork.
        NSURL *artworkURL = [NSURL URLWithString:[track objectForKey:@"highRes"]];
        NSData *imageData = [NSData dataWithContentsOfURL:artworkURL];
        UIImage *cellImage = [UIImage imageWithData:imageData];
        self.currentAlbumArtImage.image = cellImage;
        
    }
    
}

- (void)receiveUpdateBNotification:(NSNotification *)notification
{
    NSArray *recievedtracks = [[SocketKeeperSingleton sharedInstance]setListTracks];
    
    self.tracks = recievedtracks;
    [self.tableView reloadData];
    
}

#pragma mark - TableView Delegate and DataSource

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *ReusableIdentifier = @"Cell";
    SetListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ReusableIdentifier forIndexPath:indexPath];
    
    
    cell.delegate = self;
    
        if (tableView.tag == 1) {
            NSDictionary *track = [self.tracks objectAtIndex:indexPath.row];
            NSString *songTitle = [track objectForKey:@"title"];
            NSString *artist = [[track objectForKey:@"user"]objectForKey:@"username"];
            
            cell.artistLabel.text = artist;
            cell.songLabel.text = songTitle;
           
            if ([[track objectForKey:@"socket"]isEqualToString:self.socketID]) {
                cell.userSelectedSongImageView.hidden = NO;
            }
            else
            {
                cell.userSelectedSongImageView.hidden = YES;
            }
            
            
        }
        else if (tableView.tag == 2)
        {
            // Configure the cell...
            
            NSMutableDictionary *track = [[self.searchTracks objectAtIndex:indexPath.row]mutableCopy];
            cell.searchSongTitle.text = [track objectForKey:@"title"];
            cell.searchArtist.text = [[track objectForKey:@"user"]objectForKey:@"username"];
            
            //Format the tracks duration into a string and set the label.
            int duration = [[track objectForKey:@"duration"]intValue];
            NSString *durationString = [self timeFormatted:duration];
            cell.searchDurationLabel.text = durationString;
            
            
            //If there is no picture available. Adds a Custom picture.
            if ([[track objectForKey:@"artwork_url"] isEqual:[NSNull null]]){
                
                cell.searchAlbumArtImage.image = [UIImage imageNamed:@"SoundCloudLogo"];
                
            }
            else{
                //Init the cell image with the track's artwork.
                UIImage *cellImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[track objectForKey:@"artwork_url"]]]];
                cell.searchAlbumArtImage.image = cellImage;
                
            }
            
            //if the row is selected make sure the check mark is the background image. 
            UIImage *checkImage = [UIImage imageNamed:@"check.png"];
            UIImage *plusImage  = [UIImage imageNamed:@"plusButton"];
            
            if ([self.selectedRows containsIndex:indexPath.row]) {
                [cell.plusButton setBackgroundImage:checkImage forState:UIControlStateNormal];
            }
            else {
                [cell.plusButton setBackgroundImage:plusImage forState:UIControlStateNormal];
            }
            cell.tag = indexPath.row;
        }
    
    return cell;
}


-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView.tag == 1) {
        return [self.tracks count];
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
             
             self.searchTracks = (NSArray *)jsonResponse;
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

#pragma mark - Custom Buttons

- (IBAction)displaySearchViewButtonPressed:(UIButton *)sender {
    
    if (!self.plusButtonIsSelected) {
        [self.purpleGlowImageView.layer setAffineTransform:CGAffineTransformMakeScale(1, -1)];
        self.purpleGlowVertConst.constant = 0;
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
                         }];
        
    }
    else {//if plusbutton is selected
        [self.purpleGlowImageView.layer setAffineTransform:CGAffineTransformMakeScale(-1, 1)];
        self.purpleGlowVertConst.constant = -149;
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
                         }];
    }
    
    [self.searchBar resignFirstResponder];
}


-(void)addSongButtonPressedOnCell:(id)sender
{
    //Get the index from the sender's tag.
    NSInteger index =  ((UITableViewCell *)sender).tag;
    NSMutableDictionary *track = [self.searchTracks objectAtIndex:index];
    [self.selectedRows addIndex:index];
    
    NSArray *argsArray = [[NSArray alloc]initWithObjects:track, nil];
    //Send the data to the server/socket.
    [self.socket emit:@"q_add_request" args:argsArray];
    
    
}

#pragma mark - Remote Host Methods


- (IBAction)playPauseButtonPressed:(UIButton *)sender
{
    //If the user is the host, allow them to togglepause the songs.
    if (self.ishost) {
        NSMutableDictionary *togglePauseDic = [[NSMutableDictionary alloc]init];
        [togglePauseDic setObject:@"togglePause" forKey:@"action"];
        NSArray *argsArray = [[NSArray alloc]initWithObjects:togglePauseDic, nil];
        [self.socket emit:@"remote" args:argsArray];
    }
}

- (IBAction)skipButtonPressed:(UIButton *)sender
{
    //if the user is the host, allow them to skip songs.
    if (self.ishost) {
        NSMutableDictionary *skipDic = [[NSMutableDictionary alloc]init];
        [skipDic setObject:@"skip" forKey:@"action"];
        NSArray *argsArray = [[NSArray alloc]initWithObjects:skipDic, nil];
        [self.socket emit:@"remote" args:argsArray];
    }
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    //Joing to the remote host, emit the password, if correct password allow the user to be the host and pause, play and skip songs.
    NSString *remotePassword = self.remotePasswordTextField.text;
    NSMutableDictionary *passwordDick = [[NSMutableDictionary alloc]init];
    [passwordDick setObject:remotePassword forKey:@"password"];
    NSArray *argsArray = [[NSArray alloc]initWithObjects:passwordDick, nil];
    [self.socket emit:@"add remote" args:argsArray];
    [self.socket on:@"add remote" callback:^(NSArray *args) {
        
        NSMutableDictionary *key = [[NSMutableDictionary alloc]init];
        key = (NSMutableDictionary *)[args objectAtIndex:0];
        //if the password is a correct, and connection is successful, make the host view appear.
        if ([key objectForKey:@"success"]) {
            NSLog(@"Host Connection Succesful");
            self.ishost = YES;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.remotePasswordTextField resignFirstResponder];
            });
            
            
            [self.socket on:@"playing" callback:^(NSArray *args) {
                self.playPauseButton.selected = YES;
            }];
            [self.socket on:@"paused" callback:^(NSArray *args) {
                self.playPauseButton.selected = NO;
            }];
            
            self.hostIconIndicatorImage.hidden = NO;
            self.searchView.hidden = NO;
            self.playPauseButton.hidden = NO;
            self.skipButton.hidden = NO;
            
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
                self.settingsView.hidden = YES;
            }];
            
            self.remotePasswordTextField.hidden = YES;
            self.remoteImageVertConst.constant = 181;
            self.remoteLabelVertConst.constant = 210;
            UIImage *purpleIndicator = [UIImage imageNamed:@"remote-enabled.png"];
            self.remoteImageView.image = purpleIndicator;
            self.remotePasswordInfoLabel.text = @"You are a remote host";

            
            [UIView animateWithDuration:.1 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self.setListTableViewVertConst.constant = 304;
                self.setListTableViewHeightConst.constant = 238;
            } completion:^(BOOL finished) {
                
            }];
            
        }
        if ([key objectForKey:@"error"]) {
            self.remotePasswordInfoLabel.text = [key objectForKey:@"error"];
        }

    }];

    return YES;
}

- (IBAction)setListlogoPressed:(UIButton *)sender
{
    //Bring up the remote view with an animation, and blur the background. Hide the search view.
    self.settingsView.hidden = NO;
    self.searchView.hidden = YES;
    [UIView animateWithDuration:.3 animations:^{
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
        self.settingsView.hidden = YES;
    }];

    [self.remotePasswordTextField resignFirstResponder];
}

- (IBAction)leaveRoomButtonPressed:(UIButton *)sender
{
    [self.navigationController popToRootViewControllerAnimated:YES];
    [self.socket close];
}

#pragma mark - Helper Methods

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




@end
