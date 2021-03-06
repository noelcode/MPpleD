//
//  mpdPlaylistTableViewController.m
//  MPpleD
//
//  Created by KYLE HERSHEY on 2/14/13.
//  Copyright (c) 2013 Kyle Hershey. All rights reserved.
//

#import "mpdPlaylistTableViewController.h"
#import <mpd/client.h>

@interface mpdPlaylistTableViewController ()

@end

@implementation mpdPlaylistTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.leftBarButtonItem=self.editButtonItem;
    
}

-(void)viewDidAppear:(BOOL)animated
{
    [self updateInfo];
    
    self.updateTimer = [NSTimer scheduledTimerWithTimeInterval: 5.0 target: self selector:@selector(updateInfo) userInfo: nil repeats:YES];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [self.updateTimer invalidate];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//I know this is pretty useless, but needed for the timer in viewDidAppear
-(void)updateInfo
{
    [self.tableView reloadData];
}

/*
 * Passive Connection Data loading
 *
 */


-(void)initializeConnection
{
    mpdConnectionData *connection = [mpdConnectionData sharedManager];
    self.host = [connection.host UTF8String];
    self.port = [connection.port intValue];
    self.conn = mpd_connection_new(self.host, self.port, 3000);
}



#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger pos;
    [self initializeConnection];
    if (mpd_connection_get_error(self.conn) != MPD_ERROR_SUCCESS)
    {
        NSLog(@"Connection error");
        mpd_connection_free(self.conn);
        [self initializeConnection];
        return 0;
    }
    struct mpd_status * status;
    mpd_send_status(self.conn);

    status = mpd_recv_status(self.conn);
    
    if (status == NULL)
    {
        NSLog(@"Connection error status");
        mpd_connection_free(self.conn);
        [self initializeConnection];
        return 0;
    }

    pos = mpd_status_get_queue_length(status);
    mpd_connection_free(self.conn);
    self.prevRowCount = self.rowCount;
    self.rowCount = pos;
    return pos;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"playlistItem";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    [self updateRowCount];
    //should probably use queue number instead, but this works fine, especially with the timer
    if(self.rowCount!=self.prevRowCount)
    {
        [self.tableView reloadData];
    }
     
    if(indexPath.row <[tableView numberOfRowsInSection:0])
    {
        [self initializeConnection];
        struct mpd_song *nextSong = malloc(sizeof(struct mpd_song));
        nextSong=mpd_run_get_queue_song_pos(self.conn, indexPath.row);
        [[cell detailTextLabel] setText:[[NSString alloc] initWithUTF8String:mpd_song_get_tag(nextSong, MPD_TAG_ARTIST, 0)]];
        [[cell textLabel] setText:[[NSString alloc] initWithUTF8String:mpd_song_get_tag(nextSong, MPD_TAG_TITLE, 0)]];
        
    }
    struct mpd_status * status;
    mpd_send_status(self.conn);  
    
    status = mpd_recv_status(self.conn);
    
    if (status != NULL)
    {
        if(mpd_status_get_song_pos(status)==indexPath.row)
        {
            [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
            cell.textLabel.font  = [UIFont boldSystemFontOfSize:18];
            cell.detailTextLabel.font = [UIFont boldSystemFontOfSize:14];
        }
        else
        {
            [cell setAccessoryType:UITableViewCellAccessoryNone];
            cell.textLabel.font = [UIFont systemFontOfSize:18];
            cell.detailTextLabel.font = [UIFont systemFontOfSize:14];
        }
    }


    mpd_connection_free(self.conn);
    return cell;
}



// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}



// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self initializeConnection];
        if (mpd_connection_get_error(self.conn) != MPD_ERROR_SUCCESS)
        {
            NSLog(@"Connection error");
            mpd_connection_free(self.conn);
            [self initializeConnection];
            return;
        }
        
        if(mpd_run_delete(self.conn, indexPath.row)){
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
    }
}



// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    [self initializeConnection];
    if (mpd_connection_get_error(self.conn) != MPD_ERROR_SUCCESS)
    {
        NSLog(@"Connection error");
        mpd_connection_free(self.conn);
        [self initializeConnection];
        return;
    }
    mpd_run_move(self.conn, fromIndexPath.row, toIndexPath.row);
    [self.tableView reloadData];
    
    
}


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate


//Plays song at that position
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{   
    [self initializeConnection];
    if (mpd_connection_get_error(self.conn) != MPD_ERROR_SUCCESS)
    {
        NSLog(@"Connection error");
        mpd_connection_free(self.conn);
        [self initializeConnection];
        return;
    }

    mpd_run_play_pos(self.conn,indexPath.row);
    mpd_connection_free(self.conn);
    [self.tableView reloadData];    
}

-(void)updateRowCount
{
    NSInteger pos;
    [self initializeConnection];
    if (mpd_connection_get_error(self.conn) != MPD_ERROR_SUCCESS)
    {
        NSLog(@"Connection error");
        mpd_connection_free(self.conn);
        [self initializeConnection];
        return;
    }
    struct mpd_status * status;
    mpd_send_status(self.conn);
    
    status = mpd_recv_status(self.conn);
    
    if (status == NULL)
    {
        NSLog(@"Connection error status");
        mpd_connection_free(self.conn);
        [self initializeConnection];
        return;
    }
    
    pos = mpd_status_get_queue_length(status);
    mpd_connection_free(self.conn);
    self.prevRowCount = self.rowCount;
    self.rowCount = pos;
    
}


//Clear the Play Queue
-(IBAction)clearQueue:(id)sender
{
    [self initializeConnection];
    if (mpd_connection_get_error(self.conn) != MPD_ERROR_SUCCESS)
    {
        NSLog(@"Connection error");
        mpd_connection_free(self.conn);
        [self initializeConnection];
        return;
    }
    mpd_send_clear(self.conn);
    mpd_connection_free(self.conn);
    [self.tableView reloadData];
}




@end
