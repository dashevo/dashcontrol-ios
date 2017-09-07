//
//  ProposalDetailOneTimePayementTableViewCell.h
//  DashControl
//
//  Created by Manuel Boyer on 05/09/2017.
//  Copyright © 2017 dashfoundation. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ProposalDetailOneTimePayementTableViewCell : UITableViewCell

@property (nonatomic, retain) Proposal *currentProposal;

@property (strong, nonatomic) IBOutlet UILabel *labelOneTimePayment;
@property (strong, nonatomic) IBOutlet UILabel *labelOneTimePaymentDetail;

-(void)configureWithProposal:(Proposal*)proposal;

@end