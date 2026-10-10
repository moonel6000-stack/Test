#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <notify.h>
#import <objc/runtime.h>

static NSString * const GPNotifyName = @"com.glitchpulse.toggle";
static BOOL GPEnabled = NO;
static UIWindow *GPWindow;
static UIView *GPOverlay;
static CADisplayLink *GPLink;
static id GPProxy;
static NSMutableArray<UIView *> *GPStrips;

static CGFloat GPRand(CGFloat lo, CGFloat hi) {
    return lo + (arc4random_uniform(10001) / 10000.0) * (hi - lo);
}

@interface GPDisplayProxy : NSObject
- (void)tick:(CADisplayLink *)link;
@end

static void GPStop(void) {
    GPEnabled = NO;
    [GPLink invalidate];
    GPLink = nil;
    GPProxy = nil;
    [GPWindow setHidden:YES];
    GPWindow.rootViewController = nil;
    GPWindow = nil;
    GPOverlay = nil;
    GPStrips = nil;
}

static void GPTick(void) {
    if (!GPEnabled || !GPOverlay) return;
    CGRect b = UIScreen.mainScreen.bounds;
    GPOverlay.backgroundColor = UIColor.clearColor;

    for (UIView *strip in GPStrips) {
        CGFloat h = GPRand(1.0, 12.0);
        CGFloat w = GPRand(b.size.width * 0.12, b.size.width * 0.98);
        strip.frame = CGRectMake(GPRand(-16, 16), GPRand(0, b.size.height), w, h);

        switch (arc4random_uniform(5)) {
            case 0: strip.backgroundColor = [UIColor colorWithRed:1 green:0.02 blue:0.38 alpha:GPRand(0.08, 0.27)]; break;
            case 1: strip.backgroundColor = [UIColor colorWithRed:0.02 green:0.86 blue:1 alpha:GPRand(0.07, 0.25)]; break;
            case 2: strip.backgroundColor = [UIColor colorWithRed:0.55 green:0.08 blue:1 alpha:GPRand(0.06, 0.22)]; break;
            case 3: strip.backgroundColor = [UIColor colorWithWhite:1 alpha:GPRand(0.02, 0.12)]; break;
            default: strip.backgroundColor = [UIColor colorWithRed:0.1 green:1 blue:0.35 alpha:GPRand(0.05, 0.18)]; break;
        }
        strip.hidden = arc4random_uniform(100) < 38;
    }

    // Rare, low-alpha color bloom. Kept intentionally restrained to avoid harsh strobing.
    if (arc4random_uniform(100) < 3) {
        GPOverlay.backgroundColor = [UIColor colorWithRed:GPRand(0.25, 0.8)
                                                     green:GPRand(0.0, 0.18)
                                                      blue:GPRand(0.45, 1.0)
                                                     alpha:0.045];
    }
}

@implementation GPDisplayProxy
- (void)tick:(CADisplayLink *)link {
    if (GPEnabled) GPTick();
}
@end

static void GPStart(void) {
    if (GPEnabled) return;
    GPEnabled = YES;

    CGRect bounds = UIScreen.mainScreen.bounds;
    GPWindow = [[UIWindow alloc] initWithFrame:bounds];
    GPWindow.windowLevel = UIWindowLevelAlert + 1;
    GPWindow.backgroundColor = UIColor.clearColor;
    GPWindow.userInteractionEnabled = NO;

    UIViewController *root = [UIViewController new];
    root.view.backgroundColor = UIColor.clearColor;
    root.view.userInteractionEnabled = NO;
    GPWindow.rootViewController = root;

    GPOverlay = [[UIView alloc] initWithFrame:bounds];
    GPOverlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    GPOverlay.backgroundColor = UIColor.clearColor;
    GPOverlay.userInteractionEnabled = NO;
    [root.view addSubview:GPOverlay];

    GPStrips = [NSMutableArray array];
    for (NSUInteger i = 0; i < 30; i++) {
        UIView *strip = [[UIView alloc] initWithFrame:CGRectZero];
        strip.userInteractionEnabled = NO;
        strip.layer.compositingFilter = @"screenBlendMode";
        [GPOverlay addSubview:strip];
        [GPStrips addObject:strip];
    }

    GPWindow.hidden = NO;
    GPProxy = [GPDisplayProxy new];
    GPLink = [CADisplayLink displayLinkWithTarget:GPProxy selector:@selector(tick:)];
    GPLink.preferredFramesPerSecond = 30;
    [GPLink addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
}

static void GPApplyState(uint64_t state) {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (state == 1) GPStart();
        else GPStop();
    });
}

%ctor {
    @autoreleasepool {
        // Darwin notification state is shared between the Control Center module
        // process and SpringBoard.
        int token = 0;
        notify_register_dispatch(GPNotifyName.UTF8String, &token, dispatch_get_main_queue(), ^(int t) {
            uint64_t state = 0;
            notify_get_state(t, &state);
            GPApplyState(state);
        });
        // Always start from a clean state after SpringBoard relaunch.
        GPStop();
    }
}
