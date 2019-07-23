//
//  ApplicationLocationData.m
//  Location
//
//  Created by Alexander Wang on 2018/2/3.
//  Copyright © 2018年 Alexander Wang. All rights reserved.
//

#import "ApplicationLocationData.h"
#import <CoreLocation/CoreLocation.h>

@implementation LocationDataInfo

- (instancetype)initWithCLLocation:(CLLocation *)location placeMarker:(CLPlacemark *)marker {
    self = [super init];
    self.lat = location.coordinate.latitude;
    self.lng = location.coordinate.longitude;
    
    if (marker && marker.addressDictionary) {
        NSDictionary *addrDic = marker.addressDictionary;
        self.state = [addrDic objectForKey:@"State"];
        self.city = marker.locality;
        
        NSArray *addressArray = [addrDic objectForKey:@"FormattedAddressLines"];
        if (addressArray && addressArray.count > 0)
            self.address = [addressArray firstObject];
        
        self.subLocality = [addrDic objectForKey:@"SubLocality"];
        self.updateTime = [NSDate date];
    }
    return self;
}

- (NSString *)latLngString {
    return [NSString stringWithFormat:@"%f,%f", self.lat, self.lng];
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:[NSNumber numberWithDouble:self.lat] forKey:@"lat"];
    [aCoder encodeObject:[NSNumber numberWithDouble:self.lat] forKey:@"lng"];
    [aCoder encodeObject:self.state forKey:@"state"];
    [aCoder encodeObject:self.city forKey:@"city"];
    [aCoder encodeObject:self.subLocality forKey:@"subLocality"];
    [aCoder encodeObject:self.address forKey:@"address"];
    [aCoder encodeObject:self.updateTime forKey:@"updateTime"];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    NSNumber *tmpNumber = [aDecoder decodeObjectForKey:@"lat"];
    if (tmpNumber)
        self.lat = tmpNumber.doubleValue;
    tmpNumber = [aDecoder decodeObjectForKey:@"lng"];
    if (tmpNumber)
        self.lng = tmpNumber.doubleValue;
    
    self.state = [aDecoder decodeObjectForKey:@"state"];
    self.city = [aDecoder decodeObjectForKey:@"city"];
    self.subLocality = [aDecoder decodeObjectForKey:@"subLocality"];
    self.address = [aDecoder decodeObjectForKey:@"address"];
    self.updateTime = [aDecoder decodeObjectForKey:@"updateTime"];
    return self;
}

@end

@interface ApplicationLocationData()<CLLocationManagerDelegate>
{
    NSUserDefaults *_userDefaults;
    LocationDataInfo *_location;
}
@property(nonatomic, assign) BOOL locationSearching;
@property(nonatomic, retain) CLLocationManager *locationManager;
@property(nonatomic, strong) CLGeocoder *geocoder;
@end

NSString *kHPLocationSearchFaild = @"kLocationSearchFaild";
NSString *kHPLocationFaildDomain = @"newawera.locationErr";
NSString *kHPLocationDisable = @"newawera.locationDisable";

@implementation ApplicationLocationData

- (CLLocationManager *)locationManager {
    if (!_locationManager)
    {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        [_locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
        [_locationManager setDistanceFilter:1000.0f];
        self.locationSearching = NO;
    }
    return _locationManager;
}

- (void)setLocation:(LocationDataInfo *)location
{
//
//    if (_location && _location.address.length) {
//        return;
//    }
    _location = location;
    if (_location)
    {
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:_location];
        [_userDefaults setObject:data forKey:@"location"];
    }
    else
        [_userDefaults removeObjectForKey:@"location"];
    
    [_userDefaults synchronize];
}

- (LocationDataInfo *)location
{
    if (!_location)
    {
        NSData *data = [_userDefaults objectForKey:@"location"];
        if (data)
            _location = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
    return _location;
}

- (void)clearLocationInfo { self.location = nil; }

- (BOOL)startUpdateLocation
{
    //Check location service is enabled
//    if (![CLLocationManager locationServicesEnabled]) {
//        [[NSNotificationCenter defaultCenter] postNotificationName:kHPLocationSearchFaild object:[NSError errorWithDomain:kHPLocationDisable code:1 userInfo:@{@"message":@"locationServiceEnabledError"}]];
//        return NO;
//    }
//
//    if (self.locationSearching)
//        return NO;
    self.locationSearching = YES;

    [self.locationManager requestAlwaysAuthorization];
    
    [self.locationManager startUpdatingLocation];
    return YES;
}

- (void)startUpdateLocationWithTimeOut:(NSTimeInterval)seconds {
//    if ([self startUpdateLocation]) {
    self.locationSearching = YES;
    
    [self.locationManager requestAlwaysAuthorization];
    
    [self.locationManager startUpdatingLocation];
        locationSearchTimeout = seconds;
        if (locationServiceSearchTimer) {
            [locationServiceSearchTimer invalidate];
            locationServiceSearchTimer = nil;
        }
        locationServiceSearchTimer = [NSTimer scheduledTimerWithTimeInterval:locationSearchTimeout
                                                                      target:self
                                                                    selector:@selector(locationSearchTimeoutHandler)
                                                                    userInfo:nil
                                                                     repeats:NO];
//    }
}

- (void)locationSearchTimeoutHandler
{
    if (self.locationSearching)
    {
        [self cancelUpdateLocation];
        NSError *error = [[NSError alloc] initWithDomain:kHPLocationFaildDomain
                                                    code:0
                                                userInfo:@{@"message":@"requestLocationTimeOut",
                                                           @"timeInterval":[NSNumber numberWithDouble:locationSearchTimeout]}];
        [[NSNotificationCenter defaultCenter] postNotificationName:kHPLocationSearchFaild object:error];
    }
}

- (void)cancelUpdateLocation
{
    self.locationSearching = NO;
    [self.locationManager stopUpdatingLocation];
    if (locationServiceSearchTimer) {
        [locationServiceSearchTimer invalidate];
        locationServiceSearchTimer = nil;
    }
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status == kCLAuthorizationStatusNotDetermined && [self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)])
        [self.locationManager requestAlwaysAuthorization];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"---- location manage did fail with error:%@", error);
    [[NSNotificationCenter defaultCenter] postNotificationName:kHPLocationSearchFaild object:error];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    [self cancelUpdateLocation];
    CLLocation *location = [locations objectAtIndex:0];
    if(self.geocoder.geocoding) { [self.geocoder cancelGeocode]; }
    if (location) {
        [self.geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *array, NSError *error) {
            if ( array.count > 0 ) {
                CLPlacemark *placemark = [array objectAtIndex:0];
                [self setValue:[[LocationDataInfo alloc] initWithCLLocation:location placeMarker:placemark] forKey:@"location"];
            } else {
                [self setValue:[[LocationDataInfo alloc] initWithCLLocation:location placeMarker:nil] forKey:@"location"];
            }
        }];
    } else {
        NSError *error = [[NSError alloc] initWithDomain:kHPLocationFaildDomain code:1 userInfo:@{@"message":@"locationError"}];
        [[NSNotificationCenter defaultCenter] postNotificationName:kHPLocationSearchFaild object:error];
    }
}



@end
