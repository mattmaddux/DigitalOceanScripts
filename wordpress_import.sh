#!/bin/bash

echo "##### Getting Configuration & Generating Values"

read -p 'WP Export Zip Path: ' WP_ZIP_PATH

LOG_FILE=$HOME/wp_import.log
DOMAIN=$(wp option get siterul)
DOMAIN_TRIMMED=$(echo $DOMAIN | sed -E 's/^\s*.*:\/\///g')
WP_PREFIX="wp_"
WP_DIR="/var/www/wordpress"
TMP_DIR="/tmp/wp"
TMP_DB_FILE="$TMP_DIR/app/sql/local.sql"
TMP_CONTENT_DIR="$TMP_DIR/app/public/wp-content"


echo "##### Decompressing WP Export"
mkdir "$TMP_DIR"
sudo apt-get install unzip -y  2>> $LOG_FILE >> $LOG_FILE
unzip $WP_ZIP_PATH -d $TMP_DIR  2>> $LOG_FILE >> $LOG_FILE

echo "##### Importing Database"
STANDARD_PREFIX=$(grep 'wp_users' "$TMP_DB_FILE" | tail -1)
echo "##### Checking WP Prefix"
if [ -z "$STANDARD_PREFIX" ]; then
    PREFIX_ORIG=$(grep -Eo 'wp_[^_]*_' "$TMP_DB_FILE" | head -1)
    echo "Non standard prefix found: $PREFIX_ORIG"
    echo "Upddang to standard prefix: $WP_PREFIX"
    sed -i "s/$PREFIX_ORIG/$WP_PREFIX/g" $TMP_DB_FILE  2>> $LOG_FILE >> $LOG_FILE
else
    echo "Prefix is standard"
fi

cd $WP_DIR
wp db reset --yes  2>> $LOG_FILE >> $LOG_FILE
wp db import $TMP_DB_FILE  2>> $LOG_FILE >> $LOG_FILE


echo "##### Importing Content"
sudo rm -rf $WP_DIR/wp-content
sudo mv $TMP_CONTENT_DIR $WP_DIR/wp-content
sudo chown www-data:www-data -R $WP_DIR/wp-content
sudo chmod 755 -R $WP_DIR/wp-content

echo "##### Updating Domain"
IMPORTED_DOMAIN=$(wp option get siteurl)
IMPORTED_DOMAIN_TRIMMED=$(echo $DOMAIN | sed -E 's/^\s*.*:\/\///g')
wp search-replace '$IMPORTED_DOMAIN_TRIMMED' '$DOMAIN_TRIMMED' 2>> $LOG_FILE >> $LOG_FILE
wp option set siteurl $DOMAIN 2>> $LOG_FILE >> $LOG_FILE
wp option set home $DOMAIN 2>> $LOG_FILE >> $LOG_FILE


echo "##### Cleaning Up"
sudo rm -rf $TMP_DIR
sudo rm -rf $WP_ZIP_PATH

echo "##### Done"
