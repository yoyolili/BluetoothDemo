//
//  QYBTPeripheralVC.m
//  01-CoreBluetoothDemo
//
//  Created by qingyun on 15/12/22.
//  Copyright © 2015年 qingyun. All rights reserved.
//

#import "QYBTPeripheralVC.h"

@interface QYBTPeripheralVC () <UITextViewDelegate>
@property (weak, nonatomic) IBOutlet UITextView *textView;

@end

@implementation QYBTPeripheralVC

#pragma mark - view life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
}

#pragma mark - setters & getters



#pragma mark - text view delegate
- (void)textViewDidBeginEditing:(UITextView *)textView {
    UIBarButtonItem *rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"完成" style:UIBarButtonItemStyleDone target:self action:@selector(dismissKeyboard)];
    self.navigationItem.rightBarButtonItem = rightBarButtonItem;
}

#pragma mark - events handling
- (void)dismissKeyboard {
    self.navigationItem.rightBarButtonItem = nil;
    [_textView resignFirstResponder];
}

- (IBAction)advertising:(id)sender {
    
}


@end
