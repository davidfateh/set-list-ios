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
#import "SearchViewController.h"
#import "RadialGradiantView.h"

@interface SetListRoomViewController ()
@property (strong, nonatomic) NSString *socketID;
@end

@implementation SetListRoomViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    RadialGradiantView *radiantBackgroundView = [[RadialGradiantView alloc] initWithFrame:self.view.bounds];
    [self.backgroundView addSubview:radiantBackgroundView];

    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.tableView.layoutMargins = UIEdgeInsetsZero;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    //Set the number of the namespace/roomCode; 
    self.nameSpaceLabel.text = self.roomCode;
    
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
    
    
    return cell;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.tracks count];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"toSearchVC"]) {
        SearchViewController *searchVC = segue.destinationViewController;
        searchVC.roomCode = self.roomCode;
    }
}

@end
