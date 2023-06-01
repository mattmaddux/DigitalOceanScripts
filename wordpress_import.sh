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
TMP_CONFIG_FILE="$TMP_DIR/app/public/wp-config.php"

cd $WP_DIR
DOMAIN_FULL=$(wp option get siteurl)
DOMAIN=$(echo $DOMAIN_FULL | sed -E 's/^\s*.*:\/\///g')
read -p 'WP Export Zip Path: ' WP_ZIP_PATH

if [ -f $WP_ZIP_PATH ]; then
    echo "File found"
else
    echo "No such file: $WP_ZIP_PATH"
    exit 1
fi


echo "##### Installing Tools"
sudo apt-get install unzip jq -y  2>> $LOG_FILE >> $LOG_FILE


echo "##### Decompressing WP Export"
mkdir "$TMP_DIR"
unzip $WP_ZIP_PATH -d $TMP_DIR  2>> $LOG_FILE >> $LOG_FILE


echo "##### Checking WP Prefix"
IMPORT_PREFIX=$(grep "\$table_prefix" "$TMP_CONFIG_FILE" | head -1 | grep -Eo "wp_.*_")
if [ $IMPORT_PREFIX == "wp_" ]; then
    echo "Prefix is standard"
else
    echo "Non-standard prefix found: $IMPORT_PREFIX"
    echo "Updating to standard prefix: $WP_PREFIX"
    sed -i "s/$IMPORT_PREFIX/$WP_PREFIX/g" $TMP_DB_FILE  2>> $LOG_FILE >> $LOG_FILE
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
echo wp search-replace "$IMPORTED_DOMAIN" "$DOMAIN"
wp search-replace "$IMPORTED_DOMAIN" "$DOMAIN" 2>> $LOG_FILE >> $LOG_FILE


echo "##### Cleaning Up"
sudo rm -rf $TMP_DIR
sudo rm -rf $WP_ZIP_PATH

echo "##### Done"


