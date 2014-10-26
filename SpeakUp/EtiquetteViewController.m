//
//  EtiquetteViewController.m
//  SpeakUp
//
//  Created by Adrian Holzer on 20.10.14.
//  Copyright (c) 2014 Adrian Holzer. All rights reserved.
//

#import "EtiquetteViewController.h"
#import "SpeakUpManager.h"

@interface EtiquetteViewController ()

@end

@implementation EtiquetteViewController

@synthesize etiquetteLabel, agreeButton;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    if ([[[SpeakUpManager sharedSpeakUpManager] etiquetteType] isEqual:ETIQUETTE_PRESENT]){
       etiquetteLabel.text = NSLocalizedString(@"ETIQUETTE_PRESENT", nil);
    }else{
        etiquetteLabel.text = NSLocalizedString(@"ETIQUETTE_FUTURE", nil);
    }
    agreeButton.titleLabel.text=NSLocalizedString(@"OK", nil);
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)pressAgree:(id)sender{
      [super dismissViewControllerAnimated:YES completion:nil];
}

@end
