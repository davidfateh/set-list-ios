//
//  SearchViewController.m
//  TheSetList
//
//  Created by Andrew Friedman on 1/18/15.
//  Copyright (c) 2015 Andrew Friedman. All rights reserved.
//

#import "SearchViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <CoreImage/CoreImage.h>
#import "SearchTableViewCell.h"
#import <SIOSocket/SIOSocket.h>
#import "SocketKeeperSingleton.h"
#import <SCAPI.h>

#define CLIENT_ID @"40da707152150e8696da429111e3af39"

@interface SearchViewController ()

@end

@implementation SearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.searchBar.delegate = self;
    
    self.nameSpaceLabel.text = self.roomCode;
    
    //Set the searchBars text color to white. 
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setTextColor:[UIColor whiteColor]];
    
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.tracks count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *ReusableIdentifier = @"Cell";
    SearchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ReusableIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    
    NSDictionary *track = [self.tracks objectAtIndex:indexPath.row];
    cell.songTitleLabel.text = [track objectForKey:@"title"];
    cell.artistLabel.text = [[track objectForKey:@"user"]objectForKey:@"username"];
    
    //If there is no picture available. Adds a Custom picture.
    if ([[track objectForKey:@"artwork_url"] isEqual:[NSNull null]]){
        
        cell.albumArtImage.image = [UIImage imageNamed:@"SoundCloudLogo"];
        
    }
    
    else
    {
        //Init the cell image with the track's artwork.
        UIImage *cellImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[track objectForKey:@"artwork_url"]]]];
        cell.albumArtImage.image = cellImage;
    }
    
    
    return cell;
    
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *track = [self.tracks objectAtIndex:indexPath.row];
    //Deselect the row animated so that the grey disappears
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSArray *argsArray = [[NSArray alloc]initWithObjects:track, nil];
    
    //Send the data to the server/socket.
    SIOSocket *socket = [[SocketKeeperSingleton sharedInstance]socket];
    [socket emit:@"q_add_request" args:argsArray];
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
             
             self.tracks = (NSArray *)jsonResponse;
             [self.tableView reloadData];
             
         }
     }];
    
    
}

-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    self.searchBar.text = nil;
    self.tracks = nil;
    [self.tableView reloadData];
    [searchBar resignFirstResponder];
}



- (IBAction)exitButtonPressed:(UIButton *)sender
{
    [self dismissViewControllerAnimated:YES completion:^{
        //VC dismissed
    }];
}
@end
