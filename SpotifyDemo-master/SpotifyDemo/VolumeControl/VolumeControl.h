//
//  VolumeControl.h
//  AniTest
//
//  Created by Marko Čančar on 20.10.15..
//  Copyright © 2015. Marko Čančar. All rights reserved.
//

#import <UIKit/UIKit.h>

#define VOLUME_CONTROL_INSET_PERCENT (20.0/100.0)
#define VOLUME_CONTROL_INSET_START_END 30.0
#define VOLUME_CONTROL_LINE_WIDTH 3.0
#define VOLUME_CONTROL_CENTER_OFFSET_PERCENT_Y (36.0/100.0)
#define VOLUME_CONTROL_CENTER_OFFSET_PERCENT_X (16.0/100.0)

#define GRAY_COLOR colorWithRed:(53.0/255.0) green:(53.0/255.0) blue:(58.0/255.0) alpha:1.0
#define BLUE_COLOR colorWithRed:(69.0/255.0) green:(190.0/255.0) blue:(252.0/255.0) alpha:1.0
#define NAVY_COLOR colorWithRed:(18.0/255.0) green:(51.0/255.0) blue:(89.0/255.0) alpha: 1.0
#define TEAL_COLOR colorWithRed:(130.0/255.0) green:(209.0/255.0) blue:(209.0/255.0) alpha:1.0
#define BLACK_COLOR colorWithRed:(0.0) green:(0.0) blue:(0.0) alpha:0.75


@protocol VolumeControlDelegate <NSObject>

@required
/* Implement this method to notify your delegate when someone change volume value on VolumeControl.*/
- (void)didChangeVolume:(CGFloat)volume;
@optional
/* Implement this method to notify your delegate when VolumeControl is hidden.
   NOTE: This method will send just YES - will notify you just when your VolumeControle is hidden.
   You can use it for animating superview of your VolumeControl.
 */
- (void)viewIsHidden: (BOOL) ishidden;

@end


@interface VolumeControl : UIView

@property (nonatomic, weak) id <VolumeControlDelegate> volumeDelegate;


/*!
 * @brief The only way to create VolumeControl view.
 * @param center A point specifying from where VolumeControl opens.
 * @param radius A number specifying the size of a VolumeControl.
 * @return The VolumeControl view.
 */
- (instancetype)initWithCenter:(CGPoint)center withRadius:(CGFloat)radius withVolume:(CGFloat)volume withVolumeControlDelegate:(id <VolumeControlDelegate>)delegate;

/*!
 * @brief The view’s color.
 */
- (void)setColor:(UIColor *)color;

/*!
 * @brief The volume percent. From 0.0 to 1.0
 */
- (void)setVolume:(CGFloat)volume;


/*!
 * @brief The volume percent. From 0.0 to 1.0
 */
- (void)volumeChanged:(CGFloat)volume;

@end
