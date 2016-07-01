
#import "ViewController.h"
#import <WebKit/WebKit.h>
#import "JumpViewController.h"

@interface ViewController () <WKScriptMessageHandler, WKNavigationDelegate, WKUIDelegate>

@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) UIProgressView *progressView;

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.edgesForExtendedLayout = UIRectEdgeNone;
  self.automaticallyAdjustsScrollViewInsets = NO;
  
  WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
  // 设置偏好设置
  config.preferences = [[WKPreferences alloc] init];
  // 默认为0
  config.preferences.minimumFontSize = 10;
  // 默认认为YES
  config.preferences.javaScriptEnabled = YES;
  // 在iOS上默认为NO，表示不能自动通过窗口打开
  config.preferences.javaScriptCanOpenWindowsAutomatically = NO;


  // web内容处理池
  config.processPool = [[WKProcessPool alloc] init];

  // 通过JS与webview内容交互
  config.userContentController = [[WKUserContentController alloc] init];
  // 注入JS对象名称AppModel，当JS通过AppModel来调用时，
  // 我们可以在WKScriptMessageHandler代理中接收到
  [config.userContentController addScriptMessageHandler:self name:@"AppModel"];



        //通过默认的构造器来创建对象
  self.webView = [[WKWebView alloc] initWithFrame:self.view.bounds
                                    configuration:config];
  NSURL *path = [[NSBundle mainBundle] URLForResource:@"test" withExtension:@"html"];
  [self.webView loadRequest:[NSURLRequest requestWithURL:path]];
  [self.view addSubview:self.webView];
  
  // 导航代理
  self.webView.navigationDelegate = self;
  // 与webview UI交互代理
  self.webView.UIDelegate = self;
  
  // 添加KVO监听
  [self.webView addObserver:self
                 forKeyPath:@"loading"
                    options:NSKeyValueObservingOptionNew
                    context:nil];
  [self.webView addObserver:self
                 forKeyPath:@"title"
                    options:NSKeyValueObservingOptionNew
                    context:nil];
  [self.webView addObserver:self
                 forKeyPath:@"estimatedProgress"
                    options:NSKeyValueObservingOptionNew
                    context:nil];
  
  // 添加进入条
  self.progressView = [[UIProgressView alloc] init];
  self.progressView.frame = self.view.bounds;
  [self.view addSubview:self.progressView];
  self.progressView.backgroundColor = [UIColor blackColor];
  
//添加导航栏按钮
  self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"后退" style:UIBarButtonItemStyleDone target:self action:@selector(goback)];
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"前进" style:UIBarButtonItemStyleDone target:self action:@selector(gofarward)];
}

- (void)goback {
  if ([self.webView canGoBack]) {
    [self.webView goBack];
  }
}

- (void)gofarward {
  if ([self.webView canGoForward]) {
    [self.webView goForward];
  }
}

#pragma mark - WKScriptMessageHandler
- (void)userContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message {
  if ([message.name isEqualToString:@"AppModel"]) {
    // 打印所传过来的参数，只支持NSNumber, NSString, NSDate, NSArray,
    // NSDictionary, and NSNull类型
    NSLog(@"9999===%@", message.body);
          //跳转到指定控制器中
      JumpViewController *root = [[JumpViewController alloc]init];
      root.str = message.body;
      [self.navigationController pushViewController:root animated:YES];
  }
}




#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSString *,id> *)change
                       context:(void *)context {
  if ([keyPath isEqualToString:@"loading"]) {
    NSLog(@"loading");
  } else if ([keyPath isEqualToString:@"title"]) {
    self.title = self.webView.title;
  } else if ([keyPath isEqualToString:@"estimatedProgress"]) {
    NSLog(@"progress: %f", self.webView.estimatedProgress);
    self.progressView.progress = self.webView.estimatedProgress;
  }

  if (!self.webView.loading) {
    // 手动调用JS代码
    // 每次页面完成都弹出来，大家可以在测试时再打开
    NSString *js = @"callJsAlert()";
    [self.webView evaluateJavaScript:js completionHandler:^(id _Nullable response, NSError * _Nullable error) {
      NSLog(@"response: %@ error: %@", response, error);
    }];
    
    [UIView animateWithDuration:0.5 animations:^{
      self.progressView.alpha = 0;
    }];
  }
}

#pragma mark - WKNavigationDelegate
    // 请求开始前，会先调用此代理方法
    // 与UIWebView的
    // - (BOOL)webView:(UIWebView *)webView
    // shouldStartLoadWithRequest:(NSURLRequest *)request
    // navigationType:(UIWebViewNavigationType)navigationType;
    // 类型，在请求先判断能不能跳转（请求）


- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:
(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
  NSString *hostname = navigationAction.request.URL.host.lowercaseString;
  if (navigationAction.navigationType == WKNavigationTypeLinkActivated
      && ![hostname containsString:@".lanou.com"]) {
// 对于跨域，需要手动跳转
    [[UIApplication sharedApplication] openURL:navigationAction.request.URL];
    
    // 不允许web内跳转
    decisionHandler(WKNavigationActionPolicyCancel);
  } else {
    self.progressView.alpha = 1.0;
    decisionHandler(WKNavigationActionPolicyAllow);
  }
  
    NSLog(@"00===%s", __FUNCTION__);
}


    // 在响应完成时，会回调此方法
    // 如果设置为不允许响应，web内容就不会传过来
- (void)webView:(WKWebView *)webView
decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse
decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
  decisionHandler(WKNavigationResponsePolicyAllow);
  NSLog(@"11===%s", __FUNCTION__);
}


// 开始导航跳转时会回调
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation {
    NSLog(@"22===%s", __FUNCTION__);
}

    // 接收到重定向时会回调
- (void)webView:(WKWebView *)webView
didReceiveServerRedirectForProvisionalNavigation:(null_unspecified WKNavigation *)navigation {
    NSLog(@"33===%s", __FUNCTION__);
}


    // 导航失败时会回调
- (void)webView:(WKWebView *)webView
didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"44===%s", __FUNCTION__);
}


// 页面内容到达main frame时回调
- (void)webView:(WKWebView *)webView didCommitNavigation:(null_unspecified WKNavigation *)navigation {
    NSLog(@"55===%s", __FUNCTION__);
}


// 导航完成时，会回调（也就是页面载入完成了）
- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation {
    NSLog(@"66===%s", __FUNCTION__);
}


    // 导航失败时会回调
- (void)webView:(WKWebView *)webView didFailNavigation:
(null_unspecified WKNavigation *)navigation withError:(NSError *)error {
  NSLog(@"77===%s", __FUNCTION__);
}


    // 对于HTTPS的都会触发此代理，如果不要求验证，传默认就行
    // 如果需要证书验证，与使用AFN进行HTTPS证书验证是一样的

- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:
(NSURLAuthenticationChallenge *)challenge completionHandler:
(void (^)(NSURLSessionAuthChallengeDisposition disposition,
          NSURLCredential *__nullable credential))completionHandler {
    NSLog(@"88===%s", __FUNCTION__);
  completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
}


// 9.0才能使用，web内容处理中断时会触发
- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView {
    NSLog(@"99===%s", __FUNCTION__);
}

#pragma mark - WKUIDelegate
- (void)webViewDidClose:(WKWebView *)webView {
     NSLog(@"99===%s", __FUNCTION__);
}








    // 在JS端调用alert函数时，会触发此代理方法。
    // JS端调用alert时所传的数据可以通过message拿到
    // 在原生得到结果后，需要回调JS，是通过completionHandler回调
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message
initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
  NSLog(@"100===%s", __FUNCTION__);
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"alert" message:@"JS调用alert"
                                                          preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:
                    UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    completionHandler();
  }]];
  
  [self presentViewController:alert animated:YES completion:NULL];
  NSLog(@"%@", message);
}

    // JS端调用confirm函数时，会触发此方法
    // 通过message可以拿到JS端所传的数据
    // 在iOS端显示原生alert得到YES/NO后
    // 通过completionHandler回调给JS端
- (void)webView:(WKWebView *)webView
runJavaScriptConfirmPanelWithMessage:(NSString *)message
initiatedByFrame:(WKFrameInfo *)frame
completionHandler:(void (^)(BOOL result))completionHandler {
  NSLog(@"101===%s", __FUNCTION__);
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:
                              @"confirm" message:@"JS调用confirm"
                               preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:@"确定"
    style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action){
    completionHandler(YES);
  }]];
  [alert addAction:[UIAlertAction actionWithTitle:@"取消"
  style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    completionHandler(NO);
  }]];
  [self presentViewController:alert animated:YES completion:NULL];
  NSLog(@"%@", message);
}


    // JS端调用prompt函数时，会触发此方法
    // 要求输入一段文本
    // 在原生输入得到文本内容后，通过completionHandler回调给JS
- (void)webView:(WKWebView *)webView
runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt
    defaultText:(nullable NSString *)defaultText
initiatedByFrame:(WKFrameInfo *)frame
completionHandler:(void (^)(NSString * __nullable result))completionHandler {
  NSLog(@"102===%s", __FUNCTION__);
  NSLog(@"%@", prompt);
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:
                              @"textinput" message:@"JS调用输入框"
                              preferredStyle:UIAlertControllerStyleAlert];
  [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
    textField.textColor = [UIColor redColor];
  }];
  [alert addAction:[UIAlertAction actionWithTitle:@"确定"
    style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    completionHandler([[alert.textFields lastObject] text]);
  }]];
  
  [self presentViewController:alert animated:YES completion:NULL];
}

@end
