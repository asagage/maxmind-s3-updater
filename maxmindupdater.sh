#!/bin/sh

# maxmind-s3-updater
# - Uploads latest maxmind databases to an s3 bucket.
# - You can run this script in an AWS DataPipeline to update a bucket with latest maxmind files on a schedule.

#requires wget and aws-cli

#set these to match your env

AWS_ACCESS_KEY_ID=""
AWS_SECRET_ACCESS_KEY=""
AWS_DEFAULT_REGION="us-east-1"
MAXMIND_LICENSE_KEY=""

#example DEST_BUCKET_PATH="s3://my-proprietary-assets/third-party/com.maxmind/"
DEST_BUCKET_PATH=""

#Product IDs are in the download URL in maxmind web portal
# * 173 - GeoIPDomain.dat
# * 121 - GeoIPISP.dat
# * 111 - GeoIPOrg.dat
MAXMIND_PRODUCT_IDS=("173" "121" "111")

#SNS notification topic ARN
#SNS_NOTIFICATION_TOPIC="arn:aws:sns:us-west-2:123456789012:MyTopic"
SNS_NOTIFICATION_TOPIC=""

#script starts below
export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
export AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION

for i in "${MAXMIND_PRODUCT_IDS[@]}"
do
   wget --content-disposition "https://www.maxmind.com/app/geoip_download?edition_id=$i&suffix=tar.gz&license_key=$MAXMIND_LICENSE_KEY"
done

#create the databases dir if it doesn't exist
mkdir -p databases

#extracts the tar files into the databases directory 
find . -name '*.tar.gz' -print0 | xargs -0 -I {} tar -zxvf {} --strip-components=1 -C databases --exclude=README.txt

#remove the source files
rm -f *.tar.gz 

#sync to aws bucket
aws s3 sync databases $DEST_BUCKET_PATH

#send SNS notification
aws sns publish --topic-arn $SNS_NOTIFICATION_TOPIC --message "Naxmind update complete!"

exit 0
