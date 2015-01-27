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
#import "BlackHeaderGradient.h"



#define CLIENT_ID @"40da707152150e8696da429111e3af39"

@interface SetListRoomViewController ()
@property (strong, nonatomic) NSString *socketID;
@property (nonatomic) BOOL plusButtonIsSelected;
@property (strong, nonatomic) NSMutableIndexSet *selectedRows;
@property (strong, nonatomic) UIVisualEffectView *blurEffectView;

@end

@implementation SetListRoomViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    
    [[UIApplication sharedApplication]setStatusBarStyle:UIStatusBarStyleLightContent];
    
    //Set the text on the search bar to white.
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setTextColor:[UIColor whiteColor]];
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setKeyboardAppearance:UIKeyboardAppearanceDark];
    
    //Set the delegates for the search view.
    self.searchBar.delegate = self;
    self.searchTableView.delegate = self;
    self.searchTableView.dataSource = self;
    
    //set the delegates for the set list view. 
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.tableView.layoutMargins = UIEdgeInsetsZero;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    //Set the number of the namespace/roomCode; 
    self.nameSpaceLabel.text = self.roomCode;
    
    
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
            
            cell.songLabel.text = [NSString stringWithFormat:@"%@ - %@", songTitle, artist];
            
           
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
    SIOSocket *socket = [[SocketKeeperSingleton sharedInstance]socket];
    [socket emit:@"q_add_request" args:argsArray];
    
    
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
