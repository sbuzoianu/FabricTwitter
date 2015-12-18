//
//  ViewController.m
//  FabricTwitter
//
//  Created by Stefan on 05/12/15.
//  Copyright © 2015 Stefan. All rights reserved.
//

#import "ViewController.h"
#import <TwitterKit/TwitterKit.h>


@interface ViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@property (weak, nonatomic) TWTRLogInButton *logInButton;
@property (strong, nonatomic) UITableView * tableView;
@property (strong, nonatomic) NSArray *tweets;
@property (strong, nonatomic) UITextField *searchTextField;
@property (strong,nonatomic) NSString *searchText;

@property (strong,nonatomic) NSDictionary * searchedTweets;
@property (nonatomic,strong) NSMutableArray *results;


@end

@implementation ViewController
@synthesize searchTextField=_searchTextField;
@synthesize searchText=_searchText;

- (void)viewDidLoad {
    [super viewDidLoad];

    NSString *userID = [Twitter sharedInstance].sessionStore.session.userID;
    TWTRAPIClient *client = [[TWTRAPIClient alloc] initWithUserID:userID];

    
// UITableView
    CGFloat x = 0;
    CGFloat y = 50;
    CGFloat width = self.view.frame.size.width;
    CGFloat height = self.view.frame.size.height - 50;
    CGRect tableFrame = CGRectMake(x, y, width, height);
    UITableView *tableView=[[UITableView alloc] initWithFrame:tableFrame style:UITableViewStylePlain];
    self.tableView=tableView;
    [self.tableView registerClass:[TWTRTweetTableViewCell class] forCellReuseIdentifier:@"Cell"];
    self.tableView.hidden = YES;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];
    
// definim un searchTextField
    UITextField *searchTextField = [[UITextField alloc] initWithFrame:CGRectMake(5,20, width, 34)];
    self.searchTextField=searchTextField;
    
    [self.searchTextField setBackgroundColor:[UIColor colorWithRed:64.0f/255.0f green:153.0f/255.0f blue:255.0f/255.0f alpha:1]];
    self.searchTextField.font = [UIFont systemFontOfSize:15];
    self.searchTextField.textAlignment=NSTextAlignmentCenter;
    self.searchTextField.placeholder = @"#hashtag";
    [self.searchTextField setTextColor:[UIColor whiteColor]];
    self.searchTextField.keyboardType = UIKeyboardTypeDefault;
    self.searchTextField.returnKeyType = UIReturnKeyDone;
    self.searchTextField.hidden=YES;
    
//  VC este delegate-ul pentru searchTextField
    self.searchTextField.delegate=self;
    [self.view addSubview:self.searchTextField];

    

//// logare invizibila
////  [[Twitter sharedInstance] logInWithCompletion:^(TWTRSession *session, NSError *error) {
    TWTRLogInButton *logInButton = [TWTRLogInButton buttonWithLogInCompletion:^(TWTRSession *session, NSError *error) {
        if (session) {
            NSLog(@"signed in as %@ , %@", [session userName], session.userID);
            self.logInButton.hidden=YES;
            self.tableView.hidden=NO;
            self.searchTextField.hidden=YES;
            [self loadQuery:client];


        } else {
            NSLog(@"Login error: %@", [error localizedDescription]);
        }
    }];
    logInButton.center = self.view.center;
    self.logInButton = logInButton;
    [self.view addSubview:logInButton];
    

    
    // aducem un singur tweet din userId=20
    [client loadTweetWithID:@"20" completion:^(TWTRTweet *tweet, NSError *error) {
    }];
    
    // aducem mai multe tweet-uri din userId-uri diferite =20, 510908133917487104 si 31
    NSArray *tweetIDs = @[@"20", @"510908133917487104", @"31", @"1234"];
    [client loadTweetsWithIDs:tweetIDs completion:^(NSArray *tweets, NSError *error) {
    }];
    
    // aducem user cu id=sbuzoianu_ro - problema xcode 7.2
    // [client loadUserWithID:userID completion:^(TWTRUser *user, NSError *error) { }];
    
#pragma mark - Twitter request manually created
// show - aduce tweet-ul userului specificat in NSDictionary
//    NSDictionary *params = @{@"id" : @"20"};
//    NSString *statusesShowEndpoint = @"https://api.twitter.com/1.1/statuses/show.json";
    
    
// home_timeline - aduce cel mult 800 de tweet-uri ale userului
//
//    NSString *statusesShowEndpoint = @"https://api.twitter.com/1.1/statuses/home_timeline.json";
//    NSDictionary *params = @{};
//    NSError *clientError;
//    
//    NSURLRequest *request = [client URLRequestWithMethod:@"GET" URL:statusesShowEndpoint parameters:params error:&clientError];
//    
//    if (request) {
//        [client sendTwitterRequest:request completion:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
//            if (data) {
//                NSError *jsonError;
//                NSArray *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];
//                self.tweets=[TWTRTweet tweetsWithJSONArray:json];
//                [self.tableView reloadData];
//                
//                NSLog(@"s-a extras din feed: %@", self.tweets);
//            }
//            else {
//                NSLog(@"Error: %@", connectionError);
//            }
//        }];
//    }
//    
//    else {
//        NSLog(@"Error: %@", clientError);
//    }
//
}

# pragma mark - Load Twitter search query
#define RESULTS_PERPAGE @"10"

- (void) loadQuery:(TWTRAPIClient*) client{
    NSString *url = @"https://api.twitter.com/1.1/search/tweets.json";
    self.searchText=@"apple";
    NSString *encodedQuery = [self.searchText stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSDictionary *parameters = @{@"count" : RESULTS_PERPAGE,
                                 @"q" : encodedQuery};
    NSError *clientError;
    NSURLRequest *req = [client URLRequestWithMethod:@"GET" URL:url parameters:parameters error:&clientError];

    if (req) {
        [client sendTwitterRequest:req completion:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            if (data) {
                NSError *jsonError;
                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];
                self.results=json[@"statuses"];              
                self.tweets=[TWTRTweet tweetsWithJSONArray:self.results];
                [self.tableView reloadData];
                
            }
            else {
                NSLog(@"Error aici : %@", connectionError);
            }
        }];
        NSLog(@"a reusit req rez=%@", req);
    }
    
    else {
        NSLog(@"Error: %@", clientError);
    }

    
}

#pragma mark - UITableView


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.tweets count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    TWTRTweetTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[TWTRTweetTableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    [cell configureWithTweet:self.tweets[indexPath.row]];
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [TWTRTweetTableViewCell heightForTweet:self.tweets[indexPath.row] width:self.tableView.bounds.size.width];
}


#pragma mark - UITextFieldDelegate
- (BOOL) textFieldShouldReturn:(UITextField *)textField{
    if (textField==self.searchTextField){
        [textField resignFirstResponder];
        self.searchText=textField.text;
    }
    return true;
    
}
@end
