# install awscli
apt install awscli

# set credential
aws configure

# check all buckets
aws s3 ls

# check objects in bucket
aws s3 ls s3://your-bucket-name

# move all files from one folder to another inside one bucket
aws s3 mv s3://bucket-name/source-folder/ s3://bucket-name/destination-folder/ --recursive

# create folder
aws s3api put-object --bucket your-bucket-name --key folder-name/
aws s3api put-object --bucket your-bucket-name --key folder-name/new-folder-name/

# delete folder
aws s3 rm s3://your-bucket-name/folder-name/

# check acl
aws s3api get-bucket-acl --bucket your-bucket-name

# copy file to local linux
aws s3 cp s3://mybucket/myfile ./myfile

# get size of all files 
aws s3 ls --summarize --human-readable --recursive s3://bucket-name/folder-name/
# get size only inside folder
aws s3 ls --summarize --human-readable --recursive s3://bucket-name/folder-name/ | grep -E 'Total Size' | awk '{print $3, $4}'
# count quantity of all files inside folder
aws s3 ls s3://bucket-name/folder-name/ --recursive | wc -l

# get names of all files inside folder
aws s3 ls s3://bucket-name/folder-name/ | awk '{if($2) print $2}'


# Function to get the names of files to copy from the S3 bucket
get_files_to_copy_from_s3() {
    file_prefix=$1
    target_date=$2
    local s3_path="s3://$S3_BUCKET/$MAIN_FOLDER_PATH/$INCOME_FOLDER/"
    local files=$(aws s3 ls "$s3_path" | awk '{print $4}')

    if [[ $? -ne 0 ]]; then
        send_notification "<ERROR> Failed to list files from $s3_path"
        exit 1
    fi

    if [[ -n "$file_prefix" || -n "$target_date" ]]; then
        printf "%s\n" "$files" | grep "${file_prefix}.*${target_date}"
    else
        printf "%s\n" "$files"
    fi
}
FILES_FROM_S3=$(get_files_to_copy_from_s3 file_prefix target_date)
