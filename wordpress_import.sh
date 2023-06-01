#!/bin/bash

##
## USAGE
## bash <(curl -s https://raw.githubusercontent.com/mattmaddux/DigitalOceanScripts/main/wordpress_import.sh)
##


echo "##### Getting Configuration & Generating Values"

WP_DIR="/var/www/wordpress"
LOG_FILE=$HOME/wp_import.log
WP_PREFIX="wp_"
TMP_DIR="/tmp/wp"
TMP_DB_FILE="$TMP_DIR/app/sql/local.sql"
TMP_CONTENT_DIR="$TMP_DIR/app/public/wp-content"

cd $WP_DIR
DOMAIN_FULL=$(wp option get siteurl)
DOMAIN=$(echo $DOMAIN_FULL | sed -E 's/^\s*.*:\/\///g')
read -p 'WP Export Zip Path: ' WP_ZIP_PATH


echo "##### Installing Tools"
sudo apt-get install unzip jq -y  2>> $LOG_FILE >> $LOG_FILE


echo "##### Decompressing WP Export"
mkdir "$TMP_DIR"
unzip $WP_ZIP_PATH -d $TMP_DIR  2>> $LOG_FILE >> $LOG_FILE


echo "##### Checking WP Prefix"
USES_STANDARD_PREFIX=$(grep 'wp_users' "$TMP_DB_FILE" | tail -1)
if [ -z "$USES_STANDARD_PREFIX" ]; then
    PREFIX_ORIG=$(grep -Eo 'wp_[^_]*_' "$TMP_DB_FILE" | head -1)
    echo "Non-standard prefix found: $PREFIX_ORIG"
    echo "Updating to standard prefix: $WP_PREFIX"
    sed -i "s/$PREFIX_ORIG/$WP_PREFIX/g" $TMP_DB_FILE  2>> $LOG_FILE >> $LOG_FILE
else
    echo "Prefix is standard"
fi


echo "##### Importing Database"
wp db reset --yes  2>> $LOG_FILE >> $LOG_FILE
wp db import $TMP_DB_FILE  2>> $LOG_FILE >> $LOG_FILE


echo "##### Importing Content"
sudo rm -rf $WP_DIR/wp-content
sudo mv $TMP_CONTENT_DIR $WP_DIR/wp-content
sudo chown www-data:www-data -R $WP_DIR/wp-content
sudo chmod 755 -R $WP_DIR/wp-content


echo "##### Updating Domain"
IMPORTED_DOMAIN=$(jq -r '.domain' $TMP_DIR/local-site.json)
IMPORTED_NAME=$(jq -r '.name' $TMP_DIR/local-site.json)
echo "Imported Site Name: $IMPORTED_NAME"
echo "Imported Site URL: $IMPORTED_DOMAIN"
echo "Correct Domain: $DOMAIN"
wp search-replace '$IMPORTED_DOMAIN' '$DOMAIN' 2>> $LOG_FILE >> $LOG_FILE
wp option set siteurl $DOMAIN 2>> $LOG_FILE >> $LOG_FILE
wp option set home $DOMAIN 2>> $LOG_FILE >> $LOG_FILE


echo "##### Cleaning Up"
sudo rm -rf $TMP_DIR
sudo rm -rf $WP_ZIP_PATH

echo "##### Done"
