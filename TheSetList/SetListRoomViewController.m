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

@end

@implementation SetListRoomViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.selectedRows =[NSMutableIndexSet new];
    
    RadialGradiantView *radiantBackgroundView = [[RadialGradiantView alloc] initWithFrame:self.view.bounds];
    [self.backgroundView addSubview:radiantBackgroundView];
    
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
    
    
    UIVisualEffect *blurEffect;
    blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIVisualEffectView *visualEffectView;
    visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    visualEffectView.frame = self.searchBackgroundView.bounds;
    visualEffectView.alpha = 0;
    [self.setListView addSubview:visualEffectView];
    self.blurEffectView = visualEffectView;
    
    
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
    
    //If there are recieved tracks set up the next-song and queue accordingly. 
    if ([recievedtracks count]) {
        
        //Set the next song equal to the first object in the queue. 
        self.nextSongDic = [recievedtracks objectAtIndex:0];
        
        //set the queue equal to the tracks from indexes 1+
        NSRange range;
        range.location = 1;
        range.length = [recievedtracks count]-1;
        self.tracks = [recievedtracks subarrayWithRange:range];
        
        
        
        //If there are recieved tracks, make sure the next-views are not hidden.
        self.nextLabel.hidden = NO;
        self.nextSongListView.hidden = NO;
        self.nextSongAlbumArtImage.hidden = NO;
        
        
        if ([[self.nextSongDic objectForKey:@"socket"]isEqualToString:self.socketID]) {
            self.userSelectedNextIndicator.hidden = NO;
        }
        else
        {
            self.userSelectedNextIndicator.hidden = YES;
        }
        
        NSString *songTitle = [self.nextSongDic objectForKey:@"title"];
        NSString *artist = [[self.nextSongDic objectForKey:@"user"]objectForKey:@"username"];
        
        self.nextSongLabel.text = [NSString stringWithFormat:@"%@ - %@", artist, songTitle];
        
        //Init the cell image with the track's artwork.
        
        //If the imageURL sent to the app is null, then catch it. If not, display the image.
        if ([[self.nextSongDic objectForKey:@"artwork_url"] isEqual:[NSNull null]]) {
            //image is null
        }
        else
        {
            NSURL *imageURL = [NSURL URLWithString:[self.nextSongDic objectForKey:@"artwork_url"]];
            NSData *imageData = [NSData dataWithContentsOfURL:imageURL];
            UIImage *cellImage = [UIImage imageWithData:imageData];
                self.nextSongAlbumArtImage.image = cellImage;
        }

    }
    else {
        //If there are no recived tracks, make sure to hide the next-views.
        self.nextLabel.hidden = YES;
        self.nextSongListView.hidden = YES;
        self.nextSongAlbumArtImage.hidden = YES;
    }
    
    
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
            
            cell.songLabel.text = [NSString stringWithFormat:@"%@ - %@", artist, songTitle];
            
           
            if ([[track objectForKey:@"socket"]isEqualToString:self.socketID]) {
                cell.userSelectedQueueIndicator.hidden = NO;
            }
            else
            {
                cell.userSelectedQueueIndicator.hidden = YES;
            }
            
            
        }
        else if (tableView.tag == 2)
        {
            // Configure the cell...
            
            NSMutableDictionary *track = [[self.searchTracks objectAtIndex:indexPath.row]mutableCopy];
            cell.searchSongTitle.text = [track objectForKey:@"title"];
            cell.searchArtist.text = [[track objectForKey:@"user"]objectForKey:@"username"];
            
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


- (IBAction)displaySearchViewButtonPressed:(UIButton *)sender {
    
    UIImage *xImage = [UIImage imageNamed:@"xButtonThick"];
    UIImage *plusImage = [UIImage imageNamed:@"plusButton"];
    
    if (!self.plusButtonIsSelected) {
        
        [UIView animateWithDuration:.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.searchViewVertConst.constant = +10;
            [self.plusButton setBackgroundImage:xImage forState:UIControlStateNormal];
            self.searchBackgroundView.alpha = 1;
            self.blurEffectView.alpha = 1;
            [self.view layoutIfNeeded];
        }
                         completion:^(BOOL finished) {
                             self.plusButtonIsSelected = YES;
                         }];
        
    }
    else {//if plusbutton is selected
        [UIView animateWithDuration:.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.searchViewVertConst.constant = 528;
            [self.plusButton setBackgroundImage:plusImage forState:UIControlStateNormal];
            self.searchBackgroundView.alpha = 0;
            self.blurEffectView.alpha = 0;
            [self.view layoutIfNeeded];
        }
                         completion:^(BOOL finished) {
                            self.plusButtonIsSelected = NO;
                         }];
    }
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

@end
