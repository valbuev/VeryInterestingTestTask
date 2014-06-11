//
//  PhotoDownloader.m
//  VeryInterestingTestTask
//
//  Created by Valeriy Buev on 28.05.14.
//  Copyright (c) 2014 bva. All rights reserved.
//

#define DOCUMENTS [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]

#import "PhotoDownloader.h"

@implementation PhotoDownloader

- (void) startDownloadFromURL: (NSString *) _url_str withManagedObject: (NSObject *) object{
    //NSLog(@"start downloading");
    url_str = _url_str;
    managedObject = object;
    
    NSString *prefixString = @"Photo";
    NSString *guid = [[NSProcessInfo processInfo] globallyUniqueString] ;
    filePath = [DOCUMENTS stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_%@", prefixString, guid]];
    
    [self.delegate setNetworkIndicatorVisible:YES];
    NSURL *url = [NSURL URLWithString:
                  [url_str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
    NSURLRequest *theRequest=[NSURLRequest requestWithURL:url
                                              cachePolicy:NSURLRequestUseProtocolCachePolicy
                                          timeoutInterval:10.0];
    
    theConnection = [NSURLConnection connectionWithRequest:theRequest delegate:self];
    if(theConnection){
        [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
        file = [NSFileHandle fileHandleForUpdatingAtPath:filePath];
    }
    else{
        [self.delegate setNetworkIndicatorVisible:NO];
    }
    NSLog(@"start downloading");
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    //[self.Data appendData:data];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [self.delegate setNetworkIndicatorVisible:NO];
        if([data length] > 0){
            @try
            {
                [file seekToEndOfFile];
                [file writeData:data];
                [file closeFile];
            }
            @catch (NSException * e)
            {
                NSLog(@"exception when writing to file %@ \n Exception: %@", filePath,e);
                [file closeFile];
                return;
            }
            [self.delegate PhotoDownloaderDidFinishedDownload:filePath forObject:managedObject];
        }
        else{
            [file closeFile];
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSError *file_error;
            BOOL success = [fileManager removeItemAtPath:filePath error:&file_error];
            if (!success)
            {
                NSLog(@"Could not delete file -:%@ ",[file_error localizedDescription]);
            }
        }
    });
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSLog(@"connectionDidFinishLoading");
    //[file closeFile];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [file closeFile];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *file_error;
    BOOL success = [fileManager removeItemAtPath:filePath error:&file_error];
    if (!success)
    {
        NSLog(@"Could not delete file -:%@ ",[file_error localizedDescription]);
    }
    NSLog(@"connection didFailWithError: \n %@", error);
    [self.delegate setNetworkIndicatorVisible:NO];

}



- (void)connection: (NSURLConnection*) connection didReceiveResponse: (NSHTTPURLResponse*) response
{
    NSNumber* filesize;
    if ([response expectedContentLength] == NSURLResponseUnknownLength) {
        // unknown content size
        [connection cancel];
        filesize = @0;
        NSLog(@"didReceiveResponse NSURLResponseUnknownLength");
    }
    else {
        filesize = [NSNumber numberWithLongLong:[response expectedContentLength]];
        if([filesize compare:[NSNumber numberWithInt:5000000]]==NSOrderedDescending){
            NSLog(@"cancel because too much %@",filesize);
            [connection cancel];
        }
    }
}

@end
