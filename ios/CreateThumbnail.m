#import "CreateThumbnail.h"

@interface ImageUtilities : NSObject
+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)size;
+ (UIImage *)imageWithImage:(UIImage *)image scaledToMaxWidth:(CGFloat)width maxHeight:(CGFloat)height;
@end

@implementation ImageUtilities

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)size {
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        UIGraphicsBeginImageContextWithOptions(size, NO, [[UIScreen mainScreen] scale]);
    } else {
        UIGraphicsBeginImageContext(size);
    }
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();    
    UIGraphicsEndImageContext();

    return newImage;
}

+ (UIImage *)imageWithImage:(UIImage *)image scaledToMaxWidth:(CGFloat)width maxHeight:(CGFloat)height {
    CGFloat oldWidth = image.size.width;
    CGFloat oldHeight = image.size.height;

    CGFloat scaleFactor = (oldWidth > oldHeight) ? width / oldWidth : height / oldHeight;

    CGFloat newHeight = oldHeight * scaleFactor;
    CGFloat newWidth = oldWidth * scaleFactor;
    CGSize newSize = CGSizeMake(newWidth, newHeight);

    return [ImageUtilities imageWithImage:image scaledToSize:newSize];
}

@end


@implementation CreateThumbnail

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(create:(NSDictionary *)config findEventsWithResolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
    NSString *url = (NSString *)[config objectForKey:@"url"] ?: @"";
     int timeStamp = [[config objectForKey:@"timeStamp"] intValue] ?: 0;
    NSString *type = (NSString *)[config objectForKey:@"type"] ?: @"remote";
    NSString *format = (NSString *)[config objectForKey:@"format"] ?: @"jpeg";
    int quality = [[config objectForKey:@"quality"] intValue] ?: 100;
    int maxWidth = [[config objectForKey:@"maxWidth"] intValue] ?: 0;
    int maxHeight = [[config objectForKey:@"maxHeight"] intValue] ?: 0;
    int tolerance = [[config objectForKey:@"tolerance"] intValue] ?: 1;
    unsigned long long CTMaxDirSize = [[config objectForKey:@"maxDirsize"] longLongValue] ?: 26214400; // 25mb
    
    @try {
        NSURL *vidURL = nil;
        if ([type isEqual: @"local"]) {
            url = [url stringByReplacingOccurrencesOfString:@"file://" withString:@""];
            vidURL = [NSURL fileURLWithPath:url];
        } else {
            vidURL = [NSURL URLWithString:url];
        }

        AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:vidURL options:nil];
        AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
        generator.appliesPreferredTrackTransform = YES;
		generator.requestedTimeToleranceBefore = CMTimeMake(tolerance, 1000);
		generator.requestedTimeToleranceAfter = generator.requestedTimeToleranceBefore;

		NSError *err = NULL;
        CMTime time = CMTimeMake(timeStamp, 1000);
        CMTime actTime = CMTimeMake(0, 0);

        CGImageRef imgRef = [generator copyCGImageAtTime:time actualTime:&actTime error:&err];
        UIImage *thumbnail = [UIImage imageWithCGImage:imgRef];
		// Resize image
		if (maxWidth > 0 && maxHeight > 0) {
			thumbnail = [ImageUtilities imageWithImage:thumbnail scaledToMaxWidth:maxWidth maxHeight:maxHeight];
		}

        // Save to temp directory
        NSString* tempDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        tempDirectory = [tempDirectory stringByAppendingString:@"/thumbnails/"];
        // Create thumbnail directory if not exists
        [[NSFileManager defaultManager] createDirectoryAtPath:tempDirectory withIntermediateDirectories:YES attributes:nil error:&err];
        // Clean directory
        unsigned long long size = [self sizeOfFolderAtPath:tempDirectory];
        if (size >= CTMaxDirSize) {
            [self cleanDir:tempDirectory forSpace:CTMaxDirSize / 2];
        }
        
        // Generate thumbnail
        NSData *data = nil;
        NSString *fullPath = nil;
        if ([format isEqual: @"png"]) {
            data = UIImagePNGRepresentation(thumbnail);
            fullPath = [tempDirectory stringByAppendingPathComponent: [NSString stringWithFormat:@"thumb-%@.png",[[NSProcessInfo processInfo] globallyUniqueString]]];
        } else {
            data = UIImageJPEGRepresentation(thumbnail, quality * 0.01);
            fullPath = [tempDirectory stringByAppendingPathComponent: [NSString stringWithFormat:@"thumb-%@.jpeg",[[NSProcessInfo processInfo] globallyUniqueString]]];
        }

        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager createFileAtPath:fullPath contents:data attributes:nil];
        CGImageRelease(imgRef);
        resolve(@{
            @"path"     : fullPath,
			@"width"    : [NSNumber numberWithFloat: thumbnail.size.width],
            @"height"   : [NSNumber numberWithFloat: thumbnail.size.height]
        });
    } @catch(NSException *e) {
        reject(e.reason, nil, nil);
    }
}

- (unsigned long long) sizeOfFolderAtPath:(NSString *)path {
    NSArray *files = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:path error:nil];
    NSEnumerator *enumerator = [files objectEnumerator];
    NSString *fileName;
    unsigned long long size = 0;
    while (fileName = [enumerator nextObject]) {
        size += [[[NSFileManager defaultManager] attributesOfItemAtPath:[path stringByAppendingPathComponent:fileName] error:nil] fileSize];
    }
    return size;
}

- (void) cleanDir:(NSString *)path forSpace:(unsigned long long)size {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error = nil;
    unsigned long long deletedSize = 0;
    for (NSString *file in [fm contentsOfDirectoryAtPath:path error:&error]) {
        unsigned long long fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:[path stringByAppendingPathComponent:file] error:nil] fileSize];
        BOOL success = [fm removeItemAtPath:[NSString stringWithFormat:@"%@%@", path, file] error:&error];
        if (success) {
            deletedSize += fileSize;
        }
        if (deletedSize >= size) {
            break;
        }
    }
    return;
}

RCT_EXPORT_METHOD(trim:(NSDictionary *)config findEventsWithResolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
	NSString *url = (NSString *)[config objectForKey:@"url"] ?: @"";
	int msStart = [[config objectForKey:@"start"] intValue] ?: 0;
	int msEnd = [[config objectForKey:@"end"] intValue] ?: 1;
    unsigned long long CTMaxDirSize = [[config objectForKey:@"maxDirsize"] longLongValue] ?: 26214400; // 25mb

    @try {
        NSURL *vidURL = nil;
		url = [url stringByReplacingOccurrencesOfString:@"file://" withString:@""];
		vidURL = [NSURL fileURLWithPath:url];

        NSString *fullPath = nil;
        NSString* tempDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        tempDirectory = [tempDirectory stringByAppendingString:@"/trimmed/"];
		fullPath = [tempDirectory stringByAppendingPathComponent: [NSString stringWithFormat:@"video-%@.png",[[NSProcessInfo processInfo] globallyUniqueString]]];

        AVURLAsset *anAsset = [[AVURLAsset alloc] initWithURL:vidURL options:nil];
		NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:anAsset];
		if ([compatiblePresets containsObject:AVAssetExportPresetLowQuality]) {
		    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc]
    	    initWithAsset:anAsset presetName:AVAssetExportPresetLowQuality];

    		// Implementation continues.
		    exportSession.outputURL = fullPath;
			exportSession.outputFileType = AVFileTypeQuickTimeMovie;
		
			CMTime start = CMTimeMakeWithSeconds(msStart, 1000);
			CMTime duration = CMTimeMakeWithSeconds(msEnd, 1000);
			CMTimeRange range = CMTimeRangeMake(start, duration);
			exportSession.timeRange = range;

			// [exportSession exportAsynchronouslyWithCompletionHandler:^{
		
			// 	switch ([exportSession status]) {
			// 		case AVAssetExportSessionStatusFailed:
			// 			NSLog(@"Export failed: %@", [[exportSession error] localizedDescription]);
			// 			break;
			// 		case AVAssetExportSessionStatusCancelled:
			// 			NSLog(@"Export canceled");
			// 			break;
			// 		default:
			// 			break;
			// 	}
			// }];
		}

        resolve(@{
            @"path"     : fullPath,
        });

    } @catch(NSException *e) {
        reject(e.reason, nil, nil);
    }
}

@end
