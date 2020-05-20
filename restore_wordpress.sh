#!/bin/bash

echo ""

# INPUT
echo "Restore Wordpress backup"
echo -n "Insert backup's date you want to restore (format DD/MM/YYYY): "
read BACKUP_DATE
YEAR=$(echo ${BACKUP_DATE} | awk -F '/' '{ print $3 }')
MONTH=$(echo ${BACKUP_DATE} | awk -F '/' '{ print $2 }')
DAY=$(echo ${BACKUP_DATE} | awk -F '/' '{ print $1 }')
SELECTED_DATE=${YEAR}${MONTH}${DAY}

# VARS - EDIT HERE: PUT YOUR WORDPRESS DIRECTORY HERE
WP_DIR=/path/to/wordpress-dir
BUCKET_S3=your-s3-bucket-name

# PREPARE ENVIRONMENT
mkdir $PWD/.restoring_wordpress_temp
cd $PWD/.restoring_wordpress_temp

# DOWNLOADING TAR FROM AWS S3
echo "[+] Downloading tar from S3..."
s3cmd get s3://${BUCKET_S3}/wp_backup_${SELECTED_DATE}.tgz > /dev/null
tar xf wp_backup_${SELECTED_DATE}.tgz

# GREP WHAT WE NEED, PRINT ONLY THE VALUE
BCK_WP_DIR=$PWD/wp_html_files
DB_HOST=$(cat ${BCK_WP_DIR}/wp-config.php | grep DB_HOST | awk '{ print $3 }')
DB_USER=$(cat ${BCK_WP_DIR}/wp-config.php | grep DB_USER | awk '{ print $3 }')
DB_PASS=$(cat ${BCK_WP_DIR}/wp-config.php | grep DB_PASSWORD | awk '{ print $3 }')
DB_NAME=$(cat ${BCK_WP_DIR}/wp-config.php | grep DB_NAME | awk '{ print $3 }')

# REMOVING QUOTES FROM VARIABLES
DB_HOST=${DB_HOST:1:-1}
DB_USER=${DB_USER:1:-1}
DB_PASS=${DB_PASS:1:-1}
DB_NAME=${DB_NAME:1:-1}

# RESTORE BACKUP
echo "[+] Restoring Database..."
mysql --user=${DB_USER} --password=${DB_PASS} --host=${DB_HOST} --database=${DB_NAME} < wp_db_backup.sql
rm -rf ${WP_DIR}/*
cp -R ${BCK_WP_DIR}/* ${WP_DIR}/

# REMOVING LOCAL FILES
echo "[+] Removing local files..."
cd ..
rm -rf $PWD/.restoring_wordpress_temp

echo "[+] Finish!"
echo ""
