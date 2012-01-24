//
//  RZGridViewCell.m
//  RZGridView
//
//  Created by Joe Goullaud on 10/3/11.
//  Copyright 2011 Raizlabs. All rights reserved.
//

#import "RZGridViewCell.h"


@interface RZGridViewCell ()

@property (assign, nonatomic) RZGridViewCellStyle style;
@property (copy, readwrite, nonatomic) NSString *reuseIdentifier;

@property (retain, readwrite, nonatomic) UIImageView *imageView;
@property (retain, readwrite, nonatomic) UIView *contentView;
@property (retain, readwrite, nonatomic) UILabel *titleLabel;

- (void)configureCellForStyle:(RZGridViewCellStyle)style;

@end

@implementation RZGridViewCell

@synthesize style = _style;
@synthesize reuseIdentifier = _reuseIdentifier;

@synthesize imageView = _imageView;
@synthesize contentView = _contentView;
@synthesize titleLabel = _titleLabel;

- (id)initWithStyle:(RZGridViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if ((self = [super initWithFrame:CGRectMake(0, 0, 200, 200)]))
    {
        self.style = style;
        self.reuseIdentifier = reuseIdentifier;
        
        self.contentMode = UIViewContentModeScaleAspectFit;
        
        [self configureCellForStyle:style];
        
    }
    
    return self;
}

- (void)awakeFromNib
{
    self.style = RZGridViewCellStyleCustom;
}

- (void)dealloc
{
    [_reuseIdentifier release];
    
    [_imageView release];
    [_contentView release];
    [_titleLabel release];
    
    [super dealloc];
}

- (void)prepareForReuse
{
    [self configureCellForStyle:self.style];
}

- (void)configureCellForStyle:(RZGridViewCellStyle)style
{
    if (style == RZGridViewCellStyleDefault)
    {
        if (!self.contentView)
        {
            self.contentView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)] autorelease];
        }
        else
        {
            [[self.contentView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
        }
        
        if (!self.imageView)
        {
            self.imageView = [[[UIImageView alloc] initWithFrame:CGRectMake(5, 30, 190, 165)] autorelease];
        }
        else
        {
            [[self.imageView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
        }
        
        if (!self.titleLabel)
        {
            self.titleLabel = [[[UILabel alloc] initWithFrame:CGRectMake(5, 3, 190, 25)] autorelease];
        }
        else
        {
            [[self.titleLabel subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
        }
        
        self.contentView.frame = CGRectMake(0, 0, 200, 200);
        self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.contentView.contentMode = UIViewContentModeScaleToFill;
        self.contentView.backgroundColor = [UIColor clearColor];
        [self addSubview:self.contentView];
        
        self.imageView.image = nil;
        self.imageView.frame = CGRectMake(5, 30, 190, 165);
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        self.imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight  | UIViewAutoresizingFlexibleTopMargin;
        self.imageView.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:self.imageView];
        
        self.titleLabel.text = nil;
        self.titleLabel.frame = CGRectMake(5, 3, 190, 25);
        self.titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
        self.titleLabel.textAlignment = UITextAlignmentCenter;
        self.titleLabel.contentMode = UIViewContentModeCenter;
        self.titleLabel.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:self.titleLabel];
    }
}

@end
