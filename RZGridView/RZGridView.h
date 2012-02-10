//
//  RZGridView.h
//  RZGridView
//
//  Created by Joe Goullaud on 10/3/11.
//  Copyright 2011 Raizlabs. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "RZGridViewCell.h"

@protocol RZGridViewDelegate;
@protocol RZGridViewDataSource;

// Constants for Section Arrangement
typedef enum {
    RZGridViewSectionArrangementVertical,
    RZGridViewSectionArrangementHorizontal
} RZGridViewSectionArrangement;

@interface RZGridView : UIView <UIScrollViewDelegate, UIGestureRecognizerDelegate> {
    @private
    id<RZGridViewDataSource> _dataSource;
    id<RZGridViewDelegate> _delegate;
    CGFloat _rowHeight;
    
    NSMutableArray *_visibleCells;
    
    UIScrollView *_scrollView;
    NSMutableArray *_sectionRanges;
    NSMutableArray *_rowRangesBySection;
    
    NSUInteger _totalItems;
    NSUInteger _totalRows;
    NSUInteger _totalSections;
    
    struct {
        unsigned int dataSourceNumberOfItemsInSection:1;
        unsigned int dataSourceNumberOfRowsInSection:1;
        unsigned int dataSourceNumberOfColumnsInRow:1;
        unsigned int dataSourceCellForItemAtIndexPath:1;
        unsigned int dataSourceNumberOfSectionsInGridView:1;
        unsigned int dataSourceTitleForHeaderInSection:1;
        unsigned int dataSourceTitleForFooterInSection:1;
        unsigned int dataSourceMoveItemAtIndexPathToIndexPath:1;
        unsigned int delegateDidSelectItemAtIndexPath:1;
        unsigned int delegateHeightForRowAtIndexPath:1;
        unsigned int delegateWidthForColumnAtIndexPath:1;
        unsigned int delegateSectionArrangementForGridView:1;
    } _gridFlags;
}

@property (nonatomic, assign) UIEdgeInsets contentInset;

@property (nonatomic, assign) IBOutlet id<RZGridViewDataSource> dataSource;
@property (nonatomic, assign) IBOutlet id<RZGridViewDelegate> delegate;

@property (nonatomic, assign) NSTimeInterval reorderLongPressDelay;             // defaults to 0.5

@property (retain, readonly) RZGridViewCell *selectedCell;
@property (nonatomic, assign) RZGridViewSectionArrangement sectionArrangement;  // defaults to RZGridViewSectionArrangementVertical
@property (nonatomic, getter=isPagingEnabled) BOOL pagingEnabled;
@property (nonatomic) CGPoint contentOffset;

- (void)reloadData;

- (NSInteger)numberOfSections;
- (NSInteger)numberOfRowsInSection:(NSInteger)section;

- (CGRect)rectForSection:(NSInteger)section;                                    // includes header, footer and all rows
- (CGRect)rectForHeaderInSection:(NSInteger)section;
- (CGRect)rectForFooterInSection:(NSInteger)section;
- (CGRect)rectForRow:(NSInteger)row inSection:(NSInteger)section;
- (CGRect)rectForItemAtIndexPath:(NSIndexPath *)indexPath;

- (NSIndexPath*)indexPathForItemAtPoint:(CGPoint)point;                         // Returns nil if outside grid view
- (NSIndexPath*)indexPathForCell:(RZGridViewCell*)cell;                         // Returns nil if cell is not visible

- (RZGridViewCell*)cellForItemAtIndexPath:(NSIndexPath *)indexPath;              // returns nil if cell is not visible or index path is out of range
- (NSArray *)visibleCells;
- (NSArray *)indexPathsForVisibleItems;

- (RZGridViewCell*)dequeueReusableCellWithIdentifier:(NSString*)cellIdentifier;

@end

// Grid View Data Source Protocol
@protocol RZGridViewDataSource <NSObject>

@required

- (NSInteger)gridView:(RZGridView*)gridView numberOfItemsInSection:(NSInteger)section;
- (NSInteger)gridView:(RZGridView*)gridView numberOfRowsInSection:(NSInteger)section;
- (NSInteger)gridView:(RZGridView*)gridView numberOfColumnsInRow:(NSInteger)row inSection:(NSInteger)section;

- (RZGridViewCell*)gridView:(RZGridView*)gridView cellForItemAtIndexPath:(NSIndexPath*)indexPath;

@optional

- (NSInteger)numberOfSectionsInGridView:(RZGridView*)gridView;                  // Default is 1 if not implemented

- (NSString *)gridView:(RZGridView*)gridView titleForHeaderInSection:(NSInteger)section;    
- (NSString *)gridView:(RZGridView*)gridView titleForFooterInSection:(NSInteger)section;

// Data manipulation - reorder / moving support

- (void)gridView:(RZGridView*)gridView moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath;

@end

// Constants for Auto-sizing of row height and column width
#define RZGRIDVIEW_AUTO_HEIGHT CGFLOAT_MAX
#define RZGRIDVIEW_AUTO_WIDTH  CGFLOAT_MAX

#define RZGRIDVIEW_DEFAULT_HEIGHT 200.0
#define RZGRIDVIEW_DEFAULT_WIDTH  RZGRIDVIEW_AUTO_WIDTH

// Grid View Delegate Protocol
@protocol RZGridViewDelegate <NSObject>

@optional

- (void)gridView:(RZGridView*)gridView didSelectItemAtIndexPath:(NSIndexPath*)indexPath;

- (CGFloat)gridView:(RZGridView *)gridView heightForRowAtIndexPath:(NSIndexPath*)indexPath;     // Default is 200.0 if not implemented
- (CGFloat)gridView:(RZGridView *)gridView widthForColumnAtIndexPath:(NSIndexPath *)indexPath;  // Default is RZGRIDVIEW_AUTO_WIDTH if not implemented
- (RZGridViewSectionArrangement)sectionArrangementForGridView:(RZGridView*)gridView;            // Default is RZGridViewArrangementVertical if not implemented

- (void)gridViewDidScroll:(RZGridView *)gridView;

@end


// This category provides convenience methods to make it easier to use an NSIndexPath to represent a section, row, and column
@interface NSIndexPath (RZGridView)

+ (NSIndexPath *)indexPathForColumn:(NSUInteger)column andRow:(NSUInteger)row inSection:(NSUInteger)section;

@property(nonatomic,readonly) NSUInteger gridSection;
@property(nonatomic,readonly) NSUInteger gridRow;
@property(nonatomic,readonly) NSUInteger gridColumn;

@end