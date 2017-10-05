To add an user to aws-vault, execute the following:
$ aws-vault add user1-billing


To login as that user, execute:
$ aws-vault exec user1-billing -- 

To assume an IAM Role, execute:
$ aws-vault exec user1-billing-assumerole-create_delete_account -- 