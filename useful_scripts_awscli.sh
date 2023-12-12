# install awscli
apt install awscli

# set credential
aws configure

# check all buckets
aws s3 ls

# check objects in bucket
aws s3 ls s3://your-bucket-name

# create folder
aws s3api put-object --bucket your-bucket-name --key folder-name/
aws s3api put-object --bucket your-bucket-name --key folder-name/new-folder-name/

# delete folder
aws s3 rm s3://your-bucket-name/folder-name/

# check acl
aws s3api get-bucket-acl --bucket your-bucket-name

# get size of folder
aws s3 ls --summarize --human-readable --recursive s3://bucket-name/folder-name/ | grep -E 'Total Size' | awk '{print $3, $4}'
