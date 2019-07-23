//
//  ViewController.m
//  Location
//
//  Created by Alexander Wang on 2018/2/3.
//  Copyright © 2018年 Alexander Wang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ViewController.h"
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

@interface ViewController ()<CLLocationManagerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *licationLabel;
@property (weak, nonatomic) IBOutlet UILabel *detailLocationLabel;
@property(nonatomic,strong) CLLocationManager *locationManager;//获取经纬度
@property(nonatomic,copy) NSString *Longitude;//经度
@property(nonatomic,copy) NSString *Latitude;//纬度
@property(nonatomic, copy) NSString *cityCode;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self startLocation];
}

- (void)startLocation{
    //初始化定位管理器
    _locationManager= [[CLLocationManager alloc] init];
    //设置代理
    _locationManager.delegate=self;
    //设置定位精确度到米
    _locationManager.desiredAccuracy=kCLLocationAccuracyBest;
    //设置过滤器为无
    _locationManager.distanceFilter=kCLDistanceFilterNone;
    //开始定位
    if (@available(iOS 9.0, *)) {
        [_locationManager requestAlwaysAuthorization];
    }
    if (@available(iOS 9.0, *)) {
        _locationManager.allowsBackgroundLocationUpdates = YES;
    }
    [_locationManager startUpdatingLocation];
}
#pragma mark CLLocationManagerDelegate<br>/**<br>* 获取经纬度<br>*/
- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation {
    
    [_locationManager stopUpdatingLocation];
    NSLog(@"定位成功...");
    NSLog(@"%@",[NSString stringWithFormat:@"经度:%3.5f\n纬度:%3.5f",newLocation.coordinate.latitude,newLocation.coordinate.longitude]);
    
    CLGeocoder* geoCoder = [[CLGeocoder alloc] init];
    
    //根据经纬度反向地理编译出地址信息
    [geoCoder reverseGeocodeLocation:newLocation completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        if(placemarks.count>0) {
            CLPlacemark *placemark = [placemarks objectAtIndex:0];
            self.licationLabel.text = placemark.locality;
            self.detailLocationLabel.text = [NSString stringWithFormat:@"%@%@%@%@", placemark.locality,placemark.subLocality,placemark.thoroughfare,placemark.subThoroughfare];
        }
    }];
    //系统会一直更新数据，直到选择停止更新，因为我们只需要获得一次经纬度即可，所以获取之后就停止更新
    [manager stopUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    [manager stopUpdatingLocation];
    switch([error code]) {
        case kCLErrorDenied:
            [self openGPSTips];
            break;
        case kCLErrorLocationUnknown:
            break;
        default:
            break;
    }
}

-(void)openGPSTips{
    UIAlertView *alet = [[UIAlertView alloc] initWithTitle:@"当前定位服务不可用" message:@"请到“设置->隐私->定位服务”中开启定位" delegate:self cancelButtonTitle:nil otherButtonTitles:@"确定", nil];
    [alet show];
}


@end
