//
//  InputViewController.m
//  SpeakUp
//
//  Created by Adrian Holzer on 10.04.12.
//  Copyright (c) 2012 Adrian Holzer. All rights reserved.
//

#import "InputViewController.h"
#import "MessageTableViewController.h"
#import "SpeakUpManager.h"
#import "Message.h"

#define MAX_LENGTH 500

@implementation InputViewController


@synthesize input, characterCounterLabel, sendButton, noConnectionLabel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
   
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

        
    }
    return self;
}




- (void)viewWillAppear:(BOOL)animated{
    [noConnectionLabel setHidden:[[SpeakUpManager sharedSpeakUpManager] connectionIsOK]];
    [[SpeakUpManager sharedSpeakUpManager] setConnectionDelegate:self];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

-(void)connectionWasLost{
    noConnectionLabel.backgroundColor = [UIColor colorWithRed:238.0/255.0 green:0.0/255.0 blue:58.0/255.0 alpha:1.0];//dark red color
    [noConnectionLabel setText: @"CONNECTION LOST"];
    [noConnectionLabel setHidden:NO];
}
-(void)connectionHasRecovered{
    noConnectionLabel.backgroundColor = [UIColor colorWithRed:0.0/255.0 green:173.0/255.0 blue:121.0/255.0 alpha:1.0];//dark green color
    [noConnectionLabel setText: @"CONNECTION ESTABLISHED"];
    [noConnectionLabel performSelector:@selector(setHidden:) withObject:[NSNumber numberWithBool:YES] afterDelay:3.0];
}

#pragma mark - View lifecycle

/*
 // Implement loadView to create a view hierarchy programmatically, without using a nib.
 - (void)loadView
 {
 }
 */


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    [input becomeFirstResponder];
    input.text = [[SpeakUpManager sharedSpeakUpManager] inputText];
    
    int characterNumber = [[input text] length];

    
    [characterCounterLabel setText:[NSString stringWithFormat:@"%d / %d", characterNumber, MAX_LENGTH]];
    input.textInputView.layer.shadowColor =[[UIColor blackColor] CGColor];
    input.textInputView.layer.shadowRadius=2;
    input.textInputView.layer.cornerRadius=1;
    input.textInputView.layer.shadowOpacity=.5;
    input.textInputView.layer.shadowOffset = CGSizeMake(2.0, 2.0);
    
    [[SpeakUpManager sharedSpeakUpManager] setConnectionDelegate:self];
    // Custom initialization
    input.delegate=self;
    // BACK BUTTON START
    UIButton *newBackButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [newBackButton setImage:[UIImage imageNamed: @"button-back1.png"] forState:UIControlStateNormal];
    [newBackButton setImage:[UIImage imageNamed: @"button-back2.png"] forState:UIControlStateSelected];
    [newBackButton addTarget:self.navigationController action:@selector(popViewControllerAnimated:) forControlEvents:UIControlEventTouchUpInside];
    newBackButton.frame = CGRectMake(5, 5, 30, 30);
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:newBackButton];
    // BACK BUTTON END
    
    // SEND BUTTON START
    sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [sendButton setImage:[UIImage imageNamed: @"button-send1.png"] forState:UIControlStateNormal];
    [sendButton setImage:[UIImage imageNamed: @"button-send2.png"] forState:UIControlStateSelected];
    [sendButton addTarget:self action:@selector(sendInput:) forControlEvents:UIControlEventTouchUpInside];
    sendButton.frame = CGRectMake(5, 5, 30, 30);
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:sendButton];
    [sendButton setEnabled:NO];
    if(characterNumber>0){
        [sendButton setEnabled:YES];
    }
    // SEND BUTTON END
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    [[SpeakUpManager sharedSpeakUpManager] savePeerData];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)textViewDidChange:(UITextView *)textView
{
    int characterNumber = [[input text] length];
    [characterCounterLabel setText:[NSString stringWithFormat:@"%d / %d", characterNumber, MAX_LENGTH]];
    // update the input
    [[SpeakUpManager sharedSpeakUpManager] setInputText:input.text];
    [sendButton setEnabled:NO];
    if(characterNumber>0){
        [sendButton setEnabled:YES];
    }
}


// used to limit the number of characters to MAX_LENGTH
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    NSUInteger newLength = (textView.text.length - range.length) + text.length;
    if(newLength <= MAX_LENGTH)
    {
        return YES;
    }
    return NO;
    
}


-(IBAction)sendInput:(id)sender{
    if([[SpeakUpManager sharedSpeakUpManager] connectionIsOK]){
        // should send the message first
        if(![input.text isEqualToString:@""]){
            // create a new message
            Message *newMessage = [[Message alloc] init];
            newMessage.content= input.text;
            newMessage.roomID=[[[SpeakUpManager sharedSpeakUpManager] currentRoom] roomID];
            
            [[SpeakUpManager sharedSpeakUpManager] createMessage:newMessage];
            
            [input setText:@""];
            // goes back to the messages view
            [self.navigationController popViewControllerAnimated:YES];
            //update the input
            [[SpeakUpManager sharedSpeakUpManager] setInputText:input.text];
            [[SpeakUpManager sharedSpeakUpManager] savePeerData];
        }
    }
}

@end
