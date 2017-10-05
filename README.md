# AWS-Trust-CrossAccounts

Examples for establishing Cross Account Trust relationship on AWS


## Introduction

This documentation is aimed at allowing AWS account managers to setup new AWS accounts under AWS Organizations, using AWS CLI or Terraform.
Following best pratices, we will create an IAM account to manage all user logins and permitions.
All other accounts will then have their Trust relationship be modified to include the IAM account id. 


### Account limit

Given that by default new Billing accounts have a soft limit of one subccount, you will be required to create a ticket with AWS Support to increase account limit.
Visit https://console.aws.amazon.com/support/home?/case/create and submit a ticket for Organizations and increase the limit to the number you feel comfortable to use the future.


## Prepare Billing Account

Following best pratices, we will create an IAM user in the  Billing account. This user will have an MFA token attached to their account, no permitions, and be part of a Group.
That group will have two policies attached to it.
One policy will be used to allow the users that are part of this group to Assume a Role, giving them specific privileges.
The other policy grants these users to Assume a Role in other accounts.
For simplicity, we wiil be using the default cross account Role name 'OrganizationAccountAccessRole'.
This means, a web console user can login into another account by using the following URL and replacing 'IAM_ACCOUNTID' with the account id or its custom name. 
https://signin.aws.amazon.com/switchrole?roleName=OrganizationAccountAccessRole&account=IAM_ACCOUNTID