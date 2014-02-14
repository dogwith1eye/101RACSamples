//
//  main.m
//  101RACSamples
//
//  Created by Matthew Doig on 1/26/14.
//  Copyright (c) 2014 DWI. All rights reserved.
//

#pragma mark Asynchronous operators

void simpleStartEagerly()
{
    [RACSignal startEagerlyWithScheduler:[RACScheduler scheduler] block:^(id<RACSubscriber> subscriber) {
        NSLog(@"Calculating");
        [NSThread sleepForTimeInterval:3.0f];
        NSLog(@"Completed");
    }];
    NSLog(@"Main thread completed");
    [NSThread sleepForTimeInterval:5.0f];
}

void simpleStartLazily()
{
    [RACSignal startLazilyWithScheduler:[RACScheduler scheduler] block:^(id<RACSubscriber> subscriber) {
        NSLog(@"Calculating");
        [NSThread sleepForTimeInterval:3.0f];
        NSLog(@"Completed");
    }];
    NSLog(@"Main thread completed");
    [NSThread sleepForTimeInterval:5.0f];
    
    NSLog(@"Work only starts when subscribed to");
    
    RACSignal *signal = [RACSignal startLazilyWithScheduler:[RACScheduler scheduler] block:^(id<RACSubscriber> subscriber) {
        NSLog(@"Calculating");
        [NSThread sleepForTimeInterval:3.0f];
        NSLog(@"Completed");
        [subscriber sendCompleted];
    }];
    
    NSError *error;
    [signal waitUntilCompleted:&error];
    NSLog(@"Main thread completed");
}

void simpleDefer()
{
    RACSignal *mysignal = [RACSignal defer:^RACSignal *{
        return [RACSignal startEagerlyWithScheduler:[RACScheduler scheduler] block:^(id<RACSubscriber> subscriber) {
            NSLog(@"Calculating");
            [NSThread sleepForTimeInterval:3.0f];
            NSLog(@"Completed");
            [subscriber sendCompleted];
        }];
    }];
    NSLog(@"Main thread completed");
    [NSThread sleepForTimeInterval:5.0f];
    
    NSLog(@"We've turned our hot signal into a cold signal and it will not start until subscribed to");
    
    NSError *error;
    [mysignal waitUntilCompleted:&error];
}

void simpleStartLazilyRunsForFirstSubscriptionOnly() {
    RACSignal *mysignal = [RACSignal startLazilyWithScheduler:[RACScheduler scheduler] block:^(id<RACSubscriber> subscriber) {
        NSLog(@"Calculating");
        [NSThread sleepForTimeInterval:3.0f];
        NSLog(@"Completed");
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
    
    RACSignal *myresult = [RACSignal startLazilyWithScheduler:[RACScheduler scheduler] block:^(id<RACSubscriber> subscriber) {
        NSLog(@"Calculating");
        [NSThread sleepForTimeInterval:3.0f];
        NSLog(@"Completed");
        [subscriber sendNext:@1];
        [subscriber sendCompleted];
    }];
    [myresult subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
    [myresult subscribeCompleted:^{
        NSLog(@"Done 1!");
    }];
    [myresult subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
    [myresult subscribeCompleted:^{
        NSLog(@"Done 2!");
    }];
    NSError *resulterror;
    [myresult waitUntilCompleted:&resulterror];

    NSLog(@"Main thread completed");
}

void simpleCreateSignalRunsForEachSubscription() {
    RACSignal *mysignal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSLog(@"Calculating");
        [NSThread sleepForTimeInterval:3.0f];
        NSLog(@"Completed");
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
    NSLog(@"Main thread completed");
}

void simpleCreateSignalRunsForEachSubscriptionAndDoesNotBlock() {
    RACSignal *mysignal = [[RACSignal
        createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            NSLog(@"Calculating");
            [NSThread sleepForTimeInterval:3.0f];
            NSLog(@"Completed");
            [subscriber sendCompleted];
            return [RACDisposable disposableWithBlock:^{
                NSLog(@"Disposed");
            }];
        }]
        subscribeOn:[RACScheduler scheduler]];
    [mysignal subscribeCompleted:^{
        NSLog(@"Done 1!");
    }];
    [mysignal subscribeCompleted:^{
        NSLog(@"Done 2!");
    }];
    NSLog(@"Main thread completed");
    [NSThread sleepForTimeInterval:10.0f];
}

void simpleDisposeToCancelOperation()
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
            NSLog(@"Disposed");
        }];
    }];
    RACDisposable *subscription = [mysignal subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
    [NSThread sleepForTimeInterval:5.0f];
    [subscription dispose];
    [NSThread sleepForTimeInterval:5.0f];
    NSLog(@"Main thread completed.");
}

#pragma mark Creation operators

void simpleReturn()
{
    RACSignal *oneNumber = [RACSignal return:@1];
    [oneNumber
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    [oneNumber
        subscribeCompleted:^{
            NSLog(@"Done!");
        }];
    [oneNumber
        subscribeError:^(NSError *error) {
            NSLog(@"%@", error);
        }];
}

void simpleEmpty()
{
    RACSignal *oneNumber = [RACSignal empty];
    [oneNumber
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    [oneNumber
        subscribeCompleted:^{
            NSLog(@"Done!");
        }];
    [oneNumber
     subscribeError:^(NSError *error) {
         NSLog(@"%@", error);
     }];
}

void simpleNever()
{
    RACSignal *oneNumber = [RACSignal never];
    [oneNumber
     subscribeNext:^(id x) {
         NSLog(@"%@", x);
     }];
    [oneNumber
     subscribeCompleted:^{
         NSLog(@"Done!");
     }];
    [oneNumber
     subscribeError:^(NSError *error) {
         NSLog(@"%@", error);
     }];
}

void simpleError()
{
    RACSignal *oneNumber = [RACSignal error:[NSError errorWithDomain:@"Domain" code:1 userInfo:@{}]];
    [oneNumber
     subscribeNext:^(id x) {
         NSLog(@"%@", x);
     }];
    [oneNumber
     subscribeCompleted:^{
         NSLog(@"Done!");
     }];
    [oneNumber
     subscribeError:^(NSError *error) {
         NSLog(@"%@", error);
     }];
}

void simpleCreate()
{
    RACSignal *oneNumber = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@1];
        [subscriber sendCompleted];
        return [RACDisposable disposableWithBlock:^{
            NSLog(@"Disposed");
        }];
    }];
    [oneNumber
     subscribeNext:^(id x) {
         NSLog(@"%@", x);
     }];
    [oneNumber
     subscribeCompleted:^{
         NSLog(@"Done!");
     }];
    [oneNumber
     subscribeError:^(NSError *error) {
         NSLog(@"%@", error);
     }];
}

#pragma mark Restriction operators

void simpleFilter()
{
    RACSignal *oneNumberEverySecond = [[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           return @(running.unsignedIntegerValue + 1);
        }];
    [[oneNumberEverySecond
        filter:^BOOL(NSNumber *value) {
            return [value intValue] < 5;
        }]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    [NSThread sleepForTimeInterval:10.0f];
}

void simpleDistinctUntilChanged()
{
    RACSignal *sameNumberEverySecond = [[[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           return running;
        }]
        distinctUntilChanged];
    
    [sameNumberEverySecond
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    [NSThread sleepForTimeInterval:10.0f];
}


void simpleIgnore()
{
    RACSignal *oneNumberEverySecond = [[[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           return @(running.unsignedIntegerValue + 1);
        }]
        ignore:@5];
    
    [oneNumberEverySecond
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    [NSThread sleepForTimeInterval:10.0f];
}

void simpleIgnoreValues()
{
    RACSignal *oneNumberEverySecond = [[[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           return @(running.unsignedIntegerValue + 1);
        }]
        ignoreValues];
    
    [oneNumberEverySecond
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    [NSThread sleepForTimeInterval:10.0f];
}

void simpleTake()
{
    RACSignal *oneNumberEverySecond = [[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           return @(running.unsignedIntegerValue + 1);
        }];
    [[oneNumberEverySecond
        take:4]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    [NSThread sleepForTimeInterval:10.0f];
}

void simpleTakeWhile()
{
    RACSignal *oneNumberEverySecond = [[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           return @(running.unsignedIntegerValue + 1);
        }];
    [[oneNumberEverySecond
        takeWhileBlock:^BOOL(NSNumber *value) {
            return [value intValue] < 5;
        }]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    [NSThread sleepForTimeInterval:10.0f];
}

void simpleTakeUntil()
{
    RACSignal *oneNumberEverySecond = [[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           return @(running.unsignedIntegerValue + 1);
        }];
    [[oneNumberEverySecond
        takeUntilBlock:^BOOL(NSNumber *value) {
            return [value intValue] > 4;
        }]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    [NSThread sleepForTimeInterval:10.0f];
}

void simpleTakeUntilReplacement()
{
    RACSignal *number1EverySecond = [[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@1 reduce:^id(NSNumber *running, id next) {
           return running;
        }];
    
    RACSignal *number2Every5Seconds = [[RACSignal
        interval:5.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@2 reduce:^id(NSNumber *running, id next) {
           return running;
        }];
    
    [[number1EverySecond
        takeUntilReplacement:number2Every5Seconds]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    [NSThread sleepForTimeInterval:16.0f];

}

void simpleTakeLast()
{
    RACSignal *oneNumberEverySecond = [[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           return @(running.unsignedIntegerValue + 1);
        }];
    [[[oneNumberEverySecond
        take:4]
        takeLast:2]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    [NSThread sleepForTimeInterval:10.0f];
}

void simpleSkip()
{
    RACSignal *oneNumberEverySecond = [[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           return @(running.unsignedIntegerValue + 1);
        }];
    [[oneNumberEverySecond
        skip:4]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    [NSThread sleepForTimeInterval:10.0f];
}

void simpleSkipWhile()
{
    RACSignal *oneNumberEverySecond = [[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           return @(running.unsignedIntegerValue + 1);
        }];
    [[oneNumberEverySecond
        skipWhileBlock:^BOOL(NSNumber *value) {
            return [value intValue] < 5;
        }]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    [NSThread sleepForTimeInterval:10.0f];
}

void simpleSkipUntil()
{
    RACSignal *oneNumberEverySecond = [[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           return @(running.unsignedIntegerValue + 1);
        }];
    [[oneNumberEverySecond
        skipUntilBlock:^BOOL(NSNumber *value) {
            return [value intValue] > 4;
        }]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    [NSThread sleepForTimeInterval:10.0f];
}

#pragma mark Inspection Operators

void simpleAny()
{
    RACSignal *oneNumberEverySecond = [[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           return @(running.unsignedIntegerValue + 1);
        }];
    [[oneNumberEverySecond
        any:^BOOL(NSNumber *value) {
            return [value intValue] > 5;
        }]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    [NSThread sleepForTimeInterval:10.0f];
}

void simpleAll()
{
    RACSignal *firstFourNumbers = [RACSignal startLazilyWithScheduler:[RACScheduler scheduler] block:^(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@1];
        [NSThread sleepForTimeInterval:1.0f];
        [subscriber sendNext:@2];
        [NSThread sleepForTimeInterval:1.0f];
        [subscriber sendNext:@3];
        [NSThread sleepForTimeInterval:1.0f];
        [subscriber sendNext:@4];
        [NSThread sleepForTimeInterval:1.0f];
        [subscriber sendCompleted];
    }];
    [[firstFourNumbers
        all:^BOOL(NSNumber *value) {
            return [value intValue] < 5;
        }]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    [NSThread sleepForTimeInterval:10.0f];
}

#pragma mark Aggregation Operators

void simpleAggregationWithStart()
{
    RACSignal *firstFourNumbers = [RACSignal startLazilyWithScheduler:[RACScheduler scheduler] block:^(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@1];
        [NSThread sleepForTimeInterval:1.0f];
        [subscriber sendNext:@2];
        [NSThread sleepForTimeInterval:1.0f];
        [subscriber sendNext:@3];
        [NSThread sleepForTimeInterval:1.0f];
        [subscriber sendNext:@4];
        [NSThread sleepForTimeInterval:1.0f];
        [subscriber sendCompleted];
    }];
    [[firstFourNumbers
        aggregateWithStart:@0 reduce:^id(id running, id next) {
            int i = [running intValue] + [next intValue];
            return [NSNumber numberWithInt:i];
        }]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    [NSThread sleepForTimeInterval:10.0f];
}

void simpleFirst()
{
    RACSignal *firstFourNumbers = [RACSignal startLazilyWithScheduler:[RACScheduler scheduler] block:^(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@1];
        [NSThread sleepForTimeInterval:1.0f];
        [subscriber sendNext:@2];
        [NSThread sleepForTimeInterval:1.0f];
        [subscriber sendNext:@3];
        [NSThread sleepForTimeInterval:1.0f];
        [subscriber sendNext:@4];
        [NSThread sleepForTimeInterval:1.0f];
        [subscriber sendCompleted];
    }];
    NSLog(@"%@", [firstFourNumbers first]);
    [NSThread sleepForTimeInterval:10.0f];
}

void simpleFirstOrDefault()
{
    RACSignal *empty = [RACSignal empty];
    NSLog(@"%@", [empty firstOrDefault:nil]);
}

void simpleCollect()
{
    RACSignal *oneNumberEverySecond = [[[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           return @(running.unsignedIntegerValue + 1);
        }]
        take:3];
    [[oneNumberEverySecond
        collect]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    [NSThread sleepForTimeInterval:10.0f];
}

void simpleToArray()
{
    RACSignal *oneNumberEverySecond = [[[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           return @(running.unsignedIntegerValue + 1);
        }]
        take:3];
    
    NSArray *array = [oneNumberEverySecond toArray];
    NSLog(@"%@", array);
}

#pragma mark Error Handling Operators

void simpleCatch()
{
    RACSignal *error = [[RACSignal
        error:[NSError errorWithDomain:@"domain" code:1 userInfo:@{}]]
        catch:^RACSignal *(NSError *error) {
            NSLog(@"Swallowed!");
            return [RACSignal empty];
        }];
    [error
        subscribeError:^(id x) {
            NSLog(@"%@", x);
        }
     ];
}

void simpleCatchTo()
{
    RACSignal *errors = [RACSignal return:@1];
    RACSignal *error = [[RACSignal
        error:[NSError errorWithDomain:@"domain" code:1 userInfo:@{}]]
        catchTo:errors];
                            
    [error
        subscribeError:^(id x) {
            NSLog(@"%@", x);
        }
     ];
    [error
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }
     ];
}

void simpleFinally()
{
    RACSignal *oneNumber = [[RACSignal
        return:@1]
        finally:^{
            NSLog(@"Finally!");
        }];
    RACSignal *error = [[RACSignal
        error:[NSError errorWithDomain:@"domain" code:1 userInfo:@{}]]
        finally:^{
            NSLog(@"Finally!");
        }];
    [oneNumber
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }
    ];
    [error
        subscribeError:^(id x) {
            NSLog(@"%@", x);
        }
     ];
}

void simpleInitially()
{
    RACSignal *oneNumber = [[RACSignal
        return:@1]
        initially:^{
            NSLog(@"Initially!");
        }];
    
    RACSignal *error = [[RACSignal
        error:[NSError errorWithDomain:@"domain" code:1 userInfo:@{}]]
        initially:^{
            NSLog(@"Initially!");
        }];
    [oneNumber
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }
     ];
    [error
        subscribeError:^(id x) {
            NSLog(@"%@", x);
        }
     ];
}

void simpleTry()
{
    RACSignal *files = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"file1.txt"];
        [subscriber sendNext:@"file2.txt"];
        [subscriber sendNext:@"file3.txt"];
        [subscriber sendCompleted];
        return [RACDisposable disposableWithBlock:^{
            NSLog(@"Disposed");
        }];
    }];
    RACSignal *trySignal = [[files
        try:^BOOL(NSString *file, NSError *__autoreleasing *errorPtr) {
            if ([file isEqualToString:@"file1.txt"]) return YES;
            NSFileManager *fileManager = [NSFileManager defaultManager];
            return [fileManager removeItemAtPath:file error:errorPtr];
        }]
        doNext:^(id x) {
            NSLog(@"%@", x);
        }];
    
    [trySignal subscribeError:^(NSError *error) {
        NSLog(@"%@", error);
    }];
}

void simpleTryMap()
{
    RACSignal *files = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"file1.txt"];
        [subscriber sendNext:@"file2.txt"];
        [subscriber sendNext:@"file3.txt"];
        [subscriber sendCompleted];
        return [RACDisposable disposableWithBlock:^{
            NSLog(@"Disposed");
        }];
    }];
    RACSignal *trySignal = [[files
        tryMap:^id(NSString *file, NSError *__autoreleasing *errorPtr) {
            if ([file isEqualToString:@"file1.txt"]) return @{};
            NSFileManager *fileManager = [NSFileManager defaultManager];
            return [fileManager attributesOfItemAtPath:file error:errorPtr];
        }]
        doNext:^(id x) {
            NSLog(@"%@", x);
        }];
    
    [trySignal subscribeError:^(NSError *error) {
        NSLog(@"%@", error);
    }];
}

void simpleRetry()
{
    RACSignal *firstFourNumbers = [RACSignal startLazilyWithScheduler:[RACScheduler scheduler] block:^(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@1];
        [subscriber sendNext:@2];
        [subscriber sendNext:@3];
        [subscriber sendNext:@4];
        [subscriber sendError:[NSError errorWithDomain:@"domain" code:1 userInfo:@{}]];
    }];
    [[firstFourNumbers
        retry:3]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    [NSThread sleepForTimeInterval:5.0f];
}

#pragma mark Projection Operators

void simpleMap()
{
    RACSignal *oneNumberEverySecond = [[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        map:^id(NSDate *value) {
            NSTimeInterval interval = [value timeIntervalSince1970];
            return [NSNumber numberWithInt:(int)interval];
        }];
    [oneNumberEverySecond
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }
     ];
    [NSThread sleepForTimeInterval:5.0f];
}

void simpleScan()
{
    RACSignal *oneNumberEverySecond = [[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, NSDate *next) {
           return @(running.unsignedIntegerValue + 1);
        }];
    [oneNumberEverySecond
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }
     ];
    [NSThread sleepForTimeInterval:5.0f];
}

void simpleReduceEach()
{
    RACSignal *oneDateEverySecond = [RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]];

    RACSignal *oneNumberEverySecond = [[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           return @(running.unsignedIntegerValue + 1);
        }];
    
    [[[RACSignal
        zip:@[oneDateEverySecond, oneNumberEverySecond]]
        reduceEach:^(NSDate *date, NSNumber *number){
            return number;
        }]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    
    [NSThread sleepForTimeInterval:21.0f];
}

void simpleMaterialize()
{
     RACSignal *oneNumberEverySecond = [[[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           return @(running.unsignedIntegerValue + 1);
        }]
        materialize];
    [oneNumberEverySecond
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }
     ];
    [NSThread sleepForTimeInterval:10.0f];

}

void simpleDematerialize()
{
    RACSignal *oneNumberEverySecond = [[[[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           return @(running.unsignedIntegerValue + 1);
        }]
        materialize]
        dematerialize];
    [oneNumberEverySecond
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }
     ];
    [NSThread sleepForTimeInterval:10.0f];
}

void simpleNot()
{
    RACSignal *isEven = [[[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           return @(running.unsignedIntegerValue + 1);
        }]
        map:^id(NSNumber *value) {
            return [value intValue] % 2 == 0 ? [NSNumber numberWithBool:YES] : [NSNumber numberWithBool:NO];
        }];
    
    [[isEven
        not]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    [NSThread sleepForTimeInterval:5.0f];
}

void simpleAnd()
{
    RACSignal *isEvenEvery2Seconds = [[[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           return @(running.unsignedIntegerValue + 1);
        }]
        map:^id(NSNumber *value) {
            return [value intValue] % 2 == 0 ? [NSNumber numberWithBool:YES] : [NSNumber numberWithBool:NO];
        }];
    
    RACSignal *isEvenEvery3Seconds = [[[RACSignal
        interval:3.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           return @(running.unsignedIntegerValue + 1);
        }]
        map:^id(NSNumber *value) {
            return [value intValue] % 2 == 0 ? [NSNumber numberWithBool:YES] : [NSNumber numberWithBool:NO];
        }];
    [[[[RACSignal
        combineLatest:@[isEvenEvery2Seconds, isEvenEvery3Seconds]]
        doNext:^(id x) {
            NSLog(@"%@", x);
        }]
        and]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    [NSThread sleepForTimeInterval:21.0f];
}

void simpleOr()
{
    RACSignal *isEvenEvery2Seconds = [[[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           return @(running.unsignedIntegerValue + 1);
        }]
        map:^id(NSNumber *value) {
            return [value intValue] % 2 == 0 ? [NSNumber numberWithBool:YES] : [NSNumber numberWithBool:NO];
        }];
    
    RACSignal *isEvenEvery3Seconds = [[[RACSignal
        interval:3.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           return @(running.unsignedIntegerValue + 1);
        }]
        map:^id(NSNumber *value) {
            return [value intValue] % 2 == 0 ? [NSNumber numberWithBool:YES] : [NSNumber numberWithBool:NO];
        }];
    [[[[RACSignal
        combineLatest:@[isEvenEvery2Seconds, isEvenEvery3Seconds]]
        doNext:^(id x) {
            NSLog(@"%@", x);
        }]
        or]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    [NSThread sleepForTimeInterval:21.0f];
}

#pragma mark Partioning Operators

void simpleGroupBy()
{
    RACSignal *oneNumberEverySecond = [[[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           return @(running.unsignedIntegerValue + 1);
        }]
        map:^id(NSNumber *value) {
            NSString *oddOrEven = [value intValue] % 2 == 0 ? @"EVEN" : @"ODD";
            return [RACTuple tupleWithObjects:oddOrEven, value, nil];
        }];;
    
    [[oneNumberEverySecond
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

void simpleBufferWithTime()
{
    RACSignal *oneNumberEverySecond = [[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           return @(running.unsignedIntegerValue + 1);
        }];
    [[oneNumberEverySecond
        bufferWithTime:5.0f onScheduler:[RACScheduler scheduler]]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }
     ];
    [NSThread sleepForTimeInterval:21.0f];
}

void simpleDelay()
{
    RACSignal *oneNumberEveryFiveSeconds = [[RACSignal
        interval:5.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           return @(running.unsignedIntegerValue + 1);
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
    RACSignal *oneDateEverySecond = [RACSignal interval:1.0f onScheduler:[RACScheduler scheduler]];
    [oneDateEverySecond
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
     }];
    [NSThread sleepForTimeInterval:5.0f];
}

void simpleSample()
{
    RACSignal *oneNumberEverySecond = [[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           return @(running.unsignedIntegerValue + 1);
        }];
    RACSignal *oneDateEveryFiveSeconds = [RACSignal interval:5.0f onScheduler:[RACScheduler scheduler]];
    [[oneNumberEverySecond
        sample:oneDateEveryFiveSeconds]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
     }];
    [NSThread sleepForTimeInterval:21.0f];
}

void simpleThrottle()
{
    RACSignal *oneNumberEverySecond = [[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           return @(running.unsignedIntegerValue + 1);
        }];
    
    RACSignal *oneDateEveryTwoSeconds = [RACSignal interval:2.0f onScheduler:[RACScheduler scheduler]];

    [[oneNumberEverySecond
        throttle:1.1f]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
     }];
    [[oneDateEveryTwoSeconds
        throttle:1.1f]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
     }];
    [NSThread sleepForTimeInterval:21.0f];
}

void simpleTimeout()
{
    RACSignal *oneNumberEverySecond = [[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           return @(running.unsignedIntegerValue + 1);
        }];
    
    [[oneNumberEverySecond
        timeout:5.0f onScheduler:[RACScheduler scheduler]]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
     }];
    [NSThread sleepForTimeInterval:10.0f];
}

void simpleWaitUnitlCompleted()
{
    RACSignal *firstFourNumbers = [RACSignal startLazilyWithScheduler:[RACScheduler scheduler] block:^(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@1];
        [NSThread sleepForTimeInterval:1.0f];
        [subscriber sendNext:@2];
        [NSThread sleepForTimeInterval:1.0f];
        [subscriber sendNext:@3];
        [NSThread sleepForTimeInterval:1.0f];
        [subscriber sendNext:@5];
        [NSThread sleepForTimeInterval:1.0f];
        [subscriber sendCompleted];
    }];
    NSError *error;
    [firstFourNumbers waitUntilCompleted:&error];
    
    NSLog(@"End main thread");
}

#pragma mark Combination Operators

void simpleMerge()
{
    RACSignal *oneDateEverySecond = [RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]];

    RACSignal *oneNumberEveryFiveSeconds = [[RACSignal
        interval:5.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           return @(running.unsignedIntegerValue + 1);
        }];

    [[RACSignal
        merge:@[oneDateEverySecond, oneNumberEveryFiveSeconds]]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    
    [NSThread sleepForTimeInterval:21.0f];
}

void simpleFlatten()
{
    RACSignal *number1EverySecond = [[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@1 reduce:^id(NSNumber *running, id next) {
            return running;
        }];
    RACSignal *number2EverySecond = [[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@2 reduce:^id(NSNumber *running, id next) {
            return running;
        }];
    
    RACSignal *signalOfSignals = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:number1EverySecond];
        [subscriber sendNext:number2EverySecond];
        return [RACDisposable disposableWithBlock:^{
            NSLog(@"Disposed");
        }];
    }];

    RACDisposable *sub1 = [[signalOfSignals
        flatten:0]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    [NSThread sleepForTimeInterval:5.0f];
    [sub1 dispose];
    
    RACDisposable *sub2 = [[signalOfSignals
        flatten:1]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    [NSThread sleepForTimeInterval:5.0f];
    [sub2 dispose];
}

void simpleSwitchToLatest()
{
    RACSignal *number1EverySecond = [[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@1 reduce:^id(NSNumber *running, id next) {
            return running;
        }];
    RACSignal *number2EverySecond = [[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@2 reduce:^id(NSNumber *running, id next) {
            return running;
        }];
    
    RACSignal *signalOfSignals = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:number2EverySecond];
        [subscriber sendNext:number1EverySecond];
        [NSThread sleepForTimeInterval:5.0f];
        [subscriber sendNext:number2EverySecond];
        return [RACDisposable disposableWithBlock:^{
            NSLog(@"Disposed");
        }];
    }];

    [[signalOfSignals
        switchToLatest]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    [NSThread sleepForTimeInterval:11.0f];
}

void simpleSwitch()
{
    RACSignal *oneNumberEveryFiveSeconds = [[RACSignal
        interval:5.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           return @(running.unsignedIntegerValue + 1);
        }];
    
    RACSignal *number1EverySecond = [[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@1 reduce:^id(NSNumber *running, id next) {
           return running;
        }];
    
    RACSignal *number2EverySecond = [[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@2 reduce:^id(NSNumber *running, id next) {
           return running;
        }];
    
    RACSignal *number3EverySecond = [[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@3 reduce:^id(NSNumber *running, id next) {
           return running;
        }];

    [[RACSignal
         switch:oneNumberEveryFiveSeconds cases:@{@1: number1EverySecond, @2: number2EverySecond, @3: number3EverySecond} default:[RACSignal empty]]
         subscribeNext:^(id x) {
            NSLog(@"%@", x);
         }];
    
    [NSThread sleepForTimeInterval:21.0f];
}

void simpleIfThenElse()
{
    RACSignal *oneBoolEveryFiveSeconds = [[RACSignal
        interval:5.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
            return [running intValue] % 2 == 0 ? @YES : @NO;
        }];
    
    RACSignal *number1EverySecond = [[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@1 reduce:^id(NSNumber *running, id next) {
           return running;
        }];
    
    RACSignal *number2EverySecond = [[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@2 reduce:^id(NSNumber *running, id next) {
           return running;
        }];
    
    [[RACSignal
         if:oneBoolEveryFiveSeconds then:number1EverySecond else:number2EverySecond]
         subscribeNext:^(id x) {
            NSLog(@"%@", x);
         }];
    
    [NSThread sleepForTimeInterval:21.0f];
}

void simpleZip()
{
    RACSignal *oneDateEverySecond = [RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]];

    RACSignal *oneNumberEveryFiveSeconds = [[RACSignal
        interval:5.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           return @(running.unsignedIntegerValue + 1);
        }];

    [[RACSignal
        zip:@[oneDateEverySecond, oneNumberEveryFiveSeconds]]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    
    [NSThread sleepForTimeInterval:21.0f];
}

void simpleCombineLatest()
{
    RACSignal *oneDateEverySecond = [RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]];

    RACSignal *oneNumberEveryFiveSeconds = [[RACSignal
        interval:5.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           return @(running.unsignedIntegerValue + 1);
        }];
    
    [[RACSignal
        combineLatest:@[oneDateEverySecond, oneNumberEveryFiveSeconds]]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    
    [NSThread sleepForTimeInterval:21.0f];
}

void simpleConcat()
{
    RACSignal *oneDateEverySecond = [[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        take:3];

    RACSignal *oneNumberEverySecond = [[[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           return @(running.unsignedIntegerValue + 1);
        }]
        take:3];
    
    [[RACSignal
        concat:@[oneDateEverySecond, oneNumberEverySecond]]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    
    [NSThread sleepForTimeInterval:21.0f];
}

void simpleConcatHot()
{
    RACSignal *oneDateEverySecond = [[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        take:3];

    RACSignal *oneNumberEverySecond = [[[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           return @(running.unsignedIntegerValue + 1);
        }]
        take:5];
    
    RACMulticastConnection *shared = [oneNumberEverySecond publish];
    [shared connect];
    RACSignal *oneNumberEverySecondHot = [shared signal];
    
    [[RACSignal
        concat:@[oneDateEverySecond, oneNumberEverySecondHot]]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    
    [NSThread sleepForTimeInterval:10.0f];
}

void simpleThen()
{
    RACSignal *oneDateEverySecond = [[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        take:3];

    RACSignal *oneNumberEverySecond = [[[[[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           return @(running.unsignedIntegerValue + 1);
        }]
        take:3]
        doNext:^(id x) {
            NSLog(@"%@", x);
        }]
        then:^RACSignal *{
            return oneDateEverySecond;
        }];
    
    [oneNumberEverySecond
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    
    [NSThread sleepForTimeInterval:10.0f];
}


void simpleRepeat()
{
    RACSignal *firstFourNumbers = [RACSignal startLazilyWithScheduler:[RACScheduler scheduler] block:^(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@1];
        [subscriber sendNext:@2];
        [subscriber sendNext:@3];
        [subscriber sendNext:@4];
        [subscriber sendCompleted];
    }];
    [[firstFourNumbers
        repeat]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    
    [NSThread sleepForTimeInterval:5.0f];
}

void simpleStartWith()
{
    RACSignal *firstFourNumbers = [RACSignal startLazilyWithScheduler:[RACScheduler scheduler] block:^(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@1];
        [subscriber sendNext:@2];
        [subscriber sendNext:@3];
        [subscriber sendNext:@4];
        [subscriber sendCompleted];
    }];
    [[firstFourNumbers
        startWith:@0]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    
    [NSThread sleepForTimeInterval:5.0f];
}

#pragma mark Side effects operators

void simpleDoNext()
{
    NSNumber __block *currentNumber = @0;
    
    RACSignal *oneNumberEverySecond = [[[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           return @(running.unsignedIntegerValue + 1);
        }]
        doNext:^(id x) {
            currentNumber = x;
        }];
    
    [oneNumberEverySecond subscribeNext:^(id x) {
        NSLog(@"%@", currentNumber);
    }];
    [NSThread sleepForTimeInterval:5.0f];
}

void simpleDoError()
{
    NSError __block *currentError = nil;
    
    RACSignal *oneNumberEverySecond = [[RACSignal
        error:[NSError errorWithDomain:@"domain" code:1 userInfo:@{}]]
        doError:^(id x) {
            currentError = x;
        }];
    
    [oneNumberEverySecond subscribeError:^(id x) {
        NSLog(@"%@", currentError);
    }];
    [NSThread sleepForTimeInterval:5.0f];
}

void simpleDoComplete()
{
    BOOL __block isComplete = NO;
    
    RACSignal *oneNumberEverySecond = [[RACSignal
        empty]
        doCompleted:^{
            isComplete = YES;
        }];
    
    [oneNumberEverySecond subscribeCompleted:^{
        NSLog(@"%hhd", isComplete);
    }];
    [NSThread sleepForTimeInterval:5.0f];
}

void simpleScanEncapsulatingState()
{
    RACSignal *oneNumberEverySecond = [[[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:[RACTuple tupleWithObjects:@0, [NSDate date], nil] reduce:^id(RACTuple *running, id next) {
           NSDate *start = [running second];
           NSTimeInterval interval = [next timeIntervalSinceDate:start];
           return [RACTuple tupleWithObjects:[NSNumber numberWithInt:(int)interval], start, nil];
        }]
        map:^id(RACTuple *value) {
            return [value first];
        }];
    [oneNumberEverySecond
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }
     ];
    [NSThread sleepForTimeInterval:10.0f];
}

#pragma mark Sharing Operators

void simplePublish()
{
    RACSignal *oneNumberEverySecond = [[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           return @(running.unsignedIntegerValue + 1);
        }];
    
    // Each subscription starts a new sequence
    RACDisposable *sub1 = [oneNumberEverySecond subscribeNext:^(id x) {
         NSLog(@"%@", x);
     }];
    [NSThread sleepForTimeInterval:5.0f];
    RACDisposable *sub2 = [oneNumberEverySecond subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
    
    [NSThread sleepForTimeInterval:5.0f];
    [sub1 dispose];
    [sub2 dispose];
    
    RACSignal *oneNumberEverySecondShared = [[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           return @(running.unsignedIntegerValue + 1);
        }];

    RACMulticastConnection *shared = [oneNumberEverySecondShared publish];
    [[shared signal] subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
    [[shared signal] subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
    [NSThread sleepForTimeInterval:5.0f];
    [shared connect];
    
    [NSThread sleepForTimeInterval:5.0f];
    
    [[shared signal] subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
    
    [NSThread sleepForTimeInterval:10.0f];
}

void simpleMulticastReplay()
{
    RACSignal *oneNumberEverySecond = [[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           return @(running.unsignedIntegerValue + 1);
        }];

    RACMulticastConnection *shared = [oneNumberEverySecond multicast:[RACReplaySubject subject]];
    [[shared signal] subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
    [[shared signal] subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
    [shared connect];
    
    [NSThread sleepForTimeInterval:5.0f];
    
    [[shared signal] subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
    
    [NSThread sleepForTimeInterval:5.0f];
}

void simpleMulticastBehavior()
{
    RACSignal *oneNumberEverySecond = [[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           return @(running.unsignedIntegerValue + 1);
        }];

    RACMulticastConnection *shared = [oneNumberEverySecond multicast:[RACBehaviorSubject subject]];
    [[shared signal] subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
    [[shared signal] subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
    [shared connect];
    
    [NSThread sleepForTimeInterval:5.0f];
    
    [[shared signal] subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
    
    [NSThread sleepForTimeInterval:5.0f];
}

void simpleReplay()
{
    RACSignal *oneNumberEverySecond = [[[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           return @(running.unsignedIntegerValue + 1);
        }]
        replay];

    [oneNumberEverySecond subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
    [oneNumberEverySecond subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
    
    [NSThread sleepForTimeInterval:5.0f];
    
    [oneNumberEverySecond subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
    
    [NSThread sleepForTimeInterval:5.0f];
}

void simpleReplayLast()
{
    RACSignal *oneNumberEverySecond = [[[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           return @(running.unsignedIntegerValue + 1);
        }]
        replayLast];

    [oneNumberEverySecond subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
    [oneNumberEverySecond subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
    
    [NSThread sleepForTimeInterval:5.0f];
    
    [oneNumberEverySecond subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
    
    [NSThread sleepForTimeInterval:5.0f];
}

void simpleReplayLazily()
{
    RACSignal *oneNumberEverySecond = [[[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           return @(running.unsignedIntegerValue + 1);
        }]
        replay];
    
    [NSThread sleepForTimeInterval:5.0f];
    
    RACDisposable *sub1 = [oneNumberEverySecond subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
    
    [NSThread sleepForTimeInterval:5.0f];
    [sub1 dispose];
    
    RACSignal *oneNumberEverySecondLazy = [[[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           return @(running.unsignedIntegerValue + 1);
        }]
        replayLazily];
    
    [NSThread sleepForTimeInterval:5.0f];
    
    [oneNumberEverySecondLazy subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
    
    [NSThread sleepForTimeInterval:5.0f];
}

#pragma mark Scheduling Operators

void simpleSubscribeOn()
{
    RACSignal *firstThreeNumbers = [RACSignal
        createSignal:^(id<RACSubscriber> subscriber) {
            [subscriber sendNext:@1];
            [NSThread sleepForTimeInterval:1.0f];
            [subscriber sendNext:@2];
            [NSThread sleepForTimeInterval:1.0f];
            [subscriber sendNext:@3];
            [NSThread sleepForTimeInterval:1.0f];
            [subscriber sendCompleted];
            return [RACDisposable disposableWithBlock:^{}];
        }];
    
    [firstThreeNumbers
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    
    NSLog(@"Main thread completed.");
    NSError *error;
    [firstThreeNumbers waitUntilCompleted:&error];
    
    [[firstThreeNumbers
        subscribeOn:[RACScheduler scheduler]]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    
    NSLog(@"Main thread completed.");
    [firstThreeNumbers waitUntilCompleted:&error];
}

void simpleDeliverOn()
{
    RACSignal *firstThreeNumbers = [RACSignal
        createSignal:^(id<RACSubscriber> subscriber) {
            [subscriber sendNext:@1];
            [NSThread sleepForTimeInterval:1.0f];
            [subscriber sendNext:@2];
            [NSThread sleepForTimeInterval:1.0f];
            [subscriber sendNext:@3];
            [NSThread sleepForTimeInterval:1.0f];
            [subscriber sendCompleted];
            return [RACDisposable disposableWithBlock:^{}];
        }];
    
    [firstThreeNumbers
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
            NSLog(@"%@", [NSThread currentThread]);
        }];
    
    NSLog(@"Main thread completed.");
    NSError *error;
    [firstThreeNumbers waitUntilCompleted:&error];
    
    [[firstThreeNumbers
        deliverOn:[RACScheduler scheduler]]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
            NSLog(@"%@", [NSThread currentThread]);
        }];
    
    NSLog(@"Main thread completed.");
    [firstThreeNumbers waitUntilCompleted:&error];

    [firstThreeNumbers
     subscribeNext:^(id x) {
         NSLog(@"%@", x);
         NSLog(@"%@", [NSThread currentThread]);
     }];
    
    NSLog(@"Main thread completed.");
    [firstThreeNumbers waitUntilCompleted:&error];
}

#pragma mark Main

int main(int argc, const char * argv[])
{

    @autoreleasepool {
        simpleScan();
    }
    return 0;
}
