//
//  JWPublicTableViewController.m
//  JamWDev
//
//  Created by brendan kerr on 4/18/16.
//  Copyright © 2016 JOSEPH KERR. All rights reserved.
//

/*
 
 Public table view controller is a space where users can search for another user, see the tracks they have uploaded, and download them to use in their own sessions.
 
 PTVC will interact with AWS Dynamo and AWS S3 to 1) list the jam tracks the user being queryied has uploaded and 2) download the selected jam track from the correct bucket once the user chooses their desired track for a new session.
 
 
 */

#import "JWPublicTableViewController.h"
#import "JWPublicResultsTableViewController.h"
#import "JWAWSIdentityManager.h"
#import "JWAWSDataRetrivalManager.h"

@interface JWPublicTableViewController() <UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating> {
    
    BOOL _loggedIn;
}

@property (nonatomic) UIView *blockingView;
@property (nonatomic) UISearchController *search;
@property (nonatomic) UISearchBar *customSearchBar;
@property (nonatomic) JWPublicResultsTableViewController *results;
@property (nonatomic, copy) NSString *searchString;
@property (nonatomic) JWAWSDataRetrivalManager *dataManager;


@property (nonatomic) NSArray *queryResultList;

@end
@implementation JWPublicTableViewController


-(void)viewDidLoad {
    NSLog(@"%s", __func__);
    [super viewDidLoad];
    
    if ([[JWAWSIdentityManager sharedInstance] isLoggedInWithFacebook]) {
        NSLog(@"%s, Is Loggin In With Facebook", __func__);
        //self.blockingView.hidden = NO;
        _loggedIn = YES;
    } else {
        _loggedIn = NO;
    }
    
    self.dataManager = [JWAWSDataRetrivalManager new];
        
    UIView *backgroundView = [UIView new];
    backgroundView.backgroundColor = [UIColor blackColor];
    self.tableView.backgroundView = backgroundView;
    
    _results = [[JWPublicResultsTableViewController alloc] init];
    _search = [[UISearchController alloc] initWithSearchResultsController:_results];
    NSLog(@"%@", NSStringFromCGRect(_search.searchBar.frame));
    self.search.searchResultsUpdater = self;
    self.search.hidesNavigationBarDuringPresentation = NO;
    [self.search.searchBar sizeToFit];
    self.navigationItem.titleView = self.search.searchBar;
    
    
    // we want to be the delegate for our filtered table so didSelectRowAtIndexPath is called for both tables
    self.results.tableView.delegate = self;
    self.search.delegate = self;
    self.search.dimsBackgroundDuringPresentation = NO; // default is YES
    self.search.searchBar.delegate = self; // so we can monitor text changes + others
    
    self.definesPresentationContext = YES;  // know where you want UISearchController to be displayed
}



//-(void)blockUserFromLogin {
//    
//    NSLog(@"%@", NSStringFromCGRect(self.view.frame));
//    self.blockingView = [[UIView alloc] initWithFrame:self.view.frame];
//    self.blockingView.backgroundColor = [UIColor blackColor];
//    self.blockingView.alpha = 0.5;
//}




- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSLog(@"%s", __func__);
    
    
    // restore the searchController's active state
//    if (self.searchControllerWasActive) {
//        self.searchController.active = self.searchControllerWasActive;
//        _searchControllerWasActive = NO;
//        
//        if (self.searchControllerSearchFieldWasFirstResponder) {
//            [self.searchController.searchBar becomeFirstResponder];
//            _searchControllerSearchFieldWasFirstResponder = NO;
//        }
//    }
}




#pragma mark - TABLE VIEW DELEGATE


/*
 -(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
 
 }
/*
 -(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
 
 }
 /*
 - (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section  {
 
 }
 /*
 -(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
 
 }
 /*
 -(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
 
 }
 /*
 -(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
 
 }
 
 /*
 - (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
 
 }
 
 /*
 -(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
 
 }
 /*
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 
 }
 /*
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
 
 }
 /*
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 
 }
 /*
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 
 }
 
 
 */


#pragma mark - SEARCH BAR UPDATE PROTOCOL

-(void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    
    NSString *searchText = searchController.searchBar.text;
    NSLog(@"%@", searchText);
    
    [self.dataManager updateCurrentSearch:searchText];
    
//    // hand over the filtered results to our search results table
//    APLResultsTableController *tableController = (APLResultsTableController *)self.searchController.searchResultsController;
//    tableController.filteredProducts = searchResults;
//    [tableController.tableView reloadData];
    
}

/*
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    // update the filtered array based on the search text
    NSString *searchText = searchController.searchBar.text;
    NSMutableArray *searchResults = [self.products mutableCopy];
    
    // strip out all the leading and trailing spaces
    NSString *strippedString = [searchText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    // break up the search terms (separated by spaces)
    NSArray *searchItems = nil;
    if (strippedString.length > 0) {
        searchItems = [strippedString componentsSeparatedByString:@" "];
    }
    
    // build all the "AND" expressions for each value in the searchString
    //
    NSMutableArray *andMatchPredicates = [NSMutableArray array];
    
    for (NSString *searchString in searchItems) {
        // each searchString creates an OR predicate for: name, yearIntroduced, introPrice
        //
        // example if searchItems contains "iphone 599 2007":
        //      name CONTAINS[c] "iphone"
        //      name CONTAINS[c] "599", yearIntroduced ==[c] 599, introPrice ==[c] 599
        //      name CONTAINS[c] "2007", yearIntroduced ==[c] 2007, introPrice ==[c] 2007
        //
        NSMutableArray *searchItemsPredicate = [NSMutableArray array];
        
        // Below we use NSExpression represent expressions in our predicates.
        // NSPredicate is made up of smaller, atomic parts: two NSExpressions (a left-hand value and a right-hand value)
        
        // name field matching
        NSExpression *lhs = [NSExpression expressionForKeyPath:@"title"];
        NSExpression *rhs = [NSExpression expressionForConstantValue:searchString];
        NSPredicate *finalPredicate = [NSComparisonPredicate
                                       predicateWithLeftExpression:lhs
                                       rightExpression:rhs
                                       modifier:NSDirectPredicateModifier
                                       type:NSContainsPredicateOperatorType
                                       options:NSCaseInsensitivePredicateOption];
        [searchItemsPredicate addObject:finalPredicate];
        
        // yearIntroduced field matching
        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
        numberFormatter.numberStyle = NSNumberFormatterNoStyle;
        NSNumber *targetNumber = [numberFormatter numberFromString:searchString];
        if (targetNumber != nil) {   // searchString may not convert to a number
            lhs = [NSExpression expressionForKeyPath:@"yearIntroduced"];
            rhs = [NSExpression expressionForConstantValue:targetNumber];
            finalPredicate = [NSComparisonPredicate
                              predicateWithLeftExpression:lhs
                              rightExpression:rhs
                              modifier:NSDirectPredicateModifier
                              type:NSEqualToPredicateOperatorType
                              options:NSCaseInsensitivePredicateOption];
            [searchItemsPredicate addObject:finalPredicate];
            
            // price field matching
            lhs = [NSExpression expressionForKeyPath:@"introPrice"];
            rhs = [NSExpression expressionForConstantValue:targetNumber];
            finalPredicate = [NSComparisonPredicate
                              predicateWithLeftExpression:lhs
                              rightExpression:rhs
                              modifier:NSDirectPredicateModifier
                              type:NSEqualToPredicateOperatorType
                              options:NSCaseInsensitivePredicateOption];
            [searchItemsPredicate addObject:finalPredicate];
        }
        
        // at this OR predicate to our master AND predicate
        NSCompoundPredicate *orMatchPredicates = [NSCompoundPredicate orPredicateWithSubpredicates:searchItemsPredicate];
        [andMatchPredicates addObject:orMatchPredicates];
    }
    
    // match up the fields of the Product object
    NSCompoundPredicate *finalCompoundPredicate =
    [NSCompoundPredicate andPredicateWithSubpredicates:andMatchPredicates];
    searchResults = [[searchResults filteredArrayUsingPredicate:finalCompoundPredicate] mutableCopy];
    
    // hand over the filtered results to our search results table
    APLResultsTableController *tableController = (APLResultsTableController *)self.searchController.searchResultsController;
    tableController.filteredProducts = searchResults;
    [tableController.tableView reloadData];
}

 */

#pragma mark - SEARCH BAR DELEGATE

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

-(void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    NSLog(@"%s", __func__);
    NSLog(@"%@", NSStringFromCGRect(self.navigationItem.titleView.frame));
}

#pragma mark - QUEUE

-(void)updateUserSearchWithString:(NSString *)currentQuery {
    NSLog(@"%s", __func__);
    
    
    
}

@end
























