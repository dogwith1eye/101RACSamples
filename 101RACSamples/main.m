//
//  main.m
//  101RACSamples
//
//  Created by Matthew Doig on 1/26/14.
//  Copyright (c) 2014 DWI. All rights reserved.
//

#pragma mark Run Code Asynchronously

// Work will start immediately on the background thread
void showUseOfStartEagerly()
{
    NSLog(@"Shows use of startEagerly on a background thread:");
    
    [RACSignal startEagerlyWithScheduler:[RACScheduler scheduler] block:^(id<RACSubscriber> subscriber) {
        //This starts on a background thread.
        NSLog(@"From background thread. Does not block main thread.");
        NSLog(@"Calculating...");
        [NSThread sleepForTimeInterval:3.0f];
        NSLog(@"Background work completed.");
    }];
    NSLog(@"Main thread completed.");
    [NSThread sleepForTimeInterval:5.0f];
}

// No work will happen. Unlike startEagerly work will only happen when we subscribe to the signal.
void showUseOfStartLazilyNeverStarts()
{
    NSLog(@"Shows use of startLazily on a background thread:");
    
    [RACSignal startLazilyWithScheduler:[RACScheduler scheduler] block:^(id<RACSubscriber> subscriber) {
        //This starts on a background thread.
        NSLog(@"From background thread. Does not block main thread.");
        NSLog(@"Calculating...");
        [NSThread sleepForTimeInterval:3.0f];
        NSLog(@"Background work completed.");
    }];
    NSLog(@"Main thread completed.");
    [NSThread sleepForTimeInterval:5.0f];
}

// Work starts when we subscribe to the signal but the main thread never ends because the background thread never lets the subscriber know it has completed.
void showUseOfStartLazilyNeverCompletes()
{
    NSLog(@"Shows use of startLazily on a background thread:");
    
    RACSignal *mysignal = [RACSignal startLazilyWithScheduler:[RACScheduler scheduler] block:^(id<RACSubscriber> subscriber) {
        //This starts on a background thread.
        NSLog(@"From background thread. Does not block main thread.");
        NSLog(@"Calculating...");
        [NSThread sleepForTimeInterval:3.0f];
        NSLog(@"Background work completed.");
    }];
    NSError *error;
    [mysignal waitUntilCompleted:&error];
    NSLog(@"Main thread completed.");
}

// Work starts and signals the subscriber when it has completed
void showUseOfStartLazily()
{
    NSLog(@"Shows use of startLazily on a background thread:");
    
    RACSignal *mysignal = [RACSignal startLazilyWithScheduler:[RACScheduler scheduler] block:^(id<RACSubscriber> subscriber) {
        //This starts on a background thread.
        NSLog(@"From background thread. Does not block main thread.");
        NSLog(@"Calculating...");
        [NSThread sleepForTimeInterval:3.0f];
        NSLog(@"Background work completed.");
        [subscriber sendCompleted];
    }];
    NSError *error;
    [mysignal waitUntilCompleted:&error];
    NSLog(@"Main thread completed.");
}

#pragma mark Parallel Execution

void showUseOfMerge()
{
    [[RACSignal
        combineLatest:@[
            [RACSignal startLazilyWithScheduler:[RACScheduler scheduler] block:^(id<RACSubscriber> subscriber) {
                NSLog(@"Executing first on thread: %@", [NSThread currentThread]);
                [subscriber sendNext:@"Result A"];
                [subscriber sendCompleted];
            }],
            [RACSignal startEagerlyWithScheduler:[RACScheduler scheduler] block:^(id<RACSubscriber> subscriber) {
                NSLog(@"Executing second on thread: %@", [NSThread currentThread]);
                [subscriber sendNext:@"Result B"];
                [subscriber sendCompleted];
            }],
            [RACSignal startEagerlyWithScheduler:[RACScheduler scheduler] block:^(id<RACSubscriber> subscriber) {
                NSLog(@"Executing third on thread: %@", [NSThread currentThread]);
                [subscriber sendNext:@"Result C"];
                [subscriber sendCompleted];
            }]
        ]]
        subscribeCompleted:^{
            NSLog(@"Done!");
        }];
}

#pragma mark Main

int main(int argc, const char * argv[])
{

    @autoreleasepool {
        showUseOfMerge();
    }
    return 0;
}
