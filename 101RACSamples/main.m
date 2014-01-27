//
//  main.m
//  101RACSamples
//
//  Created by Matthew Doig on 1/26/14.
//  Copyright (c) 2014 DWI. All rights reserved.
//

#pragma mark Asynchronous operations

// Work will start immediately on the background thread
void runAsyncEagerly()
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

// No work will happen. Unlike startEagerly, work will only happen our signal is subscribed to.
void runAsyncLazilyNeverStarts()
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

// Work starts when we subscribe to the signal, but the main thread never ends because the background thread never lets the subscriber know it has completed.
void runAsyncLazilyNeverCompletes()
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
void runAsyncLazily()
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

void runAsyncFirstOnly() {
    RACSignal *mysignal = [RACSignal startLazilyWithScheduler:[RACScheduler scheduler] block:^(id<RACSubscriber> subscriber) {
        NSLog(@"Calculating...");
        [NSThread sleepForTimeInterval:3.0f];
        NSLog(@"Background work completed.");
        [subscriber sendCompleted];
    }];
    [mysignal subscribeCompleted:^{
        NSLog(@"Done 1!");
    }];
    [mysignal subscribeCompleted:^{
        NSLog(@"Done 2!");
    }];
    NSError *error;
    [mysignal waitUntilCompleted:&error];
    NSLog(@"Main thread completed.");
}

void runAsyncOnDemand() {
    RACSignal *mysignal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSLog(@"Calculating...");
        [NSThread sleepForTimeInterval:3.0f];
        NSLog(@"Background work completed.");
        [subscriber sendCompleted];
        return [RACDisposable disposableWithBlock:^{
            NSLog(@"Disposed");
        }];
    }];
    [mysignal subscribeCompleted:^{
        NSLog(@"Done 1!");
    }];
    [mysignal subscribeCompleted:^{
        NSLog(@"Done 2!");
    }];
    NSLog(@"Main thread completed.");
}

void parallelExecution()
{
    RACSignal *signalA = [RACSignal startLazilyWithScheduler:[RACScheduler scheduler] block:^(id<RACSubscriber> subscriber) {
        NSLog(@"Executing first on thread: %@", [NSThread currentThread]);
        [subscriber sendNext:@"ReturnA"];
        [subscriber sendCompleted];
    }];
    
    RACSignal *signalB = [RACSignal startLazilyWithScheduler:[RACScheduler scheduler] block:^(id<RACSubscriber> subscriber) {
        NSLog(@"Executing first on thread: %@", [NSThread currentThread]);
        [subscriber sendNext:@"ReturnB"];
        [subscriber sendCompleted];
    }];
    
    RACSignal *signalC = [RACSignal startLazilyWithScheduler:[RACScheduler scheduler] block:^(id<RACSubscriber> subscriber) {
        NSLog(@"Executing first on thread: %@", [NSThread currentThread]);
        [subscriber sendNext:@"ReturnC"];
        [subscriber sendCompleted];
    }];
    [[RACSignal
        combineLatest:@[signalA, signalB, signalC]
        reduce:^id(NSString *resulta, NSString *resultb, NSString *resultc) {
            NSLog(@"%@", resulta);
            NSLog(@"%@", resultb);
            NSLog(@"%@", resultc);
            return nil;
        }]
        subscribeCompleted:^{
            NSLog(@"Done!");
        }];
    
    NSLog(@"Main thread completed.");
    [NSThread sleepForTimeInterval:5.0f];
}

void cancelAsyncOperation()
{
    RACSignal *mysignal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSOperationQueue *op = [[NSOperationQueue alloc] init];
        [op addOperationWithBlock:^{
            int i = 0;
            for (; ; ) {
                [NSThread sleepForTimeInterval:0.2f];
                [subscriber sendNext:[NSNumber numberWithInt:i++]];
            }
        }];
        return [RACDisposable disposableWithBlock:^{
            [op cancelAllOperations];
        }];
    }];
    RACDisposable *subscription = [mysignal subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
    [NSThread sleepForTimeInterval:5.0f];
    [subscription dispose];
    [NSThread sleepForTimeInterval:3.0f];
    NSLog(@"Main thread completed.");
}

#pragma mark Restriction operators

void simpleFilter()
{
    NSDate *now = [NSDate date];
    RACSignal *oneDatePerSecond = [RACSignal interval:1.0f onScheduler:[RACScheduler scheduler]];
    [[oneDatePerSecond
        filter:^BOOL(NSDate *value) {
            NSTimeInterval interval = [value timeIntervalSinceDate:now];
            NSLog (@"reference date was %.0f seconds ago", interval);
            return interval < 5.0f;
        }]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    [NSThread sleepForTimeInterval:10.0f];
}

void simpleFilterTake()
{
    RACSignal *oneDatePerSecond = [RACSignal interval:1.0f onScheduler:[RACScheduler scheduler]];
    [[oneDatePerSecond
        take:4]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    [NSThread sleepForTimeInterval:10.0f];
}

#pragma mark Projection Operators

void simpleMap()
{
    NSDate *now = [NSDate date];
    RACSignal *oneNumberPerSecond = [[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        map:^id(NSDate *value) {
            NSTimeInterval interval = [value timeIntervalSinceDate:now];
            return [NSNumber numberWithInt:(int)interval];
        }];
    [oneNumberPerSecond
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }
     ];
    [NSThread sleepForTimeInterval:10.0f];
}

#pragma mark Grouping Operators

void simpleGroupBy()
{
    NSDate *now = [NSDate date];
    RACSignal *oneNumberPerSecond = [[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        map:^id(NSDate *value) {
            NSTimeInterval interval = [value timeIntervalSinceDate:now];
            NSNumber *num = [NSNumber numberWithInt:(int)interval];
            NSString *oddOrEven = [num intValue] % 2 == 0 ? @"EVEN" : @"ODD";
            RACTuple *tup = [RACTuple tupleWithObjects:oddOrEven, num, nil];
            return tup;
        }];
    [[oneNumberPerSecond
        groupBy:^id<NSCopying>(RACTuple *tuple) {
            return tuple.first;
        }]
        subscribeNext:^(RACGroupedSignal *x) {
            __block int numItems = 0;
            
            [x subscribeNext:^(RACTuple *x) {
                NSLog(@"There are %d in the %@ group", ++numItems, [x first]);
            }];
        }];
    [NSThread sleepForTimeInterval:21.0f];
}

#pragma mark Time Related Operators

void simpleBuffer()
{
    NSDate *now = [NSDate date];
    RACSignal *oneNumberPerSecond = [[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        map:^id(NSDate *value) {
            NSTimeInterval interval = [value timeIntervalSinceDate:now];
            return [NSNumber numberWithInt:(int)interval];
        }];
    [[oneNumberPerSecond
        bufferWithTime:5.0f onScheduler:[RACScheduler scheduler]]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }
     ];
    [NSThread sleepForTimeInterval:21.0f];
}

void simpleDelay()
{
    NSDate *now = [NSDate date];
    RACSignal *oneNumberEveryFiveSeconds = [[RACSignal
        interval:5.0f
        onScheduler:[RACScheduler scheduler]]
        map:^id(NSDate *value) {
            NSTimeInterval interval = [value timeIntervalSinceDate:now];
            return [NSNumber numberWithInt:(int)interval];
        }];
    //Instant Echo
    [oneNumberEveryFiveSeconds
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }
     ];
    //One second delay
    [[oneNumberEveryFiveSeconds
        delay:1.0f]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }
     ];
    //Two second delay
    [[oneNumberEveryFiveSeconds
        delay:2.0f]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }
     ];
    [NSThread sleepForTimeInterval:21.0f];
}

void simpleInterval()
{
    RACSignal *oneDatePerSecond = [RACSignal interval:1.0f onScheduler:[RACScheduler scheduler]];
    [oneDatePerSecond
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
     }];
    [NSThread sleepForTimeInterval:21.0f];
}

void simpleSample()
{
    RACSignal *oneDatePerSecond = [RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]];
    RACSignal *oneDateEveryFiveSeconds = [RACSignal interval:5.0f onScheduler:[RACScheduler scheduler]];
    [[oneDatePerSecond
        sample:oneDateEveryFiveSeconds]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
     }];
    [NSThread sleepForTimeInterval:21.0f];
}

void simpleThrottle()
{
    RACSignal *oneDatePerSecond = [RACSignal
                                   interval:1.0f
                                   onScheduler:[RACScheduler scheduler]];
    [[oneDatePerSecond
        throttle:5.0f]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
     }];
    [NSThread sleepForTimeInterval:21.0f];
}

#pragma mark Combination Operators

void simpleMerge()
{
    RACSignal *oneDatePerSecond = [RACSignal
                                   interval:1.0f
                                   onScheduler:[RACScheduler scheduler]];
    NSDate *now = [NSDate date];
    RACSignal *oneNumberPerSecond = [[[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        map:^id(NSDate *value) {
            NSTimeInterval interval = [value timeIntervalSinceDate:now];
            return [NSNumber numberWithInt:(int)interval];
        }]
        delay:0.5f];

    [[RACSignal
        merge:@[oneDatePerSecond, oneNumberPerSecond]]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    
    [NSThread sleepForTimeInterval:21.0f];
}

void simplePublish()
{
    RACSignal *oneDatePerSecond = [RACSignal
                                   interval:1.0f
                                   onScheduler:[RACScheduler scheduler]];
    
    // Each subscription starts a new sequence
    [oneDatePerSecond subscribeNext:^(id x) {
         NSLog(@"%@", x);
     }];
    [NSThread sleepForTimeInterval:5.0f];
    [oneDatePerSecond subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
    
    NSDate *now = [NSDate date];
    RACSignal *oneNumberPerSecond = [[RACSignal
       interval:1.0f
       onScheduler:[RACScheduler scheduler]]
       map:^id(NSDate *value) {
          NSTimeInterval interval = [value timeIntervalSinceDate:now];
          return [NSNumber numberWithInt:(int)interval];
       }];

    RACMulticastConnection *shared = [oneNumberPerSecond publish];
    [oneNumberPerSecond subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
    [NSThread sleepForTimeInterval:5.0f];
    [oneNumberPerSecond subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
    [shared connect];
    [NSThread sleepForTimeInterval:21.0f];
}

void simpleZip()
{
    RACSignal *oneDatePerSecond = [RACSignal
                                   interval:1.0f
                                   onScheduler:[RACScheduler scheduler]];
    NSDate *now = [NSDate date];
    RACSignal *oneNumberPerSecond = [[[RACSignal
       interval:1.0f
       onScheduler:[RACScheduler scheduler]]
       map:^id(NSDate *value) {
          NSTimeInterval interval = [value timeIntervalSinceDate:now];
          return [NSNumber numberWithInt:(int)interval];
       }]
      delay:0.5f];
    
    [[RACSignal
      zip:@[oneDatePerSecond, oneNumberPerSecond]]
      subscribeNext:^(id x) {
         NSLog(@"%@", x);
     }];
    
    [NSThread sleepForTimeInterval:21.0f];
}


#pragma mark Main

int main(int argc, const char * argv[])
{

    @autoreleasepool {
        simpleZip();
    }
    return 0;
}
