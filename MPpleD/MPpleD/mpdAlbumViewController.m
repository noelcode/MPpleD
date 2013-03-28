//
//  mpdAlbumViewController.m
//  MPpleD
//
//  Created by KYLE HERSHEY on 2/20/13.
//  Copyright (c) 2013 Kyle Hershey. All rights reserved.
//

#import "mpdAlbumViewController.h"
#import "mpdSongTableViewController.h"

@interface mpdAlbumViewController ()

@end

@implementation mpdAlbumViewController

- (void)awakeFromNib
{
    [super awakeFromNib];
    if(self.artistFilter)
    {
        self.dataController = [[albumList alloc] initWithArtist:self.artistFilter];
    }
    else{
        self.dataController = [[albumList alloc] init];
    }
}

-(void)setArtistFilter:(NSString *)newArtistFilter
{
    
    if (_artistFilter != newArtistFilter) {
        
        _artistFilter = newArtistFilter;
        
        self.dataController = [[albumList alloc] initWithArtist:newArtistFilter];
        
    }
    
}

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
    self.sections = [NSArray arrayWithObjects:@"all",@"#", @"a", @"b", @"c", @"d", @"e", @"f", @"g", @"h", @"i", @"j", @"k", @"l", @"m", @"n", @"o", @"p", @"q", @"r", @"s", @"t", @"u", @"v", @"w", @"x", @"y", @"z", nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 28;
    //return 1;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return self.sections;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString*)title atIndex:(NSInteger)index {
    return index;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section==0)
    {
        return nil;
    }
    else
    {
        NSArray *sectionArray = [self.dataController.albums filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF beginswith[c] %@", [self.sections objectAtIndex:section]]];
        NSUInteger rowCount = [sectionArray count];
        if(section==2 && self.artistFilter)
            rowCount = rowCount-1;
        if(rowCount <= 0)
            return nil;
        else
            return [self.sections objectAtIndex:section];
    }
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(section==0 && self.artistFilter)
        return 1;
    else if(section==2 && self.artistFilter)
    {
        NSArray *sectionArray = [self.dataController.albums filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF beginswith[c] %@", [self.sections objectAtIndex:section]]];
        //rowCount = [sectionArray count];
        return [sectionArray count]-1;
    }
    else
    {
        NSArray *sectionArray = [self.dataController.albums filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF beginswith[c] %@", [self.sections objectAtIndex:section]]];
        //rowCount = [sectionArray count];
        return [sectionArray count];
    }
    //return [self.dataController albumCount];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"albumItem";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];

    // Configure the cell...
    //[[cell textLabel] setText:[self.dataController albumAtIndex:indexPath.row]];
    [[cell textLabel] setText:[self.dataController albumAtSectionAndIndex:indexPath.section row:indexPath.row]];
    
    UILongPressGestureRecognizer *longPressGesture =
    [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    [cell addGestureRecognizer:longPressGesture];
    
    return cell;

    
    //return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"ShowAlbumSongs"]) {
        
        mpdSongTableViewController *songViewController = [segue destinationViewController];
        
        
        //if(self.artistFilter && [self.tableView indexPathForSelectedRow].row==0)
        if(self.artistFilter && ([[self.dataController albumAtSectionAndIndex:[self.tableView indexPathForSelectedRow].section row:[self.tableView indexPathForSelectedRow].row]isEqual:@"All"]))
        {
            songViewController.artistFilter = self.artistFilter;
            songViewController.navigationItem.title = self.artistFilter;
            
        }
        else{
            //songViewController.albumFilter = [self.dataController albumAtIndex:[self.tableView indexPathForSelectedRow].row];
            //songViewController.navigationItem.title = [self.dataController albumAtIndex:[self.tableView indexPathForSelectedRow].row];
            songViewController.albumFilter = [self.dataController albumAtSectionAndIndex:[self.tableView indexPathForSelectedRow].section row:[self.tableView indexPathForSelectedRow].row];
            songViewController.navigationItem.title = [self.dataController albumAtSectionAndIndex:[self.tableView indexPathForSelectedRow].section row:[self.tableView indexPathForSelectedRow].row];
        }
    }
    
}

-(IBAction)backToAlbumClick:(UIStoryboardSegue *)segue
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)longPress:(UILongPressGestureRecognizer *)gesture
{
	// only when gesture was recognized, not when ended
	if (gesture.state == UIGestureRecognizerStateBegan)
	{
		// get affected cell
		UITableViewCell *cell = (UITableViewCell *)[gesture view];
        
		// get indexPath of cell
		NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        
		// do something with this action
        [self.dataController addAlbumAtSectionAndIndexToQueue:indexPath.section row:indexPath.row artist:self.artistFilter];
	}
}

@end
