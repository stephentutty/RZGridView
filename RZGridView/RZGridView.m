//
//  RZGridView.m
//  RZGridView
//
//  Created by Joe Goullaud on 10/3/11.
//  Copyright 2011 Raizlabs. All rights reserved.
//

#import "RZGridView.h"

@interface RZGridView ()

@property (nonatomic, retain, getter = _visibleCells) NSMutableArray *visibleCells;
@property (nonatomic, retain) NSMutableSet *recycledCells;
@property (retain, readwrite) RZGridViewCell *selectedCell;
@property (nonatomic, retain) UITapGestureRecognizer *cellTapGestureRecognizer;
@property (nonatomic, retain) NSMutableArray *reorderedCellsIndexMap;

@property (nonatomic, assign) id<RZGridViewDelegate> gridDelegate;
@property (nonatomic, retain) NSMutableArray *sectionRanges;
@property (nonatomic, retain) NSMutableArray *rowRangesBySection;

@property (nonatomic, assign) CGFloat rowHeight;
@property (nonatomic, assign) CGFloat colWidth;

@property (nonatomic, assign) NSUInteger totalItems;
@property (nonatomic, assign) NSUInteger totalRows;
@property (nonatomic, assign) NSUInteger totalSections;
@property (nonatomic, assign) NSUInteger maxCols;

@property (nonatomic, assign) CGPoint reorderTouchOffset;
@property (nonatomic, retain) NSIndexPath *selectedLastPath;
@property (nonatomic, retain) NSIndexPath *selectedStartPath;

@property (assign, getter = isScrolling) BOOL scrolling;

- (void)setupGridView;

- (void)loadData;
- (void)configureScrollView;

- (void)updateVisibleCells;
- (void)tileCellsAnimated:(BOOL)animated;
- (void)layoutCells;

- (void)handleCellPress:(UILongPressGestureRecognizer*)gestureRecognizer;
- (void)moveItemAtIndexPath:(NSIndexPath*)sourceIndexPath toIndexPath:(NSIndexPath*)destinationIndexPath;

- (NSArray*)indexPathsForItemsInRect:(CGRect)rect;
- (NSIndexPath*)indexPathForIndex:(NSInteger)index;
- (NSUInteger)indexForIndexPath:(NSIndexPath*)indexPath;
- (NSRange)rangeForSection:(NSUInteger)section;
- (NSRange)rangeForRow:(NSUInteger)row inSection:(NSUInteger)section;
- (CGFloat)widthForSection:(NSUInteger)section;
- (CGFloat)widthForRow:(NSUInteger)row inSection:(NSUInteger)section;

- (void)updateSelectedCellIndex;
- (void)scrollIfNeededUsingDelta:(CGPoint)delta;

- (void)updateGridFlagsWithDataSource:(id<RZGridViewDataSource>)dataSource;
- (void)updateGridFlagsWithDelegate:(id<RZGridViewDelegate>)delegate;

- (void)gridTapped:(UITapGestureRecognizer*)gestureRecognizer;

@end

@implementation RZGridView

@synthesize dataSource = _dataSource;

@synthesize reorderLongPressDelay = _reorderLongPressDelay;
@synthesize sectionArrangement = _sectionArrangement;

@synthesize visibleCells = _visibleCells;
@synthesize recycledCells = _recycledCells;
@synthesize selectedCell = _selectedCell;
@synthesize cellTapGestureRecognizer = _cellTapGestureRecognizer;
@synthesize reorderedCellsIndexMap = _reorderedCellsIndexMap;

@synthesize gridDelegate = _gridDelegate;
@synthesize sectionRanges = _sectionRanges;
@synthesize rowRangesBySection = _rowRangesBySection;

@synthesize rowHeight = _rowHeight;
@synthesize colWidth = _colWidth;

@synthesize totalItems = _totalItems;
@synthesize totalRows = _totalRows;
@synthesize totalSections = _totalSections;
@synthesize maxCols = _maxCols;

@synthesize reorderTouchOffset = _reorderTouchOffset;
@synthesize selectedLastPath = _selectedLastPath;
@synthesize selectedStartPath = _selectedStartPath;

@synthesize scrolling = _scrolling;

@synthesize shouldPauseReload = _shouldPauseReload;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setupGridView];
    }
    return self;
}

- (void)awakeFromNib
{
    [self setupGridView];
}

- (void)dealloc
{
    self.gridDelegate = nil;
    [super setDelegate:nil];
    
    self.dataSource = nil;
    
    [_visibleCells release];
    [_selectedCell release];
    
    [_sectionRanges release];
    [_rowRangesBySection release];
    
    [_selectedLastPath release];
    [_selectedStartPath release];
    
    [super dealloc];
}

- (void)setupGridView
{
    self.rowHeight = RZGRIDVIEW_DEFAULT_HEIGHT;
    self.colWidth = RZGRIDVIEW_DEFAULT_WIDTH;
    self.sectionArrangement = RZGridViewSectionArrangementVertical;
    self.totalSections = 1;
    self.totalRows = 0;
    self.totalItems = 0;
    self.maxCols = 0;
    self.reorderLongPressDelay = 0.5;
    self.scrolling = NO;
    self.selectedCell = nil;
    
    self.recycledCells = [NSMutableSet set];
    
    self.multipleTouchEnabled = NO;
    [super setDelegate:self];
    
    UITapGestureRecognizer *selectTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(gridTapped:)];
    selectTapGesture.numberOfTapsRequired = 1;
    selectTapGesture.numberOfTouchesRequired = 1;
    selectTapGesture.cancelsTouchesInView = NO;
    self.cellTapGestureRecognizer = selectTapGesture;
    [self addGestureRecognizer:selectTapGesture];
    [selectTapGesture release];
    
    [self loadData];
    [self configureScrollView];
    [self tileCellsAnimated:NO];
    
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self configureScrollView];
    [self tileCellsAnimated:NO];
}

- (void)setDataSource:(id<RZGridViewDataSource>)dataSource
{
    if (dataSource == _dataSource)
    {
        return;
    }
    
    _dataSource = dataSource;
    
    [self updateGridFlagsWithDataSource:_dataSource];
    [self reloadData];
}

- (id<RZGridViewDelegate>)delegate
{
    return self.gridDelegate;
}

- (void)setDelegate:(id<RZGridViewDelegate>)delegate
{
    if (delegate == self.gridDelegate)
    {
        return;
    }
    else if (delegate == (id)self)
    {
        [super setDelegate:delegate];
        return;
    }
    
    self.gridDelegate = delegate;
    
    [self updateGridFlagsWithDelegate:delegate];
    [self reloadData];
}

- (void)reloadData
{
    [self loadData];
    [self configureScrollView];
    [self tileCellsAnimated:NO];

}

- (NSInteger)numberOfSections
{
    return self.totalSections;
}

- (NSInteger)numberOfRowsInSection:(NSInteger)section
{
    return [[self.rowRangesBySection objectAtIndex:section] count];
}

- (CGRect)rectForSection:(NSInteger)section
{
    CGFloat xOffset = 0;
    CGFloat yOffset = 0;
    CGFloat width = 0;
    CGFloat height = 0;
    
    if (RZGridViewSectionArrangementVertical == self.sectionArrangement)
    {
        for (int sectionIndex = 0; sectionIndex < section; ++sectionIndex)
        {
            yOffset += [self rectForHeaderInSection:sectionIndex].size.height;
            yOffset += [self.dataSource gridView:self numberOfRowsInSection:sectionIndex] * self.rowHeight;
            yOffset += [self rectForFooterInSection:sectionIndex].size.height;
        }
        
        width = [self widthForSection:section];
    }
    else
    {
        for (int sectionIndex = 0; sectionIndex < section; ++sectionIndex)
        {
            xOffset += [self widthForSection:sectionIndex];
        }
        
        width = [self widthForSection:section];
    }
    
    height += [self rectForHeaderInSection:section].size.height;
    height += [self.dataSource gridView:self numberOfRowsInSection:section] * self.rowHeight;
    height += [self rectForFooterInSection:section].size.height;
    
    return CGRectMake(xOffset, yOffset, width, height);
}

- (CGRect)rectForHeaderInSection:(NSInteger)section
{
    return CGRectZero;
}

- (CGRect)rectForFooterInSection:(NSInteger)section
{
    return CGRectZero;
}

- (CGRect)rectForRow:(NSInteger)row inSection:(NSInteger)section
{
    CGRect sectionRect = [self rectForSection:section];
    CGRect headerRect = [self rectForHeaderInSection:section];
    
    CGRect rowRect = CGRectMake(sectionRect.origin.x, sectionRect.origin.y + headerRect.size.height + (row * self.rowHeight), sectionRect.size.width, self.rowHeight);
    
    return rowRect;
}

- (CGRect)rectForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGRect rowRect = [self rectForRow:indexPath.gridRow inSection:indexPath.gridSection];
    
    NSInteger columnsInCurrentRow = [self.dataSource gridView:self numberOfColumnsInRow:indexPath.gridRow inSection:indexPath.gridSection];
    
    CGFloat columnWidth = rowRect.size.width / (CGFloat)columnsInCurrentRow;
    
    CGRect itemRect = CGRectMake(rowRect.origin.x + ((CGFloat)indexPath.gridColumn * columnWidth), rowRect.origin.y, columnWidth, rowRect.size.height);
    
    return itemRect;
}

- (NSIndexPath*)indexPathForItemAtPoint:(CGPoint)point
{
    // Bin Search Sections
    NSInteger min = 0;
    NSInteger max = self.totalSections - 1;
    NSInteger section = -1;
    BOOL pointInSection = NO;
    do {
        section = (min + max) / 2;
        
        CGRect sectionRect = [self rectForSection:section];
        
        if (CGRectContainsPoint(sectionRect, point))
        {
            pointInSection = YES;
            break;
        }
        
        if ((self.sectionArrangement == RZGridViewSectionArrangementVertical && point.y > CGRectGetMinY(sectionRect)) ||
            (self.sectionArrangement == RZGridViewSectionArrangementHorizontal && point.x > CGRectGetMinX(sectionRect)))
        {
            min = section + 1;
        }
        else
        {
            max = section - 1;
        }
        
    } while (min <= max);
    
    if (!pointInSection)
    {
        return nil;
    }
    
    // Bin Search Rows
    min = 0;
    max = [self numberOfRowsInSection:section] - 1;
    NSInteger row = -1;
    BOOL pointInRow = NO;
    do {
        row = (min + max) / 2;
        
        CGRect rowRect = [self rectForRow:row inSection:section];
        
        if (CGRectContainsPoint(rowRect, point))
        {
            pointInRow = YES;
            break;
        }
        
        if (point.y > CGRectGetMinY(rowRect))
        {
            min = row + 1;
        }
        else
        {
            max = row - 1;
        }
        
    } while (min <= max);
    
    if (!pointInRow)
    {
        return nil;
    }
    
    // Find Col
    min = 0;
    max = [self.dataSource gridView:self numberOfColumnsInRow:row inSection:section] - 1;
    NSInteger col = -1;
    do {
        col = (min + max) / 2;
        NSIndexPath *itemIndexPath = [NSIndexPath indexPathForColumn:col andRow:row inSection:section];
        
        CGRect itemRect = [self rectForItemAtIndexPath:itemIndexPath];
        
        if (CGRectContainsPoint(itemRect, point))
        {
            NSUInteger maxCol = [[[self.rowRangesBySection objectAtIndex:section] objectAtIndex:row] rangeValue].length - 1;
            if (itemIndexPath.gridColumn > maxCol)
            {
                itemIndexPath = [NSIndexPath indexPathForColumn:maxCol andRow:row inSection:section];
            }
            
            return itemIndexPath;
        }
        
        if (point.x > CGRectGetMaxX(itemRect))
        {
            min = col + 1;
        }
        else
        {
            max = col - 1;
        }
        
    } while (min <= max);
    
    return nil;
}

- (NSIndexPath*)indexPathForCell:(RZGridViewCell*)cell
{
    NSUInteger index = [self.visibleCells indexOfObject:cell];
    
    if (index != NSNotFound)
    {
        NSInteger section = -1;
        
        for (int sectionIndex = 0; sectionIndex < [self.sectionRanges count]; ++sectionIndex)
        {
            NSValue *value = [self.sectionRanges objectAtIndex:sectionIndex];
            NSRange sectionRange = [value rangeValue];
            if (NSLocationInRange(index, sectionRange))
            {
                section = sectionIndex;
                break;
            }
        }
        
        if (section < 0 || section >= [self.rowRangesBySection count])
        {
            return nil;
        }
        
        NSArray *sectionRowRanges = [self.rowRangesBySection objectAtIndex:section];
        
        for (int row = 0; row < [sectionRowRanges count]; ++row)
        {
            NSValue *value = [sectionRowRanges objectAtIndex:row];
            NSRange rowRange = [value rangeValue];
            if (NSLocationInRange(index, rowRange))
            {
                NSInteger column = index - rowRange.location;
                
                return [NSIndexPath indexPathForColumn:column andRow:row inSection:section];
            }
        }
    }
    
    return nil;
}

- (RZGridViewCell*)cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger index = [self indexForIndexPath:indexPath];
    
    if (index < [self.visibleCells count])
    {
        id cell = [self.visibleCells objectAtIndex:index];
        
        if (cell != [NSNull null])
        {
            return cell;
        }
    }
    
    return nil;
}

- (NSArray *)visibleCells
{
    return [self.visibleCells filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF != %@", [NSNull null]]];
}

- (NSArray *)indexPathsForVisibleItems
{
    NSArray *visibleCells = [self visibleCells];
    NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:[visibleCells count]];
    
    for (RZGridViewCell *cell in visibleCells)
    {
        NSIndexPath *indexPath = [self indexPathForCell:cell];
        if (nil != indexPath)
        {
            [indexPaths addObject:indexPath];
        }
    }
    
    return indexPaths;
}

- (RZGridViewCell*)dequeueReusableCellWithIdentifier:(NSString*)cellIdentifier
{
    NSSet *reusableCells = [self.recycledCells filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"reuseIdentifier == %@", cellIdentifier]];
    
    RZGridViewCell *cell = [reusableCells anyObject];
    
    if (cell)
    {
        [self.recycledCells removeObject:cell];
        [cell prepareForReuse];
    }
    
    return cell;
}

- (void)loadData
{
    NSInteger totalItems = 0;
    NSInteger totalRows = 0;
    NSInteger numSections = 1;
    NSInteger maxCols = 0;
    
    if (_gridFlags.dataSourceNumberOfSectionsInGridView)
    {
        numSections = [self.dataSource numberOfSectionsInGridView:self];
    }
    
    [[self visibleCells] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    self.visibleCells = [NSMutableArray array];
    self.sectionRanges = [NSMutableArray arrayWithCapacity:numSections];
    self.rowRangesBySection = [NSMutableArray arrayWithCapacity:numSections];
    
    for (NSInteger section = 0; section < numSections; ++section)
    {
        NSInteger sectionOffset = totalItems;
        NSInteger itemsInSection = 0;
        NSInteger totalItemsInSection = [self.dataSource gridView:self numberOfItemsInSection:section];
        NSInteger numRows = [self.dataSource gridView:self numberOfRowsInSection:section];
        totalRows += numRows;
        
        [self.rowRangesBySection addObject:[NSMutableArray arrayWithCapacity:numRows]];
        
        for (NSInteger row = 0; row < numRows; ++row)
        {
            NSInteger rowOffset = totalItems;
            NSInteger itemsInRow = 0;
            NSInteger numColumns = [self.dataSource gridView:self numberOfColumnsInRow:row inSection:section];
            
            maxCols = MAX(maxCols, numColumns);
            
            for (NSInteger column = 0; column < numColumns; ++column)
            {
                if (itemsInSection < totalItemsInSection)
                {
                    [self.visibleCells addObject:[NSNull null]];
                    ++itemsInRow;
                    ++itemsInSection;
                    ++totalItems;
                }
                else
                {
                    break;
                }
            }
            
            [[self.rowRangesBySection objectAtIndex:section] addObject:[NSValue valueWithRange:NSMakeRange(rowOffset, itemsInRow)]];
        }
        
        [self.sectionRanges addObject:[NSValue valueWithRange:NSMakeRange(sectionOffset, itemsInSection)]];
    }
    
    self.totalItems = totalItems;
    self.totalRows = totalRows;
    self.totalSections = numSections;
    self.maxCols = maxCols;
    
//    NSLog(@"Section Ranges:\n%@", self.sectionRanges);
//    NSLog(@"Row Ranges:\n%@", self.rowRangesBySection);
}

- (void)configureScrollView
{
    CGFloat width = RZGRIDVIEW_DEFAULT_WIDTH;
    CGFloat height = RZGRIDVIEW_DEFAULT_HEIGHT;
    
    if (_gridFlags.delegateHeightForRowAtIndexPath)
    {
        height = [self.delegate gridView:self heightForRowAtIndexPath:[NSIndexPath indexPathForColumn:0 andRow:0 inSection:0]];
    }
    
    if (_gridFlags.delegateWidthForColumnAtIndexPath)
    {
        width = [self.delegate gridView:self widthForColumnAtIndexPath:[NSIndexPath indexPathForColumn:0 andRow:0 inSection:0]];
    }
    
    if (height == RZGRIDVIEW_AUTO_HEIGHT)
    {
        height = self.bounds.size.height / (CGFloat)self.totalRows;
    }
    
    if (width == RZGRIDVIEW_AUTO_WIDTH)
    {
        width = self.bounds.size.width / (CGFloat)self.maxCols;
    }
    
    self.colWidth = width;
    self.rowHeight = height;
    
    if (_gridFlags.delegateSectionArrangementForGridView)
    {
        self.sectionArrangement = [self.delegate sectionArrangementForGridView:self];
    }
    
    CGRect contentRect = CGRectNull;
    
    for (int i = 0; i < self.totalSections; ++i)
    {
        contentRect = CGRectUnion(contentRect, [self rectForSection:i]);
    }
    
    self.contentSize = contentRect.size;
    
    if (CGPointEqualToPoint(self.contentOffset, CGPointZero))
    {
        self.contentOffset = CGPointMake(-self.contentInset.left, -self.contentInset.top);
    }
}

- (void)updateVisibleCells
{
    [UIView setAnimationsEnabled:NO];
    
    CGRect visibleRect = CGRectIntersection((CGRect){CGPointZero, self.contentSize}, CGRectInset(self.bounds, -self.colWidth, -self.rowHeight));
    
    NSArray *currentVisibleIndexPaths = [self indexPathsForVisibleItems];
    NSArray *stillVisibleIndexPaths = [self indexPathsForItemsInRect:visibleRect];
    
    NSMutableSet *stillVisibleCells = [NSMutableSet setWithCapacity:[stillVisibleIndexPaths count]];
    
    NSMutableSet *removedIndexPaths = [NSMutableSet setWithArray:currentVisibleIndexPaths];
    [removedIndexPaths minusSet:[NSSet setWithArray:stillVisibleIndexPaths]];
    
//    NSLog(@"Cells to Remove: %d", [removedIndexPaths count]);
    
    for (NSIndexPath *indexPath in removedIndexPaths)
    {
        RZGridViewCell *cell = [self cellForItemAtIndexPath:indexPath];
        
        if (cell && cell != self.selectedCell)
        {
            [self.recycledCells addObject:cell];
            for (UIGestureRecognizer *gr in [cell gestureRecognizers])
            {
                if (gr.delegate == self)
                {
                    [cell removeGestureRecognizer:gr];
                }
            }
            [cell removeFromSuperview];
            NSUInteger index = [self.visibleCells indexOfObject:cell];
            
            if (NSNotFound != index)
            {
                [self.visibleCells replaceObjectAtIndex:index withObject:[NSNull null]];
            }
        }
    }
    
    for (NSIndexPath *indexPath in stillVisibleIndexPaths)
    {
        if ([self indexForIndexPath:indexPath] == NSNotFound)
            continue;
        
        RZGridViewCell *cell = nil;
        
        cell = [self cellForItemAtIndexPath:indexPath];
        
        if (cell)
        {
            [stillVisibleCells addObject:cell];
        }
        else
        {
            if (self.selectedCell != nil)
            {
                NSInteger oldIndex = [self indexForIndexPath:indexPath];
                NSInteger newIndex = [[self.reorderedCellsIndexMap objectAtIndex:oldIndex] integerValue];
                NSIndexPath *newIndexPath = [self indexPathForIndex:newIndex];
                
                cell = [self.dataSource gridView:self cellForItemAtIndexPath:newIndexPath];
            }
            else
            {
                cell = [self.dataSource gridView:self cellForItemAtIndexPath:indexPath];
            }
            
            if (cell)
            {
                CGRect cellFrame = [self rectForItemAtIndexPath:indexPath];
                cell.frame = cellFrame;
                
                UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleCellPress:)];
                longPress.minimumPressDuration = self.reorderLongPressDelay;
                longPress.delegate = self;
                [cell addGestureRecognizer:longPress];
                [longPress release];
                
                cell.userInteractionEnabled = YES;
                cell.clipsToBounds = YES;
                
                [self addSubview:cell];
                
                NSUInteger index = [self indexForIndexPath:indexPath];
                
                if (NSNotFound != index)
                {
                    [self.visibleCells replaceObjectAtIndex:index withObject:cell];
                }
                
                [stillVisibleCells addObject:cell];
            }
        }
    }
    
//    NSLog(@"Visible Cells: %d - Total Recycled Cells: %d", [[self visibleCells] count], [self.recycledCells count]);
    
    while ([self.recycledCells count] > 10)
    {
        [self.recycledCells removeObject:[self.recycledCells anyObject]];
    }
    
    [UIView setAnimationsEnabled:YES];
}

- (void)tileCellsAnimated:(BOOL)animated
{
    if (self.shouldPauseReload) {
        // When we pause reload we still want to update the frames of the cells, but not do a datasource call for new contents in -updateVisibleCells
        
        [self layoutCells];
    }
    else {
        [self updateVisibleCells];
        
        if (animated)
        {
            [UIView animateWithDuration:0.25 
                                  delay:0 
                                options:(UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowAnimatedContent | UIViewAnimationOptionAllowUserInteraction)
                             animations:^(void) {
                                 [self layoutCells];
                             } 
                             completion:^(BOOL finished) {
                                 
                             }
             ];
        }
        else
        {
            [self layoutCells];
        }
    }
}

- (void)setShouldPauseReload:(BOOL)shouldPauseReload
{
    _shouldPauseReload = shouldPauseReload;
}

- (void)layoutCells
{
    for (RZGridViewCell *cell in [self visibleCells])
    {
        if (cell != self.selectedCell)
        {
            NSIndexPath *cellPath = [self indexPathForCell:cell];
            
            CGRect cellFrame = [self rectForItemAtIndexPath:cellPath];
            
            cell.frame = cellFrame;
        }
//        [self.scrollView addSubview:cell];
    }
    
    [self bringSubviewToFront:self.selectedCell];
    
    [self setNeedsDisplay];
}

- (void)gridTapped:(UITapGestureRecognizer*)gestureRecognizer
{
    NSIndexPath *indexPath = [self indexPathForItemAtPoint:[gestureRecognizer locationInView:self]];
    
    if (indexPath && _gridFlags.delegateDidSelectItemAtIndexPath)
    {
        [self.delegate gridView:self didSelectItemAtIndexPath:indexPath];
    }
}

- (void)handleCellPress:(UILongPressGestureRecognizer*)gestureRecognizer
{
    CGPoint oldCenter;
    
    switch ([gestureRecognizer state]) {
        case UIGestureRecognizerStateBegan:
            self.selectedCell = (RZGridViewCell*)gestureRecognizer.view;
            self.selectedStartPath = [self indexPathForCell:(RZGridViewCell *)gestureRecognizer.view];
            self.selectedLastPath = self.selectedStartPath;
            
            NSMutableArray *cellIndecies = [NSMutableArray arrayWithCapacity:[self.visibleCells count]];
            
            for (int i = 0; i < [self.visibleCells count]; ++i)
            {
                [cellIndecies addObject:[NSNumber numberWithInt:i]];
            }
            
            self.reorderedCellsIndexMap = cellIndecies;
            
            self.reorderTouchOffset = CGPointMake(gestureRecognizer.view.center.x - [gestureRecognizer locationInView:self].x, 
                                                  gestureRecognizer.view.center.y - [gestureRecognizer locationInView:self].y);
            [self bringSubviewToFront:gestureRecognizer.view];
            [UIView animateWithDuration:0.2 animations:^(void) {
                gestureRecognizer.view.transform = CGAffineTransformMakeScale(1.25, 1.25);
                gestureRecognizer.view.alpha = 0.75;
            }];
            break;
            
        case UIGestureRecognizerStateChanged:
            oldCenter = self.selectedCell.center;
            
            self.selectedCell.center = CGPointApplyAffineTransform([gestureRecognizer locationInView:self], CGAffineTransformMakeTranslation(self.reorderTouchOffset.x, self.reorderTouchOffset.y));
            
            CGPoint delta = CGPointMake(self.selectedCell.center.x - oldCenter.x, self.selectedCell.center.y - oldCenter.y);
            
            [self updateSelectedCellIndex];
            
            [self scrollIfNeededUsingDelta:delta];
            
            break;
        
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
            
            [self updateSelectedCellIndex];
            
            CGRect endRect = [self rectForItemAtIndexPath:self.selectedLastPath];
            
            [UIView animateWithDuration:0.2 animations:^(void) {
                gestureRecognizer.view.center = CGPointMake(CGRectGetMidX(endRect), CGRectGetMidY(endRect));
                
                gestureRecognizer.view.transform = CGAffineTransformIdentity;
                gestureRecognizer.view.alpha = 1.0;
            }];
            
            if (self.selectedStartPath && 
                self.selectedLastPath && 
                ![self.selectedStartPath isEqual:self.selectedLastPath] && 
                _gridFlags.dataSourceMoveItemAtIndexPathToIndexPath)
            {
                [self.dataSource gridView:self moveItemAtIndexPath:self.selectedStartPath toIndexPath:self.selectedLastPath];
            }
            
            self.selectedCell = nil;
            self.reorderedCellsIndexMap = nil;
            self.selectedStartPath = nil;
            self.selectedLastPath = nil;
            break;
            
        default:
            break;
    }
}

- (void)moveItemAtIndexPath:(NSIndexPath*)sourceIndexPath toIndexPath:(NSIndexPath*)destinationIndexPath
{
    NSUInteger sourceIndex = [self indexForIndexPath:sourceIndexPath];
    NSUInteger destinationIndex = [self indexForIndexPath:destinationIndexPath];
    NSUInteger removeIndex = sourceIndex;
    
    if (destinationIndex < sourceIndex)
    {
        ++removeIndex;
    }
    else
    {
        ++destinationIndex;
    }
    
    RZGridViewCell *cell = [self.visibleCells objectAtIndex:sourceIndex];
    NSNumber *index = [self.reorderedCellsIndexMap objectAtIndex:sourceIndex];
    
    [self.visibleCells insertObject:cell atIndex:destinationIndex];
    [self.visibleCells removeObjectAtIndex:removeIndex];
    [self.reorderedCellsIndexMap insertObject:index atIndex:destinationIndex];
    [self.reorderedCellsIndexMap removeObjectAtIndex:removeIndex];
    
    [self tileCellsAnimated:YES];
}

- (NSArray*)indexPathsForItemsInRect:(CGRect)rect
{
    NSMutableArray *indexPaths = [NSMutableArray array];
    
    if (!CGRectIsEmpty(rect))
    {
        CGPoint upperLeft = CGPointMake(CGRectGetMinX(rect) + 0.1, CGRectGetMinY(rect) + 0.1);
        CGPoint lowerRight = CGPointMake(CGRectGetMaxX(rect)-0.1, CGRectGetMaxY(rect)-0.1);
        
        NSIndexPath *upperLeftPath = [self indexPathForItemAtPoint:upperLeft];
        NSIndexPath *lowerRightPath = [self indexPathForItemAtPoint:lowerRight];
        
        for (int section = upperLeftPath.gridSection; section <= lowerRightPath.gridSection; ++section)
        {
            CGRect sectionRect = CGRectIntersection([self rectForSection:section], rect);
            
            CGPoint sectionUpperLeft = CGPointMake(CGRectGetMinX(sectionRect) + 0.1, CGRectGetMinY(sectionRect) + 0.1);
            CGPoint sectionLowerRight = CGPointMake(CGRectGetMaxX(sectionRect)-0.1, CGRectGetMaxY(sectionRect)-0.1);
            
            NSIndexPath *sectionUpperLeftPath = [self indexPathForItemAtPoint:sectionUpperLeft];
            NSIndexPath *sectionLowerRightPath = [self indexPathForItemAtPoint:sectionLowerRight];
            
            for (int row = sectionUpperLeftPath.gridRow; row <= sectionLowerRightPath.gridRow; ++row)
            {
                CGRect rowRect = CGRectIntersection([self rectForRow:row inSection:section], rect);
                
                NSInteger firstColumn = [self indexPathForItemAtPoint:CGPointMake(CGRectGetMinX(rowRect) + 0.1, CGRectGetMinY(rowRect) + 0.1)].gridColumn;
                NSInteger lastColumn = [self indexPathForItemAtPoint:CGPointMake(CGRectGetMaxX(rowRect)-0.1, CGRectGetMaxY(rowRect)-0.1)].gridColumn;
                
                for (int column = firstColumn; column <= lastColumn; ++column)
                {
                    [indexPaths addObject:[NSIndexPath indexPathForColumn:column andRow:row inSection:section]];
                }
            }
        }
    }
    
    return indexPaths;
}

- (NSIndexPath*)indexPathForIndex:(NSInteger)index
{
    NSIndexPath *indexPath = nil;
    
    NSInteger section = NSNotFound;
    for (int i = 0; i < [self.sectionRanges count]; ++i)
    {
        NSRange sectionRange = [self rangeForSection:i];
        
        if (NSLocationInRange(index, sectionRange))
        {
            section = i;
            break;
        }
    }
    
    if (NSNotFound != section)
    {
        for (int row = 0; row < [[self.rowRangesBySection objectAtIndex:section] count]; ++row)
        {
            NSRange rowRange = [self rangeForRow:row inSection:section];
            
            if (NSLocationInRange(index, rowRange))
            {
                NSInteger column = index - rowRange.location;
                indexPath = [NSIndexPath indexPathForColumn:column andRow:row inSection:section];
                break;
            }
        }
    }
    
    return indexPath;
}

- (NSUInteger)indexForIndexPath:(NSIndexPath*)indexPath
{
    NSInteger offset = NSNotFound;
    
    NSRange rowRange = [self rangeForRow:indexPath.gridRow inSection:indexPath.gridSection];
    
    if (rowRange.length > 0)
    {
        offset = rowRange.location + indexPath.gridColumn;
    }
    
    return offset;
}

- (NSRange)rangeForSection:(NSUInteger)section
{
    if (section < self.totalSections)
    {
        NSValue *sectionValue = [self.sectionRanges objectAtIndex:section];
        
        if (sectionValue)
        {
            return [sectionValue rangeValue];
        }
    }
    
    return NSMakeRange(0, 0);
}

- (NSRange)rangeForRow:(NSUInteger)row inSection:(NSUInteger)section
{
    if (section < self.totalSections && row < [self numberOfRowsInSection:section])
    {
        NSArray *rowRanges = [self.rowRangesBySection objectAtIndex:section];
        
        if (rowRanges)
        {
            NSValue *rowValue = [rowRanges objectAtIndex:row];
            
            if (rowValue)
            {
                return [rowValue rangeValue];
            }
        }
    }
    
    return NSMakeRange(0, 0);
}

- (CGFloat)widthForSection:(NSUInteger)section
{
    if (!_gridFlags.delegateWidthForColumnAtIndexPath)
    {
        return self.bounds.size.width;
    }
    
    CGFloat maxWidth = 0.0;
    
    NSUInteger rows = [[self.rowRangesBySection objectAtIndex:section] count];
    for (int i = 0; i < rows; ++i)
    {
        maxWidth = MAX(maxWidth, [self widthForRow:i inSection:section]);
    }
    
    return maxWidth;
}

- (CGFloat)widthForRow:(NSUInteger)row inSection:(NSUInteger)section
{
    if (!_gridFlags.delegateWidthForColumnAtIndexPath)
    {
        return self.bounds.size.width;
    }
    
    NSRange rowRange = [[[self.rowRangesBySection objectAtIndex:section] objectAtIndex:row] rangeValue];
    
    return self.colWidth * rowRange.length;
}

- (void)updateSelectedCellIndex
{
    NSIndexPath *currentIndexPath = [self indexPathForItemAtPoint:self.selectedCell.center];
    
    if (currentIndexPath && ![self.selectedLastPath isEqual:currentIndexPath])
    {
        [self moveItemAtIndexPath:self.selectedLastPath toIndexPath:currentIndexPath];
        self.selectedLastPath = currentIndexPath;
    }
}

- (void)scrollIfNeededUsingDelta:(CGPoint)delta
{
    @synchronized(self)
    {
        if (!self.scrolling && self.selectedCell && (self.contentSize.width > self.bounds.size.width || self.contentSize.height > self.bounds.size.height))
        {
            CGPoint locationInBounds = [self.selectedCell.superview convertPoint:self.selectedCell.center toView:self];
            CGFloat xMinBoundry = self.bounds.origin.x + self.selectedCell.bounds.size.width / 2.0;
            CGFloat xMaxBounrdy = self.bounds.origin.x + self.bounds.size.width - xMinBoundry;
            CGFloat yMinBoundry = self.bounds.origin.y + self.selectedCell.bounds.size.height / 2.0;
            CGFloat yMaxBoundry = self.bounds.origin.y + self.bounds.size.height - yMinBoundry;
            
            CGFloat xOffset = 0.0;
            CGFloat yOffset = 0.0;
            CGFloat xSpeed = self.colWidth * 0.30;// self.scrollView.bounds.size.width * 0.10;
            CGFloat ySpeed = self.rowHeight * 0.30;//self.scrollView.bounds.size.height * 0.10;
            
            BOOL canScrollX = self.contentSize.width > self.bounds.size.width;
            BOOL canScrollY = self.contentSize.height > self.bounds.size.height;
            
            if (canScrollX)
            {
                if (locationInBounds.x < xMinBoundry && delta.x < 1.0)
                {
                    xOffset = -xSpeed * (1.0 - (locationInBounds.x - self.contentOffset.x)/self.bounds.size.width);
                }
                else if (locationInBounds.x > xMaxBounrdy && delta.x > -1.0)
                {
                    xOffset = xSpeed * ((locationInBounds.x - self.contentOffset.x)/self.bounds.size.width);
                }
            }
            
            if (canScrollY)
            {
                if (locationInBounds.y < yMinBoundry && delta.y < 1.0)
                {
                    yOffset = -ySpeed * (1.0 - (locationInBounds.y - self.contentOffset.y)/self.bounds.size.height);
                }
                else if (locationInBounds.y > yMaxBoundry && delta.y > -1.0)
                {
                    yOffset = ySpeed * ((locationInBounds.y - self.contentOffset.y)/self.bounds.size.height);
                }
            }
            
            CGPoint scrollOffset = self.contentOffset;
            CGFloat minX = - self.contentInset.left;
            CGFloat minY = - self.contentInset.top;
            CGFloat maxX = (self.contentSize.width + self.contentInset.right) - self.bounds.size.width;
            CGFloat maxY = (self.contentSize.height + self.contentInset.bottom) - self.bounds.size.height;
            
            if (canScrollX)
            {
                if (scrollOffset.x + xOffset < minX)
                {
                    xOffset = minX - scrollOffset.x;
                }
                else if (scrollOffset.x + xOffset > maxX)
                {
                    xOffset = maxX - scrollOffset.x;
                }
            }
            
            if (canScrollY)
            {
                if (scrollOffset.y + yOffset < minY)
                {
                    yOffset = minY - scrollOffset.y;
                }
                else if (scrollOffset.y + yOffset > maxY)
                {
                    yOffset = maxY - scrollOffset.y;
                }
            }
            
            if (fabs(xOffset) > 1.0 || fabs(yOffset) > 1.0)
            {
                self.scrolling = YES;
                [UIView animateWithDuration:0.1
                                      delay:0
                                    options:(UIViewAnimationOptionCurveLinear | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction |
                                        UIViewAnimationOptionAllowAnimatedContent) 
                                 animations:^{
                                     CGPoint offset = self.contentOffset;
                                     offset.x += xOffset;
                                     offset.y += yOffset;
                                     [self setContentOffset:offset animated:NO];
                                     
                                     CGPoint cellCenter = self.selectedCell.center;
                                     cellCenter.x += xOffset;
                                     cellCenter.y += yOffset;
                                     self.selectedCell.center = cellCenter;
                                     
                                     [self updateSelectedCellIndex];
                                 } 
                                 completion:^(BOOL finished) {
                                     self.scrolling = NO;
                                     [self scrollIfNeededUsingDelta:CGPointMake(xOffset, yOffset)];
                                 }
                 ];
            }
        }
    }
}

- (void)updateGridFlagsWithDataSource:(id<RZGridViewDataSource>)dataSource
{
    _gridFlags.dataSourceNumberOfItemsInSection = [dataSource respondsToSelector:@selector(gridView:numberOfItemsInSection:)];
    _gridFlags.dataSourceNumberOfRowsInSection = [dataSource respondsToSelector:@selector(gridView:numberOfRowsInSection:)];
    _gridFlags.dataSourceNumberOfColumnsInRow = [dataSource respondsToSelector:@selector(gridView:numberOfColumnsInRow:inSection:)];
    _gridFlags.dataSourceCellForItemAtIndexPath = [dataSource respondsToSelector:@selector(gridView:cellForItemAtIndexPath:)];
    _gridFlags.dataSourceNumberOfSectionsInGridView = [dataSource respondsToSelector:@selector(numberOfSectionsInGridView:)];
    _gridFlags.dataSourceTitleForHeaderInSection = [dataSource respondsToSelector:@selector(gridView:titleForHeaderInSection:)];
    _gridFlags.dataSourceTitleForFooterInSection = [dataSource respondsToSelector:@selector(gridView:titleForFooterInSection:)];
    _gridFlags.dataSourceMoveItemAtIndexPathToIndexPath = [dataSource respondsToSelector:@selector(gridView:moveItemAtIndexPath:toIndexPath:)];
}

- (void)updateGridFlagsWithDelegate:(id<RZGridViewDelegate>)delegate
{
    _gridFlags.delegateDidSelectItemAtIndexPath = [delegate respondsToSelector:@selector(gridView:didSelectItemAtIndexPath:)];
    _gridFlags.delegateHeightForRowAtIndexPath = [delegate respondsToSelector:@selector(gridView:heightForRowAtIndexPath:)];
    _gridFlags.delegateWidthForColumnAtIndexPath = [delegate respondsToSelector:@selector(gridView:widthForColumnAtIndexPath:)];
    _gridFlags.delegateSectionArrangementForGridView = [delegate respondsToSelector:@selector(sectionArrangementForGridView:)];
    
    // Check UIScrollViewDelegate selectors
    _gridFlags.delegateScrollViewDidScroll = [delegate respondsToSelector:@selector(scrollViewDidScroll:)];
    _gridFlags.delegateScrollViewDidZoom = [delegate respondsToSelector:@selector(scrollViewDidZoom:)];
    _gridFlags.delegateScrollViewWillBeginDragging = [delegate respondsToSelector:@selector(scrollViewWillBeginDragging:)];
    _gridFlags.delegateScrollViewWIllEndDragging = [delegate respondsToSelector:@selector(scrollViewWillEndDragging:withVelocity:targetContentOffset:)];
    _gridFlags.delegateScrollViewDidEndDragging = [delegate respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)];
    _gridFlags.delegateScrollViewWillBeginDecelerating = [delegate respondsToSelector:@selector(scrollViewWillBeginDecelerating:)];
    _gridFlags.delegateScrollViewDidEndDecelerating = [delegate respondsToSelector:@selector(scrollViewDidEndDecelerating:)];
    _gridFlags.delegateScrollViewDidEndScrollingAnimation = [delegate respondsToSelector:@selector(scrollViewDidEndScrollingAnimation:)];
    _gridFlags.delegateViewForZoomingInScrollView = [delegate respondsToSelector:@selector(viewForZoomingInScrollView:)];
    _gridFlags.delegateScrollViewWillBeginZooming = [delegate respondsToSelector:@selector(scrollViewWillBeginZooming:withView:)];
    _gridFlags.delegateScrollViewDidEndZooming = [delegate respondsToSelector:@selector(scrollViewDidEndZooming:withView:atScale:)];
    _gridFlags.delegateScrollViewShouldScrollToTop = [delegate respondsToSelector:@selector(scrollViewShouldScrollToTop:)];
    _gridFlags.delegateScrollViewDidScrollToTop = [delegate respondsToSelector:@selector(scrollViewDidScrollToTop:)];
    
}

#pragma mark - UIScrollView Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self tileCellsAnimated:NO];
    
    if (_gridFlags.delegateScrollViewDidScroll)
    {
        [self.delegate scrollViewDidScroll:scrollView];
    }
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    if (_gridFlags.delegateScrollViewDidZoom)
    {
        [self.delegate scrollViewDidZoom:scrollView];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if (_gridFlags.delegateScrollViewWillBeginDragging)
    {
        [self.delegate scrollViewWillBeginDragging:scrollView];
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    if (_gridFlags.delegateScrollViewWIllEndDragging)
    {
        [self.delegate scrollViewWillEndDragging:scrollView withVelocity:velocity targetContentOffset:targetContentOffset];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (_gridFlags.delegateScrollViewDidEndDragging)
    {
        [self.delegate scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
    }
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView
{
    if (_gridFlags.delegateScrollViewWillBeginDecelerating)
    {
        [self.delegate scrollViewWillBeginDecelerating:scrollView];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if (_gridFlags.delegateScrollViewDidEndDecelerating)
    {
        [self.delegate scrollViewDidEndDecelerating:scrollView];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    if (_gridFlags.delegateScrollViewDidEndScrollingAnimation)
    {
        [self.delegate scrollViewDidEndScrollingAnimation:scrollView];
    }
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    if (_gridFlags.delegateViewForZoomingInScrollView)
    {
        return [self.delegate viewForZoomingInScrollView:scrollView];
    }
    
    return nil;
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view
{
    if (_gridFlags.delegateScrollViewWillBeginZooming)
    {
        [self.delegate scrollViewWillBeginZooming:scrollView withView:view];
    }
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale
{
    if (_gridFlags.delegateScrollViewDidEndZooming)
    {
        [self.delegate scrollViewDidEndZooming:scrollView withView:view atScale:scale];
    }
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView
{
    if (_gridFlags.delegateScrollViewShouldScrollToTop)
    {
        return [self.delegate scrollViewShouldScrollToTop:scrollView];
    }
    
    return YES;
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView
{
    if (_gridFlags.delegateScrollViewDidScrollToTop)
    {
        [self.delegate scrollViewDidScrollToTop:scrollView];
    }
}

#pragma mark - UIGestureRecognizer Delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return NO;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]] && [gestureRecognizer.view isKindOfClass:[RZGridViewCell class]])
    {
        @synchronized(self)
        {
            if (_gridFlags.dataSourceMoveItemAtIndexPathToIndexPath)
            {
                if (self.selectedCell == nil)
                {
                    self.selectedCell = (RZGridViewCell*)gestureRecognizer.view;
                    return YES;
                }
            }
            
            return NO;
        }
    }
    
    return YES;
}

@end


@implementation NSIndexPath (RZGridView)

+ (NSIndexPath *)indexPathForColumn:(NSUInteger)column andRow:(NSUInteger)row inSection:(NSUInteger)section
{
    NSUInteger indexes[3] = {section, row, column};
    
    return [NSIndexPath indexPathWithIndexes:indexes length:3];
}

- (NSUInteger)gridSection
{
    return [self indexAtPosition:0];
}

- (NSUInteger)gridRow
{
    return [self indexAtPosition:1];
}

- (NSUInteger)gridColumn
{
    return [self indexAtPosition:2];
}

@end