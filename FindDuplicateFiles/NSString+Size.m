//
//  NSString+Size.m
//  randomTest
//
//  Created by TanHao on 12-9-24.
//  Copyright (c) 2012年 tanhao.me. All rights reserved.
//

#import "NSString+Size.h"

@implementation NSString(Size)

static NSString* sizeUnit[]={@"KB",@"MB",@"GB",@"TB"};

+ (NSString *)stringWithSize:(uint64_t)size
{
    double value = size;
    int unitIdx = 0;
    
    value /= 1024;
    while (value > 1000.0f && unitIdx+1<sizeof(sizeUnit)/sizeof(sizeUnit[0]))
    {
        value /= 1024;
        unitIdx++;
    }
    
    if (value < 10)
    {
        return [NSString stringWithFormat:@"%.2f %@",value,sizeUnit[unitIdx]];
    }else if (value < 100)
    {
        return [NSString stringWithFormat:@"%.1f %@",value,sizeUnit[unitIdx]];
    }else
    {
        return [NSString stringWithFormat:@"%.0f %@",value,sizeUnit[unitIdx]];
    }
}

+ (NSString *)stringWithDiskSize:(uint64_t)size
{
    double value = size;
    int unitIdx = 0;
    
    value /= 1000;
    while (value > 1000.0f && unitIdx+1<sizeof(sizeUnit)/sizeof(sizeUnit[0]))
    {
        value /= 1000;
        unitIdx++;
    }
    
    if (value < 10)
    {
        return [NSString stringWithFormat:@"%.2f %@",value,sizeUnit[unitIdx]];
    }else if (value < 100)
    {
        return [NSString stringWithFormat:@"%.1f %@",value,sizeUnit[unitIdx]];
    }else
    {
        return [NSString stringWithFormat:@"%.0f %@",value,sizeUnit[unitIdx]];
    }
}

@end
