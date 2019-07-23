//
//  ApplicationLocationData.h
//  Location
//
//  Created by Alexander Wang on 2018/2/3.
//  Copyright © 2018年 Alexander Wang. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, DegradationTrade){
    DegradationTradeUnsuport = 0,
    DegradationTradeSuport = 1
};

@interface LocationDataInfo : NSObject<NSCoding>
@property(nonatomic) double lat;
@property(nonatomic) double lng;
@property(nonatomic, readonly) NSString *latLngString;

@property(nonatomic, strong) NSDate *updateTime;
@property(nonatomic, strong) NSString *state;
@property(nonatomic, strong) NSString *subLocality;
@property(nonatomic, strong) NSString *city;
@property(nonatomic, strong) NSString *address;
@end

extern NSString *kHPLocationSearchFaild;
extern NSString *kHPLocationFaildDomain;
extern NSString *kHPLocationDisable;

@interface ApplicationLocationData : NSObject
{
    NSTimer  *locationServiceSearchTimer;
    NSTimeInterval locationSearchTimeout;
}
@property(nonatomic) LocationDataInfo *location;
- (BOOL)startUpdateLocation;
- (void)startUpdateLocationWithTimeOut:(NSTimeInterval)seconds;
- (void)cancelUpdateLocation;
- (void)clearLocationInfo;
@end

