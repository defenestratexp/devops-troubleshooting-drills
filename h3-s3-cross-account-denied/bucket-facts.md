# What is true about the bucket

Established by inspection, not assumption:

    $ aws s3api get-bucket-encryption --bucket n9n-data-exchange
    SSEAlgorithm: aws:kms
    KMSMasterKeyID: arn:aws:kms:us-east-1:111122223333:key/8f3c1b2a-...

    $ aws s3api get-bucket-ownership-controls --bucket n9n-data-exchange
    ObjectOwnership: ObjectWriter

    $ aws s3api get-public-access-block --bucket n9n-data-exchange
    BlockPublicAcls: true
    IgnorePublicAcls: true

    $ aws s3api list-objects-v2 --bucket n9n-data-exchange --query 'Contents[].Key'
    [ "feeds/2026-10-12/orders.csv", "feeds/2026-10-12/returns.csv" ]

    # run as account A's own administrator:
    $ aws s3api get-object-acl --bucket n9n-data-exchange --key feeds/2026-10-12/orders.csv
    Owner:
      ID: 9e1f...   # account 777788889999, the upstream vendor that uploads the feed
    Grants: []

The vendor in account `777788889999` writes the feed files with a plain
`aws s3 cp`. Account A owns the bucket. Account B is trying to read.
