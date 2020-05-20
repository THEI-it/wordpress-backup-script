#!/bin/bash

echo ""

# VAR - EDIT HERE: PUT YOUR WORDPRESS DIRECTORY HERE
WP_DIR=/path/to/wordpress-dir
BUCKET_S3=your-s3-bucket-name

# CHECK FOR WP-CONFIG.PHP
if [ ! -d ${WP_DIR} ]; then
  echo "[+] ERROR: Directory ${WP_DIR} does not exist"
  echo ""
  exit
fi
if [ ! -f ${WP_DIR}/wp-config.php ]; then
  echo "[+] ERROR: No wp-config.php in ${WP_DIR}"
  echo ""
  exit
fi

# GREP WHAT WE NEED, PRINT ONLY THE VALUE
DB_HOST=$(cat ${WP_DIR}/wp-config.php | grep DB_HOST | awk '{ print $3 }')
DB_USER=$(cat ${WP_DIR}/wp-config.php | grep DB_USER | awk '{ print $3 }')
DB_PASS=$(cat ${WP_DIR}/wp-config.php | grep DB_PASSWORD | awk '{ print $3 }')
DB_NAME=$(cat ${WP_DIR}/wp-config.php | grep DB_NAME | awk '{ print $3 }')

# REMOVING QUOTES FROM VARIABLES
DB_HOST=${DB_HOST:1:-1}
DB_USER=${DB_USER:1:-1}
DB_PASS=${DB_PASS:1:-1}
DB_NAME=${DB_NAME:1:-1}

# DUMP OF WP DATABASE
echo "[+] Creating Database dump..."
mysqldump --user=${DB_USER} --password=${DB_PASS} --host=${DB_HOST} --databases ${DB_NAME} > wp_db_backup.sql

# CREATE TAR WITH THE TWO BZIPPED FILES
echo "[+] bzip2 running on wordpress directory and database file..."
cp -R ${WP_DIR} wp_html_files
tar cf wp_backup.tgz -j wp_html_files wp_db_backup.sql

# RENAMING TAR FILE
CURRENT_DATE=$(date +"%Y%m%d")
NEW_TAR_NAME=wp_backup_${CURRENT_DATE}.tgz
mv wp_backup.tgz ${NEW_TAR_NAME}

# UPLOADING TAR TO AWS S3
echo "[+] Uploading tar to S3..."
s3cmd --storage-class=STANDARD_IA put ${NEW_TAR_NAME} s3://${BUCKET_S3}/

# REMOVING LOCAL FILES
echo "[+] Removing local files..."
rm -rf wp_db_backup.sql wp_html_files ${NEW_TAR_NAME}

echo "[+] Finish!"
echo ""
