//
//  EtiquetteViewController.h
//  SpeakUp
//
//  Created by Adrian Holzer on 20.10.14.
//  Copyright (c) 2014 Adrian Holzer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EtiquetteViewController : UIViewController


@property(strong, nonatomic) IBOutlet UITextView * etiquetteLabel;
@property(strong, nonatomic) IBOutlet UIButton * agreeButton;

-(IBAction)pressAgree:(id)sender;


@end
