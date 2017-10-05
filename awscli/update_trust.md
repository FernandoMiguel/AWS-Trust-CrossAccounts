$ aws iam get-role --role-name OrganizationAccountAccessRole | tee /tmp/Role-Trust-Policy.json
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


Edit the file to add the ARN of the IAM account
json file should look like
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

Then run the following to update the policy:
$ aws iam update-assume-role-policy --role-name OrganizationAccountAccessRole --policy-document file:///tmp/Role-Trust-Policy.json
