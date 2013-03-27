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

#define MAX_LENGTH 160

@implementation InputViewController


@synthesize input, characterCounterLabel, room, sendButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        input.delegate=self;
        
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
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
    [sendButton setEnabled:NO];
    if(characterNumber>0){
        [sendButton setEnabled:YES];
    }
    
    [characterCounterLabel setText:[NSString stringWithFormat:@"%d / %d", characterNumber, MAX_LENGTH]];
    //input.textInputView.clipsToBounds=NO;
    input.textInputView.layer.shadowColor =[[UIColor blackColor] CGColor];
    input.textInputView.layer.shadowRadius=2;
    input.textInputView.layer.cornerRadius=5;
    input.textInputView.layer.shadowOpacity=.5;
    input.textInputView.layer.shadowOffset = CGSizeMake(2.0, 2.0);
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    [[SpeakUpManager sharedSpeakUpManager] savePeerData];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
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
    } else {
        // NSUInteger emptySpace = MAX_LENGTH - (textView.text.length - range.length);
        // textView.text = [[[textView.text substringToIndex:range.location]
        //  stringByAppendingString:[text substringToIndex:emptySpace]]
        // stringByAppendingString:[textView.text substringFromIndex:(range.location + range.length)]];
        return NO;
    }
}


-(IBAction)sendInput:(id)sender{
    // should send the message first
    if(![input.text isEqualToString:@""]){
        // create a new message
        Message *newMessage = [[Message alloc] init];
        newMessage.content= input.text;
        newMessage.roomID=room.roomID;
        
        int messageNumber= [[SpeakUpManager sharedSpeakUpManager] getNextMessageNumber];
        int peerID= [[[SpeakUpManager sharedSpeakUpManager] peerID] intValue] ;
        
        newMessage.messageID=[NSString stringWithFormat: @"peer%dmessage%d", peerID, messageNumber];
        
        [[SpeakUpManager sharedSpeakUpManager] createMessage:newMessage];
        
        [input setText:@""];
        // goes back to the messages view
        [self.navigationController popViewControllerAnimated:YES];
        //update the input
        [[SpeakUpManager sharedSpeakUpManager] setInputText:input.text];
        [[SpeakUpManager sharedSpeakUpManager] savePeerData];
    }
}

@end
