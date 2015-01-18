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

@interface SetListRoomViewController ()

@end

@implementation SetListRoomViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.tableView.layoutMargins = UIEdgeInsetsZero;
    
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
    }
    
    //else, display the current songs info
    else
    {
        
        self.currentSongLabel.text = [track objectForKey:@"title"];
        
        self.currentArtistLabel.text = [[track objectForKey:@"user"]objectForKey:@"username"];
        
        //If there is no picture available. Adds a Custom picture.
        if ([[track objectForKey:@"artwork_url"] isEqual:[NSNull null]]){
            
            self.currentAlbumArtImage.image = [UIImage imageNamed:@"SoundCloudLogo"];
            
        }
        
        else
        {
            //Init the cell image with the track's artwork.
            UIImage *cellImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[track objectForKey:@"artwork_url"]]]];
            self.currentAlbumArtImage.image = cellImage;
        }
        
    }
    
}

- (void)receiveUpdateBNotification:(NSNotification *)notification
{
    NSArray *tracks = [[SocketKeeperSingleton sharedInstance]setListTracks];
    self.tracks = tracks;
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

@end
