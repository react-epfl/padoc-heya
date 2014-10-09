//
//  MessageCell.m
//  SpeakUp
//
//  Created by Adrian Holzer on 13.07.13.
//  Copyright (c) 2013 Seance Association. All rights reserved.
//

#import "MessageCell.h"

@implementation MessageCell

@synthesize message;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
