//
//  RZGridViewCell.h
//  RZGridView
//
//  Created by Joe Goullaud on 10/3/11.
//  Copyright 2011 Raizlabs. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    RZGridViewCellStyleDefault,
    RZGridViewCellStyleCustom
} RZGridViewCellStyle;

@interface RZGridViewCell : UIView {
    
}

@property (copy, nonatomic) NSString *reuseIdentifier;

@property (retain, readonly, nonatomic) UIImageView *imageView;
@property (retain, readonly, nonatomic) UIView *contentView;
@property (retain, readonly, nonatomic) UILabel *titleLabel;

- (id)initWithStyle:(RZGridViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier;

- (void)prepareForReuse;

@end
