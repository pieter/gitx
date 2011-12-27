//
//  BMScript.m
//  BMScriptTest
//
//  Created by Andre Berg on 11.09.09.
//  Copyright 2009 Berg Media. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//    http://www.apache.org/licenses/LICENSE-2.0
//  
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

/// @cond HIDDEN

#import "BMScript.h"

#if BMSCRIPT_ENABLE_DTRACE
#import "BMScriptProbes.h"      /* dtrace probes auto-generated from .d file(s) */
#endif

#include <unistd.h>             /* for usleep       */
#include <pthread.h>            /* for pthread_*    */

#define BMSCRIPT_INSERTION_TOKEN    @"%@"   /* used by templates to mark locations where a replacement insertions should occur */
#define BM_NSSTRING_TRUNCATE_LENGTH 20      /* used by -truncate, defined in NSString (BMScriptUtilities) */

#ifndef BMSCRIPT_DEBUG_HISTORY
    #define BMSCRIPT_DEBUG_HISTORY  0
#endif

#if (BMSCRIPT_THREAD_SAFE && BMSCRIPT_ENABLE_DTRACE)
    #if BMSCRIPT_FAST_LOCK
        #define BM_LOCK(name) \
        BM_PROBE(ACQUIRE_LOCK_START, (char *) [BMStringFromBOOL(BMSCRIPT_FAST_LOCK) UTF8String]); \
        static pthread_mutex_t mtx_##name = PTHREAD_MUTEX_INITIALIZER; \
        if (pthread_mutex_lock(&mtx_##name)) {\
            printf("*** Warning: Lock failed! Application behaviour may be undefined. Exiting...");\
            exit(EXIT_FAILURE);\
        }
        #define BM_UNLOCK(name) \
        if ((pthread_mutex_unlock(&mtx_##name) != 0)) {\
            printf("*** Warning: Unlock failed! Application behaviour may be undefined. Exiting...");\
            exit(EXIT_FAILURE);\
        }\
        BM_PROBE(ACQUIRE_LOCK_END, (char *) [BMStringFromBOOL(BMSCRIPT_FAST_LOCK) UTF8String]);
    #else
        #define BM_LOCK(name) \
        BM_PROBE(ACQUIRE_LOCK_START, (char *) [BMStringFromBOOL(BMSCRIPT_FAST_LOCK) UTF8String]);\
        static id const sync_##name##_ref = @""#name;\
        @synchronized(sync_##name##_ref) {
        #define BM_UNLOCK(name) }\
        BM_PROBE(ACQUIRE_LOCK_END, (char *) [BMStringFromBOOL(BMSCRIPT_FAST_LOCK) UTF8String]);
    #endif
#elif (BMSCRIPT_THREAD_SAFE && !BMSCRIPT_ENABLE_DTRACE)
    #if BMSCRIPT_FAST_LOCK
        #define BM_LOCK(name) \
        static pthread_mutex_t mtx_##name = PTHREAD_MUTEX_INITIALIZER; \
        if (pthread_mutex_lock(&mtx_##name)) {\
            printf("*** Warning: Lock failed! Application behaviour may be undefined. Exiting...");\
            exit(EXIT_FAILURE);\
        }
        #define BM_UNLOCK(name) \
        if ((pthread_mutex_unlock(&mtx_##name) != 0)) {\
            printf("*** Warning: Unlock failed! Application behaviour may be undefined. Exiting...");\
            exit(EXIT_FAILURE);\
        };
    #else
        #define BM_LOCK(name) \
        static id const sync_##name##_ref = @""#name;\
        @synchronized(sync_##name##_ref) {
        #define BM_UNLOCK(name) };
    #endif
#else 
    #define BM_LOCK(name)
    #define BM_UNLOCK(name)
#endif


NSString * const BMScriptOptionsTaskLaunchPathKey  = @"BMScriptOptionsTaskLaunchPathKey";
NSString * const BMScriptOptionsTaskArgumentsKey   = @"BMScriptOptionsTaskArgumentsKey";
NSString * const BMScriptOptionsVersionKey         = @"BMScriptOptionsVersionKey"; 

NSString * const BMScriptTaskDidEndNotification            = @"BMScriptTaskDidEndNotification";
NSString * const BMScriptNotificationTaskResults           = @"BMScriptNotificationTaskResults";
NSString * const BMScriptNotificationTaskTerminationStatus = @"BMScriptNotificationTaskTerminationStatus";

NSString * const BMScriptTemplateArgumentMissingException  = @"BMScriptTemplateArgumentMissingException";
NSString * const BMScriptTemplateArgumentsMissingException = @"BMScriptTemplateArgumentsMissingException";

NSString * const BMScriptLanguageProtocolDoesNotConformException = @"BMScriptLanguageProtocolDoesNotConformException";
NSString * const BMScriptLanguageProtocolMethodMissingException  = @"BMScriptLanguageProtocolMethodMissingException";
NSString * const BMScriptLanguageProtocolIllegalAccessException  = @"BMScriptLanguageProtocolIllegalAccessException";


/* Empty braces means this is an "Extension" as opposed to a Category */
@interface BMScript ()

@property (BM_ATOMIC copy, readwrite) NSString * result;
@property (BM_ATOMIC assign) NSInteger returnValue;
@property (BM_ATOMIC assign) NSInteger bgTaskReturnValue;
@property (BM_ATOMIC copy) NSString * partialResult;
@property (BM_ATOMIC assign) BOOL isTemplate;
@property (BM_ATOMIC retain) NSTask * task;
@property (BM_ATOMIC retain) NSPipe * pipe;
@property (BM_ATOMIC retain) NSTask * bgTask;
@property (BM_ATOMIC retain) NSPipe * bgPipe;

- (void) stopTask;
- (BOOL) setupTask;
- (void) cleanupTask:(NSTask *)whichTask;
- (TerminationStatus) launchTaskAndStoreResult;
- (void) setupAndLaunchBackgroundTask;
- (void) taskTerminated:(NSNotification *)aNotification;
- (void) appendData:(NSData *)d;
- (void) dataReceived:(NSNotification *)aNotification;
- (const char *) gdbDataFormatter;

@end

@implementation BMScript

@dynamic delegate;

@synthesize script;
@synthesize options;
@synthesize partialResult;
@synthesize result;
@synthesize isTemplate;
@synthesize history;
@synthesize task;
@synthesize pipe;
@synthesize bgTask;
@synthesize bgPipe;
@synthesize returnValue;
@synthesize bgTaskReturnValue;

//=========================================================== 
//  delegate 
//=========================================================== 
- (id<BMScriptDelegateProtocol>)delegate {
    return delegate; 
}

- (void)setDelegate:(id<BMScriptDelegateProtocol>)newDelegate {
    BM_LOCK(delegate)
    if (delegate != newDelegate) {
        delegate = newDelegate;
    }
    BM_UNLOCK(delegate)
}

// MARK: Description

- (NSString *) description {
    return [NSString stringWithFormat:@"%@\n"
                                      @"  script: '%@'\n"
                                      @"  result: '%@'\n"
                                      @"delegate: '%@'\n"
                                      @" options: '%@'", 
            [super description], 
            [script quote], 
            [result quote], 
            (delegate == self? (id)@"self" : delegate), 
            [options descriptionInStringsFileFormat]];
}

- (NSString *) debugDescription {
    return [NSString stringWithFormat:@"%@\n"
                                      @" history (%d item%@): '%@'\n"
                                      @"    task: '%@'\n"
                                      @"    pipe: '%@'\n"
                                      @"  bgTask: '%@'\n"
                                      @"  bgPipe: '%@'\n", 
            [self description], [history count], ([history count] == 1 ? @"" : @"s"), history, task, pipe, bgTask, bgPipe ];
}

- (const char *) gdbDataFormatter {
    
    NSString * launchPath = [options objectForKey:BMScriptOptionsTaskLaunchPathKey];
    NSArray * args = [options objectForKey:BMScriptOptionsTaskArgumentsKey];
    NSMutableString * accString = [NSMutableString string];
    if (args) {
        for (NSString * arg in args) {
            [accString appendFormat:@" %@%@", arg, ([arg isEqualToString:@""] ? @"" : @", ")];
        }
    }
    NSString * desc = [NSString stringWithFormat:@"options = %@%@script = %@, result = %@, isTemplate = %@", 
                       (launchPath ? launchPath : @"nil, "),
                       (accString ? accString : @"nil, "),
                       (script ? [[script quote] truncate] : @"nil"), 
                       (result ? [[result quote] truncate] : @"nil"),
                       BMStringFromBOOL(isTemplate)];
    
    return [desc UTF8String];
}

// MARK: Deallocation

- (void) dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (BM_EXPECTED([task isRunning], 0)) [task terminate];
    if (BM_EXPECTED([bgTask isRunning], 0)) [bgTask terminate];
    
    [script release], script = nil;
    [history release], history = nil;
    [options release], options = nil;
    [result release], result = nil;
    [partialResult release], partialResult = nil;
    [task release], task = nil;
    [pipe release], pipe = nil;
    [bgTask release], bgTask = nil;
    [bgPipe release], bgPipe = nil;
    
    [super dealloc];
}

- (void) finalize {
    
    if (BM_EXPECTED([task isRunning], 0)) [task terminate];
    if (BM_EXPECTED([bgTask isRunning], 0)) [bgTask terminate];
        
    [super finalize];
}

// MARK: Initializer Methods

- (id)init {
    
    NSLog(@"BMScript Warning: Initializing instance %@ with default values! "
          @"(options = \"/bin/echo\", \"\", script source = '<script source placeholder>')", [super description]);
    
    return [self initWithScriptSource:nil options:nil]; 
}

/* designated initializer */
- (id) initWithScriptSource:(NSString *)scriptSource options:(NSDictionary *)scriptOptions {

    #if (BMSCRIPT_ENABLE_DTRACE)
        BM_PROBE(INIT_BEGIN, 
                 (char *) (scriptSource ? [[scriptSource quote] UTF8String] : "(null)"), 
                 (char *) (scriptOptions ? [[[scriptOptions descriptionInStringsFileFormat] quote] UTF8String] : "(null)"));
    #endif
        
    if ([self isDescendantOfClass:[BMScript class]] && ![self conformsToProtocol:@protocol(BMScriptLanguageProtocol)]) {
        @throw [NSException exceptionWithName:BMScriptLanguageProtocolDoesNotConformException 
                                       reason:@"BMScript Error: "
                                              @"Descendants of BMScript must conform to the BMScriptLanguageProtocol!" 
                                     userInfo:nil];
    }
    self = [super init];
    if (BM_EXPECTED(self != nil, 1)) {
        
        if (scriptOptions) {
            options = [scriptOptions retain];
        } else {
            if ([self isDescendantOfClass:[BMScript class]] && ![self respondsToSelector:@selector(defaultOptionsForLanguage)]) {
                @throw [NSException exceptionWithName:BMScriptLanguageProtocolMethodMissingException 
                                               reason:@"BMScript Error: Descendants of BMScript must implement "
                                                      @"-[<BMScriptLanguageProtocol> defaultOptionsForLanguage]." 
                                             userInfo:nil];
            } else if ([self respondsToSelector:@selector(defaultOptionsForLanguage)]) {
                options = [[self performSelector:@selector(defaultOptionsForLanguage)] retain];
            } else {
                NSLog(@"BMScript Warning: Initializing instance %@ with default options: BMSynthesizeOptions(@\"/bin/echo\", @\"\")", [super description]);
                options = [BMSynthesizeOptions(@"/bin/echo", @"") retain];
            }
            
        }
        
        if (scriptSource) {
            if (scriptOptions || options) {
                script = [scriptSource retain];
            } else {
                // if scriptOptions == nil, we run with default options, namely /bin/echo so it might be better 
                // to put quotes around the scriptSource
                NSLog(@"BMScript Info: Wrapping script source with single quotes. This is a precautionary measure "
                      @"because we are using default script options (instance initialized with options:nil).");
                script = [[scriptSource wrapSingleQuotes] retain];
            }
        } else {
            if ([self respondsToSelector:@selector(defaultScriptSourceForLanguage)]) {
                script = [[self performSelector:@selector(defaultScriptSourceForLanguage)] retain];
            } else {
                NSLog(@"BMScript Warning: Initializing instance %@ with default script: '<script source placeholder>'", [super description]);
                script = @"'<script source placeholder>'";
            }
        }
        
        history = [[NSMutableArray alloc] init];
        partialResult = [[NSString alloc] init];
        
        // tasks/pipes will be allocated, initialized (and destroyed) lazily
        // on an as-needed basis because NSTasks are one-shot (not for re-use)
    }
    #if (BMSCRIPT_ENABLE_DTRACE)    
        BM_PROBE(INIT_END, (char *) [[[self debugDescription] quote] UTF8String]);
    #endif    
    return self;
}

- (id) initWithTemplateSource:(NSString *)templateSource options:(NSDictionary *)scriptOptions {
    
    if (templateSource) {
        BM_LOCK(isTemplate)
        self.isTemplate = YES;
        BM_UNLOCK(isTemplate)
        templateSource = [templateSource stringByReplacingOccurrencesOfString:@"%" withString:@"%%"];
        templateSource = [templateSource stringByReplacingOccurrencesOfString:@"%%{}" withString:@"%%{"BMSCRIPT_INSERTION_TOKEN"}"];
        return [self initWithScriptSource:templateSource options:scriptOptions];
    }
    return nil;
}

- (id) initWithContentsOfFile:(NSString *)path options:(NSDictionary *)scriptOptions {
    
    NSError * err = nil;
    NSString * scriptSource = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&err];
    if (BM_EXPECTED(scriptSource && !err, 1)) {
        BM_LOCK(isTemplate)
        self.isTemplate = NO;
        BM_UNLOCK(isTemplate)
        return [self initWithScriptSource:scriptSource options:scriptOptions];
    } else {
        NSLog(@"BMScript Error: Reading script source from file at '%@' failed: %@", path, [err localizedFailureReason]);
    }
    return nil;
}

- (id) initWithContentsOfTemplateFile:(NSString *)path options:(NSDictionary *)scriptOptions {
    
    NSError * err;
    NSString * scriptSource = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&err];
    if (BM_EXPECTED(scriptSource != nil, 1)) {
        return [self initWithTemplateSource:scriptSource options:scriptOptions];
    } else {
        NSLog(@"BMScript Error: Reading script source from file at '%@' failed: %@", path, [err localizedFailureReason]);
    }
    return nil;
}


// MARK: Factory Methods

+ (id) scriptWithSource:(NSString *)scriptSource options:(NSDictionary *)scriptOptions { 
    return [[[self alloc] initWithScriptSource:scriptSource options:scriptOptions] autorelease]; 
}

+ (id) scriptWithContentsOfFile:(NSString *)path options:(NSDictionary *)scriptOptions {
    return [[[self alloc] initWithContentsOfFile:path options:scriptOptions] autorelease];
}

+ (id) scriptWithContentsOfTemplateFile:(NSString *)path options:(NSDictionary *)scriptOptions {
    return [[[self alloc] initWithContentsOfTemplateFile:path options:scriptOptions] autorelease];
}

// MARK: Private Methods

- (BOOL) setupTask {
    
    BOOL success = NO;
    
    if (BM_EXPECTED([task isRunning], 0)) {
        [task terminate];
    } else {

        #if (BMSCRIPT_ENABLE_DTRACE)
            BM_PROBE(SETUP_TASK_BEGIN);
        #endif

        task = [[NSTask alloc] init];
        pipe = [[NSPipe alloc] init];
        
        if (task && pipe) {
            
            NSString * path = [options objectForKey:BMScriptOptionsTaskLaunchPathKey];
            NSArray * args = [options objectForKey:BMScriptOptionsTaskArgumentsKey];
            
            // If BMSynthesizeOptions is called with "nil" as second argument 
            // that effectively sets up BMScriptOptionsTaskArgumentsKey as 
            // [NSArray arrayWithObjects:nil] which in turn becomes a "__NSArray0"
            if (!args || [args isEmptyStringArray] || [args isZeroArray]) {
                //NSLog(@"BMScript Warning: Zero array set as task arguments.\n args = %@, args class = %@", args, NSStringFromClass([args class]));
                args = [NSArray arrayWithObject:script];
            } else {
                args = [args arrayByAddingObject:script];
            }  
            
            [task setLaunchPath:path];
            [task setArguments:args];
            [task setStandardOutput:pipe];
            
            // Unfortunately we need the following define if we want to use SenTestingKit for unit testing. Since we are telling 
            // BMScript here to write to stdout and stderr SenTestingKit will actually output certain messages to stderr, messages
            // which can include the PID of the current task used for the testing. This invalidates testing task ouput from
            // two tasks even if their output is identical because their PID is not. To work around this, we can use a define which
            // will be set to 1 in the build settings for our unit tests via OTHER_CFLAGS and -DBMSCRIPT_UNIT_TESTS=1.
            if (!BMSCRIPT_UNIT_TEST) {
                //NSLog(@"BMScript: Info: setting [task standardError:pipe]");
                [task setStandardError:pipe];
            }
            #if (BMSCRIPT_ENABLE_DTRACE)            
                BM_PROBE(SETUP_TASK_END);
            #endif
            success = YES;
        }
    }
    return success; 
}

/* fires a one-off (blocking or synchroneous) task and stores the result */
- (TerminationStatus) launchTaskAndStoreResult {
    
    TerminationStatus status = BMScriptNotExecuted;
    NSData * data = nil;
    
    BM_LOCK(task)
    @try {
        #if (BMSCRIPT_ENABLE_DTRACE)
            BM_PROBE(NET_EXECUTION_BEGIN, (char *) [[BMStringFromTerminationStatus(status) wrapSingleQuotes] UTF8String]);
        #endif
        [task launch];
    }
    @catch (NSException * e) {
        self.returnValue = status = BMScriptFailedWithException;
        #if (BMSCRIPT_ENABLE_DTRACE)
                BM_PROBE(NET_EXECUTION_END, (char *) [[BMStringFromTerminationStatus(status) wrapSingleQuotes] UTF8String]);
        #endif
        goto endnow;
    }    
    [task waitUntilExit];
    #if (BMSCRIPT_ENABLE_DTRACE)
        BM_PROBE(NET_EXECUTION_END, (char *) [[BMStringFromTerminationStatus(status) wrapSingleQuotes] UTF8String]);
    #endif
    data = [[pipe fileHandleForReading] readDataToEndOfFile];
    if (BM_EXPECTED([task isRunning], 0)) [task terminate];
    BM_UNLOCK(task)
    
    self.returnValue = status = [task terminationStatus];
    
    NSString * string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSString * aResult = string;
    
    BM_LOCK(result)
    BOOL shouldSetResult = YES;
    if ([delegate respondsToSelector:@selector(shouldSetResult:)]) {
        shouldSetResult = [delegate shouldSetResult:string];
    }
    if (shouldSetResult) {
        if ([delegate respondsToSelector:@selector(willSetResult:)]) {
            aResult = [delegate willSetResult:string];
        }
        self.result = aResult;
    }
    BM_UNLOCK(result)

    [string release], string = nil;
     
    goto endnow;
    
endnow:
    [self cleanupTask:task];
    return status;
}

/* fires a one-off (non-blocking or asynchroneous) task and reels in the results 
   one after another thru notifications */
- (void) setupAndLaunchBackgroundTask {
    
    if (BM_EXPECTED([bgTask isRunning], 0)) {
        [bgTask terminate];
    } else {
        if (!bgTask) {
            #if (BMSCRIPT_ENABLE_DTRACE)            
                BM_PROBE(SETUP_BG_TASK_BEGIN);
            #endif

            // Create a task and pipe
            bgTask = [[NSTask alloc] init];
            bgPipe = [[NSPipe alloc] init];    
            
            NSString * path = [options objectForKey:BMScriptOptionsTaskLaunchPathKey];
            NSArray * args = [options objectForKey:BMScriptOptionsTaskArgumentsKey];
            
            // If BMSynthesizeOptions is called with "nil" as second argument 
            // that effectively sets up BMScriptOptionsTaskArgumentsKey as 
            // [NSArray arrayWithObjects:nil] which in turn becomes an opaque 
            // object named "__NSArray0"
            if (!args || [args isEmptyStringArray] || [args isZeroArray]) {
                //NSLog(@"args = %@, args class = %@", args, NSStringFromClass([args class]));
                args = [NSArray arrayWithObject:script];
            } else {
                args = [args arrayByAddingObject:script];
            }  
            
            // set options for background task
            [bgTask setLaunchPath:path];
            [bgTask setArguments:args];
            [bgTask setStandardOutput:bgPipe];
            [bgTask setStandardError:bgPipe];
            
            // register for notifications
            
            // currently the execution model for background tasks is an incremental one:
            // self.partialResult is accumulated over the time the task is running and
            // posting NSFileHandleReadCompletionNotification notifications. This happens
            // through #dataReceived: which calls #appendData: until the NSTaskDidTerminateNotification 
            // is posted. Then, the partialResult is simply mirrored over to lastResult.
            // This gives the user the advantage for long running scripts to check partialResult
            // periodically and see if the task needs to be aborted.
            
            // [[NSNotificationCenter defaultCenter] addObserver:self 
            //                                          selector:@selector(dataComplete:) 
            //                                              name:NSFileHandleReadToEndOfFileCompletionNotification 
            //                                            object:bgTask];
            
            [[NSNotificationCenter defaultCenter] addObserver:self 
                                                     selector:@selector(dataReceived:) 
                                                         name:NSFileHandleReadCompletionNotification 
                                                       object:[bgPipe fileHandleForReading]];
            
            [[NSNotificationCenter defaultCenter] addObserver:self 
                                                     selector:@selector(taskTerminated:) 
                                                         name:NSTaskDidTerminateNotification 
                                                       object:bgTask];
            #if (BMSCRIPT_ENABLE_DTRACE)            
                BM_PROBE(SETUP_BG_TASK_END);
            #endif

            @try {
                [bgTask launch];
            }
            @catch (NSException * e) {
                self.bgTaskReturnValue = BMScriptFailedWithException;
                [self cleanupTask:bgTask];
            }

            // kick off pipe reading in background
            [[bgPipe fileHandleForReading] readInBackgroundAndNotify];
            //[[bgPipe fileHandleForReading] readToEndOfFileInBackgroundAndNotify];
        }
    }
}

- (void) dataReceived:(NSNotification *)aNotification {
    
	NSData * data = [[aNotification userInfo] valueForKey:NSFileHandleNotificationDataItem];
    if (BM_EXPECTED([data length] > 0, 1)) {
        [self appendData:data];
    } else {
        [self stopTask];
    }
    // fire again in background after each notification
    [[bgPipe fileHandleForReading] readInBackgroundAndNotify];
}


- (void) appendData:(NSData *)data {
    
    NSString * string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    #if (BMSCRIPT_ENABLE_DTRACE)
        BM_PROBE(APPEND_DATA_BEGIN, (char *) [string UTF8String]);
    #endif
    if (BM_EXPECTED(string != nil, 1)) {
        NSString * aPartial = string;
        BOOL shouldAppendPartial = YES;
        if ([delegate respondsToSelector:@selector(shouldAppendPartialResult:)]) {
            shouldAppendPartial = [delegate shouldAppendPartialResult:aPartial];
        }
        if (shouldAppendPartial) {
            if ([delegate respondsToSelector:@selector(willAppendPartialResult:)]) {
                aPartial = [delegate willAppendPartialResult:string];
            }
            BM_LOCK(partialResult)
            self.partialResult = [partialResult stringByAppendingString:aPartial];
            BM_UNLOCK(partialResult)
        }
    } else {
        NSLog(@"BMScript: Warning: Attempted %s but could not append to self.partialResult. Data maybe lost!", __PRETTY_FUNCTION__);
    }
    #if (BMSCRIPT_ENABLE_DTRACE)
        BM_PROBE(APPEND_DATA_END, (char *) [[partialResult quote] UTF8String]);
    #endif
    [string release], string = nil;
}

- (void) cleanupTask:(NSTask *)whichTask {
    if (task && task == whichTask) {
                
        #if (BMSCRIPT_ENABLE_DTRACE)
            BM_PROBE(CLEANUP_TASK_BEGIN);
        #endif
        BM_LOCK(task)
        [task release], task = nil;
        BM_UNLOCK(task)
        
        BM_LOCK(pipe)
        if (pipe) {
            [[pipe fileHandleForReading] closeFile];
            [pipe release], pipe = nil;
        }
        BM_UNLOCK(pipe)
        #if (BMSCRIPT_ENABLE_DTRACE)
            BM_PROBE(CLEANUP_TASK_END);
        #endif
        
    } else if (bgTask && bgTask == whichTask) {
        
        #if (BMSCRIPT_ENABLE_DTRACE)
            BM_PROBE(CLEANUP_BG_TASK_BEGIN);
        #endif
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:NSFileHandleReadCompletionNotification 
                                                      object:[bgPipe fileHandleForReading]];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                        name:NSTaskDidTerminateNotification 
                                                      object:bgTask];
        BM_LOCK(bgTask)
        [bgTask release], bgTask = nil;
        BM_UNLOCK(bgTask)
        
        BM_LOCK(bgPipe)
        if (bgPipe) {
            [[bgPipe fileHandleForReading] closeFile];
            [bgPipe release], bgPipe = nil;
        }
        BM_UNLOCK(bgPipe)
        #if (BMSCRIPT_ENABLE_DTRACE)
            BM_PROBE(CLEANUP_BG_TASK_END);
        #endif
    }
}


- (void) stopTask {
    #if (BMSCRIPT_ENABLE_DTRACE)    
        BM_PROBE(STOP_BG_TASK_BEGIN);
    #endif
    
    // read out remaining data, as the pipes have a limited buffer size 
    // and may stall on subsequent calls if full
    NSData * dataInPipe = [[bgPipe fileHandleForReading] readDataToEndOfFile];
    if (BM_EXPECTED(dataInPipe && [dataInPipe length], 0)) {
        [self appendData:dataInPipe];
    }

    if(BM_EXPECTED([bgTask isRunning], 0)) [bgTask terminate];
    
    self.bgTaskReturnValue = [bgTask terminationStatus];
    
    // task is finished, copy over the accumulated partialResults into lastResult
    NSString * string = self.partialResult;
    NSString * aResult = string;
    
    BM_LOCK(result)
    BOOL shouldSetResult = YES;
    if ([delegate respondsToSelector:@selector(shouldSetResult:)]) {
        shouldSetResult = [delegate shouldSetResult:aResult];
    }
    if (shouldSetResult) {
        if ([delegate respondsToSelector:@selector(willSetResult:)]) {
            aResult = [delegate willSetResult:string];
        }
        // we need to do the right thing here and not use the accessor methods
        // when the thread safety flag is on, since we are already in a locked 
        // section.
        #if (BMSCRIPT_THREAD_SAFE)
            result = aResult;
        #else
            self.result = aResult;
        #endif
    }
    BM_UNLOCK(result)
    
    [self cleanupTask:bgTask];

    #if (BMSCRIPT_ENABLE_DTRACE)
        BM_PROBE(BG_EXECUTE_END, (char *) [[result quote] UTF8String]);
    #endif

    NSArray * historyItem = [NSArray arrayWithObjects:script, result, nil];
    BM_LOCK(history)
    if ([delegate respondsToSelector:@selector(shouldAddItemToHistory:)]) {
        if ([delegate shouldAddItemToHistory:historyItem]) {
            [history addObject:historyItem];
        }
    } else {
        [history addObject:historyItem];
    }
    BM_UNLOCK(history)
    
    if (BMSCRIPT_DEBUG_HISTORY) {
        NSLog(@"BMScript Debug: Script '%@' executed successfully.\n"
              @"Added to history = %@", [[script quote] truncate], history);
    }
    
    NSDictionary * info = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithInteger:self.bgTaskReturnValue], BMScriptNotificationTaskTerminationStatus, 
                                                                          result, BMScriptNotificationTaskResults, nil];
    BM_LOCK(self)
    [[NSNotificationCenter defaultCenter] postNotificationName:BMScriptTaskDidEndNotification object:self userInfo:info];
    BM_UNLOCK(self)
    
    #if (BMSCRIPT_ENABLE_DTRACE)
        BM_PROBE(STOP_BG_TASK_END);
    #endif
}

- (void) taskTerminated:(NSNotification *) aNotification { 
#pragma unused(aNotification)
    [self stopTask]; 
}

// MARK: Templates

- (BOOL) saturateTemplateWithArgument:(NSString *)tArg {
    #if (BMSCRIPT_ENABLE_DTRACE)    
        BM_PROBE(SATURATE_WITH_ARGUMENT_BEGIN, (char *) [tArg UTF8String]);
    #endif
    if (self.isTemplate) {
        BM_LOCK(script)
        self.script = [NSString stringWithFormat:script, tArg];
        self.isTemplate = NO;
        BM_UNLOCK(script)
        return YES;
    }
    return NO;
    #if (BMSCRIPT_ENABLE_DTRACE)
        BM_PROBE(SATURATE_WITH_ARGUMENT_END, (char *) [[script quote] UTF8String]);
    #endif
}

- (BOOL) saturateTemplateWithArguments:(NSString *)firstArg, ... {
    #if (BMSCRIPT_ENABLE_DTRACE)    
        BM_PROBE(SATURATE_WITH_ARGUMENTS_BEGIN);
    #endif
    BOOL success = NO;
    if (self.isTemplate) {
        NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

        // determine how many replacements we need to make
        NSInteger numTokens = [script countOccurrencesOfString:BMSCRIPT_INSERTION_TOKEN];
        if (numTokens == NSNotFound) {
            goto endnow;
        }
        
        NSString * accumulator = self.script;
        NSString * arg;
        
        va_list arglist;
        va_start(arglist, firstArg);
        
        NSRange searchRange = NSMakeRange(0, [accumulator rangeOfString:BMSCRIPT_INSERTION_TOKEN].location + [BMSCRIPT_INSERTION_TOKEN length]);
        
        accumulator = [accumulator stringByReplacingOccurrencesOfString:BMSCRIPT_INSERTION_TOKEN
                                                             withString:firstArg 
                                                                options:NSLiteralSearch 
                                                                  range:searchRange];
        
        while (--numTokens > 0) {
            arg = va_arg(arglist, NSString *);
            searchRange = NSMakeRange(0, [accumulator rangeOfString:BMSCRIPT_INSERTION_TOKEN].location + [BMSCRIPT_INSERTION_TOKEN length]);
            accumulator = [accumulator stringByReplacingOccurrencesOfString:BMSCRIPT_INSERTION_TOKEN
                                                                 withString:arg 
                                                                    options:NSLiteralSearch 
                                                                      range:searchRange];
            if (numTokens <= 1) break;
        }
        
        va_end(arglist);
        
        self.script = [accumulator stringByReplacingOccurrencesOfString:@"%%" withString:@"%"];
        self.isTemplate = NO;

        [pool drain];
        success = YES;
        goto endnow;
    }
endnow:
    #if (BMSCRIPT_ENABLE_DTRACE)
        BM_PROBE(SATURATE_WITH_ARGUMENTS_END, (char *) [[script quote] UTF8String]);
    #endif
    return success;
}

- (BOOL) saturateTemplateWithDictionary:(NSDictionary *)dictionary {
    
    BOOL success = NO;
    #if (BMSCRIPT_ENABLE_DTRACE)
        BM_PROBE(SATURATE_WITH_DICTIONARY_BEGIN, (char *) [[[dictionary descriptionInStringsFileFormat] quote] UTF8String]);
    #endif
    if (self.isTemplate) {
        
        NSString * accumulator = self.script;
        
        NSArray * keys = [dictionary allKeys];
        NSArray * values = [dictionary allValues];
        
        // FIXME: Don't replace escaped token sequences
        NSInteger i = 0;
        for (NSString * key in keys) {
            accumulator = [accumulator stringByReplacingOccurrencesOfString:@"\\%" withString:@"%%%%"];
            accumulator = [accumulator stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%%{"BMSCRIPT_INSERTION_TOKEN"}", key ] 
                                                                 withString:[values objectAtIndex:i]];
            i++;
        }
        
        BM_LOCK(script)
        self.script = [accumulator stringByReplacingOccurrencesOfString:@"%" withString:@""];
        self.isTemplate = NO;
        BM_UNLOCK(script)
        
        success = YES;
    }
    #if (BMSCRIPT_ENABLE_DTRACE)
        BM_PROBE(SATURATE_WITH_DICTIONARY_END, (char *) [[script quote] UTF8String]);
    #endif
    return success;
}



// MARK: Execution

- (TerminationStatus) execute {
    if (self.isTemplate) {
        @throw [NSException exceptionWithName:BMScriptTemplateArgumentMissingException 
                                       reason:@"BMScript Error: Please define all replacement values for the current template "
                                              @"by calling one of the -[saturateTemplate...] methods prior to execution" 
                                     userInfo:nil];
    }
    TerminationStatus success = [self executeAndReturnResult:nil];
    return success;
}

- (TerminationStatus) executeAndReturnResult:(NSString **)results {
    
    if (self.isTemplate) {
        @throw [NSException exceptionWithName:BMScriptTemplateArgumentMissingException 
                                       reason:@"BMScript Error: please define all replacement values for the current template "
                                              @"by calling one of the -[saturateTemplate...] methods prior to execution" 
                                     userInfo:nil];
    }
    
    TerminationStatus success = [self executeAndReturnResult:results error:nil];
    
    return success;
}

- (TerminationStatus) executeAndReturnResult:(NSString **)results error:(NSError **)error {
    #if (BMSCRIPT_ENABLE_DTRACE)
        BM_PROBE(EXECUTE_BEGIN, 
                 (char *) [[[task launchPath] wrapSingleQuotes] UTF8String],
                 (char *) [[script quote] UTF8String], 
                 (char *) [BMStringFromBOOL(isTemplate) UTF8String]);
    #endif
    
    BOOL success = NO;
    TerminationStatus status = BMScriptNotExecuted;
    
    if (self.isTemplate) {
        if (error) {
            NSDictionary * errorDict = 
                [NSDictionary dictionaryWithObject:@"BMScript Error: Please define all replacement values for the current template "
                                                   @"by calling one of the -saturateTemplate... methods prior to execution" 
                                            forKey:NSLocalizedFailureReasonErrorKey];
            *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:0 userInfo:errorDict];
        } else {
            @throw [NSException exceptionWithName:BMScriptTemplateArgumentMissingException 
                                           reason:@"BMScript Error: Please define all replacement values for the current template "
                                                  @"by calling one of the -saturateTemplate... methods prior to execution" 
                                         userInfo:nil];            
        }            
    } else {// isTemplate is NO
        
        BM_LOCK(task)
        success = [self setupTask];
        BM_UNLOCK(task)
        
        if (BM_EXPECTED(success, 1)) {
            
            status = [self launchTaskAndStoreResult];
            
            if (status == BMScriptFailedWithException) {
                if (error) {
                    NSString * reason = [NSString stringWithFormat:@"BMScript Error: Executing the task raised an exception."];
                    NSString * suggestion = [NSString stringWithFormat:@"Check launch path (path to the executable) and task arguments. "
                                                                       @"Most of the time an exception is raised by NSTask because either or both are inappropriate."];               
                    NSDictionary * errorDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                                        reason, NSLocalizedFailureReasonErrorKey, 
                                                    suggestion, NSLocalizedRecoverySuggestionErrorKey, nil];
                    
                    *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:0 userInfo:errorDict];
                }
            } else if (status == BMScriptNotExecuted) {
                if (error) {
                    NSString * reason = [NSString stringWithFormat:@"BMScript Error: Unable to execute task."];
                    NSString * suggestion = [NSString stringWithFormat:@"Check launch path (path to the executable) and task arguments. "
                                                                       @"Most of the time an exception is raised because either or both are inappropriate."];
                    NSDictionary * errorDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                                        reason, NSLocalizedFailureReasonErrorKey, 
                                                    suggestion, NSLocalizedRecoverySuggestionErrorKey, nil];
                    
                    *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:0 userInfo:errorDict];
                }
            } else {
                if (results) {
                    *results = result;
                }
                
                BM_LOCK(history)
                NSArray * historyItem = [NSArray arrayWithObjects:script, result, nil];
                if ([delegate respondsToSelector:@selector(shouldAddItemToHistory:)]) {
                    if ([delegate shouldAddItemToHistory:historyItem]) {
                        [history addObject:historyItem];
                    }
                } else {
                    [history addObject:historyItem];
                }
                BM_UNLOCK(history)
                if (BMSCRIPT_DEBUG_HISTORY) {
                    NSLog(@"BMScript Debug: Script '%@' executed successfully.\n"
                          @"Added to history = %@", [[script quote] truncate], history);
                }
            }
        } else {
            if (error) {
                NSDictionary * errorDict = 
                [NSDictionary dictionaryWithObject:@"BMScript Error: Task setup failed! (sorry, don't have more info than that...)" 
                                            forKey:NSLocalizedFailureReasonErrorKey];
                *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:0 userInfo:errorDict];
            }
        }
    }

    #if (BMSCRIPT_ENABLE_DTRACE)
        BM_PROBE(EXECUTE_END, (char *) [[result quote] UTF8String]);
    #endif

    return status;
}


- (void) executeInBackgroundAndNotify {
    if (self.isTemplate) {
            @throw [NSException exceptionWithName:BMScriptTemplateArgumentMissingException 
                                           reason:@"please define all replacement values for the current template "
                                                  @"by calling one of the -[saturateTemplate...] methods prior to execution" 
                                         userInfo:nil];            
    }
    
    #if (BMSCRIPT_ENABLE_DTRACE)    
        BM_PROBE(BG_EXECUTE_BEGIN, 
                 (char *) [[[options objectForKey:BMScriptOptionsTaskLaunchPathKey] wrapSingleQuotes] UTF8String],
                 (char *) [[script quote] UTF8String], 
                 (char *) [BMStringFromBOOL(isTemplate) UTF8String]);
    #endif
    
    [self setupAndLaunchBackgroundTask];
    
}

// MARK: History

- (NSString *) scriptSourceFromHistoryAtIndex:(NSInteger)index {

    #if (BMSCRIPT_ENABLE_DTRACE)
        BM_PROBE(SCRIPT_AT_INDEX_BEGIN, index, (int) [history count]);
    #endif
    NSString * aScript = nil;
    NSInteger hc = [history count];
    if (hc > 0 && (index >= 0 && index <= hc)) {
        NSString * item = [[self.history objectAtIndex:index] objectAtIndex:0];
        if ([delegate respondsToSelector:@selector(shouldReturnItemFromHistory:)]) {
            if ([delegate shouldReturnItemFromHistory:item]) {
                aScript = item;
            }
        } else {
            aScript = item;
        }
    } else {
        @throw [NSException exceptionWithName:NSInvalidArgumentException 
                                       reason:[NSString stringWithFormat:@"Index (%d) out of bounds (%d)", index, hc]
                                     userInfo:nil];                    
    }
    #if (BMSCRIPT_ENABLE_DTRACE)
        BM_PROBE(SCRIPT_AT_INDEX_END, (char *) [[aScript quote] UTF8String], (int) [history count]);
    #endif
    return aScript;
}

- (NSString *) resultFromHistoryAtIndex:(NSInteger)index {
    #if (BMSCRIPT_ENABLE_DTRACE)
        BM_PROBE(RESULT_AT_INDEX_BEGIN, index, (int) [history count]);
    #endif
    NSString * aResult = nil;
    NSInteger hc = [history count];
    if (hc > 0 && (index >= 0 && index <= hc)) {
        NSString * item = [[history objectAtIndex:index] objectAtIndex:1];
        if ([delegate respondsToSelector:@selector(shouldReturnItemFromHistory:)]) {
            if ([delegate shouldReturnItemFromHistory:item]) {
                aResult = item;
            }
        } else {
            aResult = item;
        }
    } else {
        @throw [NSException exceptionWithName:NSInvalidArgumentException 
                                       reason:[NSString stringWithFormat:@"Index (%d) out of bounds (%d)", index, hc]
                                     userInfo:nil];                    
    }    
    #if (BMSCRIPT_ENABLE_DTRACE)
        BM_PROBE(RESULT_AT_INDEX_END, (char *) [[aResult quote] UTF8String], (int) [history count]);
    #endif
    return aResult;
}

- (NSString *) lastScriptSourceFromHistory {
    #if (BMSCRIPT_ENABLE_DTRACE)    
        BM_PROBE(LAST_SCRIPT_BEGIN, (int) [history count]);
    #endif
    NSString * aScript = nil;
    if ([history count] > 0) {
        NSString * item = [[history lastObject] objectAtIndex:0];
        if ([delegate respondsToSelector:@selector(shouldReturnItemFromHistory:)]) {
            if ([delegate shouldReturnItemFromHistory:item]) {
                aScript = item;
            }
        } else {
            aScript = item;
        }
    }
    #if (BMSCRIPT_ENABLE_DTRACE)
        BM_PROBE(LAST_SCRIPT_END, (char *) [[aScript quote] UTF8String], (int) [history count]);
    #endif
    return aScript;
}

- (NSString *) lastResultFromHistory {
    #if (BMSCRIPT_ENABLE_DTRACE)
        BM_PROBE(LAST_RESULT_BEGIN, (int) [history count]);
    #endif
    NSString * aResult = nil;
    if ([history count] > 0) {
        NSString * item = [[history lastObject] objectAtIndex:1];
        if ([delegate respondsToSelector:@selector(shouldReturnItemFromHistory:)]) {
            if ([delegate shouldReturnItemFromHistory:item]) {
                aResult = item;
            }
        } else {
            aResult = item;
        }
    }
    #if (BMSCRIPT_ENABLE_DTRACE)
        BM_PROBE(LAST_RESULT_END, (char *) [[aResult quote] UTF8String], (int) [history count]);
    #endif
    return aResult;
}

// MARK: Equality

- (BOOL) isEqualToScript:(BMScript *)other {
    return [script isEqualToString:other.script];
}

- (BOOL) isEqual:(BMScript *)other {
    BOOL sameScript = [script isEqualToString:other.script];
    BOOL sameLaunchPath = [[options objectForKey:BMScriptOptionsTaskLaunchPathKey] 
                           isEqualToString:[other.options objectForKey:BMScriptOptionsTaskLaunchPathKey]];
    return sameScript && sameLaunchPath;
}

// MARK BMScriptDelegate

// - (BOOL) shouldAddItemToHistory:(NSArray *)anItem { 
//     #pragma unused(anItem)
//     return YES; 
// }
// - (BOOL) shouldReturnItemFromHistory:(NSString *)anItem { 
//     #pragma unused(anItem)
//     return YES; 
// }
// - (BOOL) shouldAppendPartialResult:(NSString *)string { 
//     #pragma unused(string)
//     return YES; 
// }
// - (BOOL) shouldSetResult:(NSString *)aString { 
//     #pragma unused(aString)
//     return YES; 
// }
// - (BOOL) shouldSetScript:(NSString *)aScript { 
//     #pragma unused(aScript)
//     return YES; 
// }
// - (BOOL) shouldSetOptions:(NSDictionary *)opts { 
//     #pragma unused(opts)
//     return YES; 
// }
// 
// - (NSString *) willAddItemToHistory:(NSString *)anItem { return anItem; }
// - (NSString *) willReturnItemFromHistory:(NSString *)anItem { return anItem; }
// - (NSString *) willAppendPartialResult:(NSString *)string { return string; }
// - (NSString *) willSetResult:(NSString *)aString { return aString; }
// - (NSString *) willSetScript:(NSString *)aScript { return aScript; }
// - (NSDictionary *) willSetOptions:(NSDictionary *)opts { return opts; }


// MARK: NSCopying

- (id)copyWithZone:(NSZone *)zone {
    #pragma unused(zone)
    return [self retain];
}

// MARK: NSMutableCopying

- (id) mutableCopyWithZone:(NSZone *)zone {
    id copy = [[[self class] allocWithZone:zone] initWithScriptSource:self.script
                                                              options:self.options ];
    return copy;
}

// MARK: NSCoding

- (void) encodeWithCoder:(NSCoder *)coder { 
    [coder encodeObject:script];
    [coder encodeObject:result];
    [coder encodeObject:options];
    [coder encodeObject:history];
    [coder encodeObject:task];
    [coder encodeObject:pipe];
    [coder encodeObject:bgTask];
    [coder encodeObject:bgPipe];
    [coder encodeObject:delegate];
    [coder encodeValueOfObjCType:@encode(BOOL) at:&isTemplate];
    [coder encodeValueOfObjCType:@encode(NSInteger) at:&returnValue];
    [coder encodeValueOfObjCType:@encode(NSInteger) at:&bgTaskReturnValue];
}


- (id) initWithCoder:(NSCoder *)coder { 
    if ((self = [super init])) { 
        //int version = [coder versionForClassName:NSStringFromClass([self class])]; 
        //NSLog(@"class version = %i", version);
        script      = [[coder decodeObject] retain];
        result      = [[coder decodeObject] retain];
        options     = [[coder decodeObject] retain];
        history     = [[coder decodeObject] retain];
        task        = [[coder decodeObject] retain];
        pipe        = [[coder decodeObject] retain];
        bgTask      = [[coder decodeObject] retain];
        bgPipe      = [[coder decodeObject] retain];
        delegate    = [[coder decodeObject] retain];
        [coder decodeValueOfObjCType:@encode(BOOL) at:&isTemplate];
        [coder decodeValueOfObjCType:@encode(NSInteger) at:&returnValue];
        [coder decodeValueOfObjCType:@encode(NSInteger) at:&bgTaskReturnValue];
    }
    return self;
}

- (id) replacementObjectForPortCoder:(NSPortCoder *)encoder {
    if ([encoder isByref])
        return [NSDistantObject proxyWithLocal:self
                                    connection:[encoder connection]];
    else
        return self;
}

@end

@implementation BMScript (CommonScriptLanguagesFactories)

// Ruby

+ (id) rubyScriptWithSource:(NSString *)scriptSource {
    NSDictionary * opts = BMSynthesizeOptions(@"/usr/bin/ruby", @"-Ku", @"-e");
    return [[[self alloc] initWithScriptSource:scriptSource options:opts] autorelease];
}

+ (id) rubyScriptWithContentsOfFile:(NSString *)path {
    NSDictionary * opts = BMSynthesizeOptions(@"/usr/bin/ruby", @"-Ku", @"-e");
    return [[[self alloc] initWithContentsOfFile:path options:opts] autorelease];
}

+ (id) rubyScriptWithContentsOfTemplateFile:(NSString *)path {
	NSDictionary * opts = BMSynthesizeOptions(@"/usr/bin/ruby", @"-Ku", @"-e");
    return [[[self alloc] initWithContentsOfTemplateFile:path options:opts] autorelease];
}

// Python 

+ (id) pythonScriptWithSource:(NSString *)scriptSource {
    NSDictionary * opts = BMSynthesizeOptions(@"/usr/bin/python", @"-c");
    return [[[self alloc] initWithScriptSource:scriptSource options:opts] autorelease];
}

+ (id) pythonScriptWithContentsOfFile:(NSString *)path {
    NSDictionary * opts = BMSynthesizeOptions(@"/usr/bin/python", @"-c");
    return [[[self alloc] initWithContentsOfFile:path options:opts] autorelease];
}

+ (id) pythonScriptWithContentsOfTemplateFile:(NSString *)path {
    NSDictionary * opts = BMSynthesizeOptions(@"/usr/bin/python", @"-c");
    return [[[self alloc] initWithContentsOfTemplateFile:path options:opts] autorelease];
}

// Perl

+ (id) perlScriptWithSource:(NSString *)scriptSource {
	NSDictionary * opts = BMSynthesizeOptions(@"/usr/bin/perl", @"-Mutf8", @"-e");
    return [[[self alloc] initWithScriptSource:scriptSource options:opts] autorelease];
}

+ (id) perlScriptWithContentsOfFile:(NSString *)path {
	NSDictionary * opts = BMSynthesizeOptions(@"/usr/bin/perl", @"-Mutf8", @"-e");
    return [[[self alloc] initWithContentsOfFile:path options:opts] autorelease];
}

+ (id) perlScriptWithContentsOfTemplateFile:(NSString *)path {
	NSDictionary * opts = BMSynthesizeOptions(@"/usr/bin/perl", @"-Mutf8", @"-e");
    return [[[self alloc] initWithContentsOfTemplateFile:path options:opts] autorelease];
}

// Shell 

+ (id) shellScriptWithSource:(NSString *)scriptSource {
	NSDictionary * opts = BMSynthesizeOptions(@"/bin/sh", @"-c");
    return [[[self alloc] initWithScriptSource:scriptSource options:opts] autorelease];
}

+ (id) shellScriptWithContentsOfFile:(NSString *)path {
	NSDictionary * opts = BMSynthesizeOptions(@"/bin/sh", @"-c");
    return [[[self alloc] initWithContentsOfFile:path options:opts] autorelease];
}

+ (id) shellScriptWithContentsOfTemplateFile:(NSString *)path {
	NSDictionary * opts = BMSynthesizeOptions(@"/bin/sh", @"-c");
    return [[[self alloc] initWithContentsOfTemplateFile:path options:opts] autorelease];
}

@end


#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_4
@implementation NSString (BMScriptNSString10_4Compatibility)

- (NSString *)stringByReplacingOccurrencesOfString:(NSString *)target withString:(NSString *)replacement options:(unsigned)opts range:(NSRange)searchRange {
    NSMutableString * str = [NSMutableString stringWithString:self];
    [str replaceOccurrencesOfString:target withString:replacement options:opts range:searchRange];
    return (NSString *)str;
}

- (NSString *)stringByReplacingOccurrencesOfString:(NSString *)target withString:(NSString *)replacement {
    NSRange searchRange = NSMakeRange(0, [self length]);
    NSMutableString * str = [NSMutableString stringWithString:self];
    [str replaceOccurrencesOfString:target withString:replacement options:0 range:searchRange];
    return (NSString *)str;
}

@end
#endif

@implementation NSString (BMScriptStringUtilities)

- (NSString *) quote {
    
    NSString * quotedResult = [self stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
       quotedResult = [quotedResult stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
       quotedResult = [quotedResult stringByReplacingOccurrencesOfString:@"\'" withString:@"\\\'"];
       quotedResult = [quotedResult stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
       quotedResult = [quotedResult stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"];
       quotedResult = [quotedResult stringByReplacingOccurrencesOfString:@"\t" withString:@"\\t"];
       quotedResult = [quotedResult stringByReplacingOccurrencesOfString:@"%"  withString:@"%%"];
    
    return quotedResult;
}

- (NSString *) wrapSingleQuotes { 
    return [NSString stringWithFormat:@"'%@'", self]; 
}

- (NSString *) wrapDoubleQuotes {
    return [NSString stringWithFormat:@"\"%@\"", self]; 
}


- (NSString *) truncate {
    #ifdef BM_NSSTRING_TRUNCATE_LENGTH
        NSUInteger len = BM_NSSTRING_TRUNCATE_LENGTH;
    #else
        NSUInteger len = 20;
    #endif
    if ([self length] < len) {
        return self;
    }
    return [self truncateToLength:len];
}

- (NSString *) truncateToLength:(NSUInteger)len {
    if ([self length] < len) {
        return self;
    }
    return [[self substringWithRange:(NSMakeRange(0, len))] stringByAppendingString:@"..."];
}

- (NSInteger) countOccurrencesOfString:(NSString *)aString {
    NSInteger num = ((NSInteger)[[NSArray arrayWithArray:[self componentsSeparatedByString:aString]] count] - 1);
    if (num > 0) {
        return num;
    }
    return NSNotFound;
}

@end

@implementation NSDictionary (BMScriptUtilities)

- (NSDictionary *) dictionaryByAddingObject:(id)object forKey:(id)key {
    NSArray * keys = [[self allKeys] arrayByAddingObject:key];
    NSArray * values = [[self allValues] arrayByAddingObject:object];
    return [NSDictionary dictionaryWithObjects:values forKeys:keys];
}

@end

@implementation NSObject (BMScriptUtilities)

+ (BOOL) isDescendantOfClass:(Class)anotherClass {
    id instance = [self new];
    BOOL result = [instance isDescendantOfClass:anotherClass];
    [instance release], instance = nil;
    return result;
}

- (BOOL) isDescendantOfClass:(Class)anotherClass {
    return (!([[self class] isEqual:anotherClass]) && [self isKindOfClass:anotherClass]);
}

@end


@implementation NSArray (BMScriptUtilities)

- (BOOL) isEmptyStringArray {
    for (NSString * str in self) {
        if (![str isEqualToString:@""]) {
            return NO;
        }
    }
    return YES;
}

- (BOOL) isZeroArray {
    return [NSStringFromClass([self class]) isEqualToString:@"__NSArray0"];
    
}

@end


///@endcond

