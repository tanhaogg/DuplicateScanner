//
//  THDuplicateCell.h
//  FindDuplicateFiles
//
//  Created by TanHao on 12-11-10.
//  Copyright (c) 2012年 tanhao.me. All rights reserved.
//

#import "PXListViewCell.h"
#import "THStaticTextField.h"

#define kTHDuplicateCellMinSize (NSMakeSize(400, 40))
#define kTHPathViewHeight (20)

@protocol THDuplicateCellDelegate;
@interface THDuplicateCell : PXListViewCell
{
    NSImageView *iconView;
    THStaticTextField *sizeField;
    NSMutableArray *viewItemList;
}
@property (nonatomic,unsafe_unretained) id delegate;
@property (nonatomic,strong) NSArray *fileLists;
@property (nonatomic,assign) uint64 fileSize;

@end

@protocol THDuplicateCellDelegate <NSObject>

- (void)cellOpenClick:(THDuplicateCell *)cell index:(NSInteger)index;
- (void)cellRemoveClick:(THDuplicateCell *)cell index:(NSInteger)index;

@end