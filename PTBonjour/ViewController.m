//
//  ViewController.m
//  PTBonjour
//
//  Created by Jay Baker on 7/10/15.
//  Copyright © 2015 Jay Baker. All rights reserved.
//

#import "ViewController.h"
#import "arpa/inet.h"

@interface ViewController ()

@end

@implementation ViewController
const NSString *service = @"_YOUR-SERVICE-NAME._PROTOCOL";

void resolveCallback (
                        CFNetServiceRef theService,
                        CFStreamError* error,
                        void* info)
{
    
    struct sockaddr_in *addr;
    CFArrayRef _addresses = CFNetServiceGetAddressing(theService);
    for(int i=0; i<CFArrayGetCount(_addresses); i++) {
        addr = (struct sockaddr_in *) CFDataGetBytePtr(CFArrayGetValueAtIndex(_addresses, i));
        NSLog(@"name : %@\nip : %s\nport : %d\n", CFNetServiceGetName(theService), inet_ntoa(addr->sin_addr), ntohs(addr->sin_port));
    }
}

static void ResolveService(CFStringRef name, CFStringRef type, CFStringRef domain)
{
    CFNetServiceClientContext context = { 0, NULL, NULL, NULL, NULL };
    CFTimeInterval duration = 0; // use infinite timeout
    CFStreamError error;
    
    CFNetServiceRef gServiceBeingResolved = CFNetServiceCreate(kCFAllocatorDefault, domain, type, name, 0);
    assert(gServiceBeingResolved != NULL);
    
    CFNetServiceSetClient(gServiceBeingResolved, resolveCallback, &context);
    CFNetServiceScheduleWithRunLoop(gServiceBeingResolved, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
    
    if (CFNetServiceResolveWithTimeout(gServiceBeingResolved, duration, &error) == false) {
        
        // Something went wrong, so let's clean up.
        CFNetServiceUnscheduleFromRunLoop(gServiceBeingResolved, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
        CFNetServiceSetClient(gServiceBeingResolved, NULL, NULL);
        CFRelease(gServiceBeingResolved);
        gServiceBeingResolved = NULL;
        
        fprintf(stderr, "CFNetServiceResolve returned (domain = %ld, error = %d)\n", (long)error.domain, error.error);
    }
    
    return;
}


void browseCallBack (CFNetServiceBrowserRef browser, CFOptionFlags flags, CFTypeRef domainOrService, CFStreamError *err, void *info)
{
    // check the type we found
    if ((err->error) != 0)
    {
        NSLog(@"error: %d\n", (int)err->error);
    }
    else if ((flags & kCFNetServiceFlagIsDomain) != 0)
    {
        NSLog(@"domain !\n");
    }
    else if ((flags & kCFNetServiceFlagRemove) == 0) {
        CFNetServiceRef service = (CFNetServiceRef)domainOrService;
        CFStringRef name = CFNetServiceGetName(service);
        CFStringRef type = CFNetServiceGetType(service);
        CFStringRef domain = CFNetServiceGetDomain(service);
        
        ResolveService(name, type, domain);
    }
    else {
        NSLog(@"Service lost");
    }
}

static Boolean StartBrowsingForServices(CFStringRef type, CFStringRef domain) {
    CFNetServiceClientContext clientContext = { 0, NULL, NULL, NULL, NULL };
    CFStreamError error;
    Boolean result;
    
    assert(type != NULL);
    
    CFNetServiceBrowserRef gServiceBrowserRef = CFNetServiceBrowserCreate(kCFAllocatorDefault, browseCallBack, &clientContext);
    assert(gServiceBrowserRef != NULL);
    
    CFNetServiceBrowserScheduleWithRunLoop(gServiceBrowserRef, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
    
    result = CFNetServiceBrowserSearchForServices(gServiceBrowserRef, domain, type, &error);
    
    if (result == false) {
        
        // Something went wrong, so let's clean up.
        CFNetServiceBrowserUnscheduleFromRunLoop(gServiceBrowserRef, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
        CFRelease(gServiceBrowserRef);
        gServiceBrowserRef = NULL;
        
        fprintf(stderr, "CFNetServiceBrowserSearchForServices returned (domain = %ld, error = %d)\n", (long)error.domain, error.error);
    }
    
    return result;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    CFStringRef type = (__bridge CFStringRef)service;
    CFStringRef domain = (__bridge CFStringRef)@"";
    
    StartBrowsingForServices(type, domain);
    
    //ResolveService(name, type, domain);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
