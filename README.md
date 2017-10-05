# AWS-Trust-CrossAccounts
**Examples for establishing Cross Account Trust relationship on AWS**

***

<!-- TOC -->

- [AWS-Trust-CrossAccounts](#aws-trust-crossaccounts)
    - [Introduction](#introduction)
        - [Account limit](#account-limit)
    - [Prepare Billing Account](#prepare-billing-account)
        - [Policy: group_orgs_crossaccount](#policy-group_orgs_crossaccount)
            - [Description](#description)
        - [Policy: group_create_aws_accounts](#policy-group_create_aws_accounts)
            - [Description](#description-1)
        - [Role: assumerole_create_account](#role-assumerole_create_account)
            - [Description](#description-2)
        - [Policy: role_create_accounts](#policy-role_create_accounts)
            - [Description](#description-3)
    - [aws-vault setup](#aws-vault-setup)
        - [awscli config](#awscli-config)
        - [aws-vault profiles](#aws-vault-profiles)
            - [Add profile](#add-profile)
            - [Login](#login)
            - [Assume a Role](#assume-a-role)
    - [Command line](#command-line)
        - [IAM account](#iam-account)
            - [More AWS Accounts](#more-aws-accounts)
        - [Add Trust](#add-trust)
            - [Read Trust policy](#read-trust-policy)
            - [Update Trust policy](#update-trust-policy)

<!-- /TOC -->

## Introduction
This documentation is aimed at allowing AWS account managers to setup new [AWS accounts](https://aws.amazon.com/account/) under [AWS Organizations](https://aws.amazon.com/organizations/), using [AWS CLI](https://aws.amazon.com/cli/) or [Terraform](https://www.terraform.io/).

Following [best practices](https://aws.amazon.com/whitepapers/aws-security-best-practices/), we will create an [IAM account](https://docs.aws.amazon.com/IAM/latest/UserGuide/introduction.html) to manage all user logins and permissions.

All other accounts will then have their [Trust Relationship](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_terms-and-concepts.html) be modified to include the IAM account id. 


### Account limit
Given that by default new Billing accounts have a soft limit of one sub-account, you will be required to create a ticket with AWS Support to increase account limit.

Visit https://console.aws.amazon.com/support/home?/case/create and submit a ticket for Organizations and increase the limit to the number you feel comfortable to use the future.


## Prepare Billing Account
Following best practices, we will create an IAM user in the  Billing account. This user will have an [MFA token](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_mfa_enable.html) attached to their account, no permissions, and be part of a Group.

That Group will have two policies attached to it.

One policy ([group_orgs_crossaccount](/policy/group_orgs_crossaccount.json)) will be used to allow the users that are part of this group to Assume a Role, giving them specific privileges.

The other policy ([group_create_aws_accounts](/policy/group_create_aws_accounts.json)) grants these users to Assume a Role in other accounts.


### Policy: group_orgs_crossaccount

#### Description
This policy Grants resources to access the Role _OrganizationAccountAccessRole_ in other accounts.

This policy is to be added to an IAM group.


For simplicity, we will be using the default cross account Role name _OrganizationAccountAccessRole_.

This means, a web console user can login into another account by using the following URL and replacing _IAM_ACCOUNTID_ with the account id or its custom name. 

https://signin.aws.amazon.com/switchrole?roleName=OrganizationAccountAccessRole&account=IAM_ACCOUNTID


### Policy: group_create_aws_accounts

#### Description
This policy allows a resource to assume the Role _assumerole_create_account_.

This policy is to be added to an IAM group.


### Role: assumerole_create_account

#### Description
This role is assumed by an user, grating privileges to create AWS Orgs accounts via policy [role_create_accounts](/policy/role_create_accounts.json)

Create an IAM Role using the Billing Account ID as the trust relationship

Give the following URL to users who can switch roles in the console, replacing _IAM_ACCOUNTID_ with the Billing account id or its custom name.

https://signin.aws.amazon.com/switchrole?roleName=assumerole-create_account&account=BILLING_ACCOUNTID


### Policy: role_create_accounts

#### Description
Allow user to create AWS Org accounts

This policy is to be added to an IAM Role that will grant privileges to Create AWS Organizations accounts under the Billing account.


## aws-vault setup
Now that you have an IAM user and their API keys, we will follow with configuring [aws-vault](https://github.com/99designs/aws-vault) to securely access the AWS API using [STS](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp.html) (short time lived tokens).

This authentication system will allow us to use both AWS CLI and Terraform (or any other API tool).

### awscli config
AWS cli tools allows users to create config file that will contain all users, their MFA tokens, specific region for each profile, the assumed role.

We can create nested profiles, sharing the same login, and change only the role or region.

[A sample file can be found here](/dot_aws/config)

It should be placed in the user ```$HOME/.aws/config``` path.

Replace _ACCOUNTID_ with your actual account IDs.


### aws-vault profiles

#### Add profile
To add an user to aws-vault, execute the following:
```
$ aws-vault add user1-billing
```
and enter the API credentials for the IAM user you created in the Billing account.

the profile name should match the ones in the aws config file.

#### Login
To login as that profile, execute:
```
$ aws-vault exec user1-billing -- 
```

#### Assume a Role
To assume an IAM Role, execute:
```
$ aws-vault exec user1-billing-assumerole-create_account --
```

## Command line
Now that we have the policies and roles in place in the Billing account, and one user setup to access the AWS accounts, we shall proceed to create the new IAM account and further working accounts.

The IAM account is used to manage all AWS users (Web console or API), the roles they will assume for other accounts, and the passwords and key policies.

### IAM account
To create a new account via AWS CLI, authenticate with aws-vault and execute the following command:
```
$ aws organizations create-account --email awsops+IAM@company.tld --account-name IAM --iam-user-access-to-billing ALLOW 
```

#### More AWS Accounts
Repeat as many times required to create all further accounts:
```
$ aws organizations create-account --email awsops+ACCOUNT0X@company.tld --account-name ACCOUNT0X --iam-user-access-to-billing ALLOW 
```

### Add Trust
The next step is add a Trust Relationship between the IAM account and the new accounts, so that your users can assume a cross account role.

#### Read Trust policy
Execute the following to download the existing Trust policy from **at least one** of the new accountd you created after the IAM account:
```
$ aws iam get-role --role-name OrganizationAccountAccessRole | tee /tmp/Role-Trust-Policy.json
```

The output should be exactly the same for all, and it will list the _Principal_ being the Billing Account:
```
{
    "Role": {
        "Path": "/",
        "RoleName": "OrganizationAccountAccessRole",
        "RoleId": "XXXX",
        "Arn": "arn:aws:iam::ACCOUNT02:role/OrganizationAccountAccessRole",
        "CreateDate": "2017-10-05T18:59:29Z",
        "AssumeRolePolicyDocument": {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Principal": {
                        "AWS": "arn:aws:iam::BILLING_ACCOUNTID:root"
                    },
                    "Action": "sts:AssumeRole"
                }
            ]
        }
    }
}
```

#### Update Trust policy
Edit the file to add the ARN of the IAM account

The json file should look like
```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::BILLING_ACCOUNTID:root",
          "arn:aws:iam::IAM_ACCOUNTID:root"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```
Then run the following to update the policy:
```
$ aws iam update-assume-role-policy --role-name OrganizationAccountAccessRole --policy-document file:///tmp/Role-Trust-Policy.json
```
Remember to switch between all new accounts so that the policy is added to all.