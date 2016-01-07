#import "ViewController.h"
#import <TwitterKit/TwitterKit.h>


@interface ViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@property (weak, nonatomic) TWTRLogInButton *logInButton; // utilizat daca am autentificare manuala
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

    [self deseneaza];
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:refreshControl];
    
    [self interogareTwitter];
    
}

- (void)refresh:(UIRefreshControl *)refreshControl {
    [self interogareTwitter];
    [refreshControl endRefreshing];
}

- (void) deseneaza{
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
    UITextField *searchTextField = [[UITextField alloc] initWithFrame:CGRectMake(2,20, width-4, 34)];
    searchTextField.borderStyle=UITextBorderStyleRoundedRect;
    searchTextField.backgroundColor=[UIColor colorWithRed:14.0f/255.0f green:153.0f/255.0f blue:255.0f/255.0f alpha:1];
    searchTextField.font = [UIFont systemFontOfSize:15];
    searchTextField.textAlignment=NSTextAlignmentCenter;
    searchTextField.attributedPlaceholder=[[NSAttributedString alloc] initWithString:@"#hashtag" attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
    searchTextField.textColor=[UIColor whiteColor];
    searchTextField.keyboardType = UIKeyboardTypeDefault;
    searchTextField.returnKeyType = UIReturnKeyDone;
    searchTextField.autocorrectionType=UITextAutocorrectionTypeNo;
    self.searchTextField=searchTextField;
    //  VC este delegate-ul pentru searchTextField
    searchTextField.delegate=self;
    [self.view addSubview:searchTextField];

}


# pragma mark - Load Twitter search query
#define RESULTS_PERPAGE @"10"

- (void) interogareTwitter{
    
    NSString *userID = [Twitter sharedInstance].sessionStore.session.userID;
    TWTRAPIClient *client = [[TWTRAPIClient alloc] initWithUserID:userID];

    [[Twitter sharedInstance] logInWithCompletion:^(TWTRSession *session, NSError *error) {
        if (session) {
            self.tableView.hidden=NO; // activez daca merge autentificare
            
        } else {
            NSLog(@"Login error: %@", [error localizedDescription]);
        }
    }];

    
    NSString *url = @"https://api.twitter.com/1.1/search/tweets.json";
    
    if ([self.searchText length] == 0){
    self.searchText=@"romania";
    }
    
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
        NSLog(@"s-a introdus %@", self.searchText);
        [self interogareTwitter];
    }
    return true;
    
}
@end
