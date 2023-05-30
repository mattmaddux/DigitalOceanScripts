#!/bin/bash

##
## USAGE
## bash <(curl -s https://raw.githubusercontent.com/mattmaddux/DigitalOceanScripts/main/wordpress_install.sh)
##

function yesNoPrompt {
	local RESULT
	while true; do

	read -p "$1 (y/n) " yn

	case $yn in 
		[yY] ) echo true;
			break;;
		[nN] ) echo false;
			exit;;
		* ) echo invalid response;;
	esac

	done
	
	echo $RESULT
}

echo "##### Configuring Generating Values #####"

read -p 'Domain Name: ' DOMAIN
WWW_SUBDOMAIN=$(yesNoPrompt "Do you want to also add a 'www' subdomain for your domain?")
read -p 'Site Name: ' SITE_NAME
read -p 'Wordpress User: ' WP_USER
read -p 'Your Email: ' WP_USER_EMAIL
PHP_VER=$(yesNoPrompt "Install PHP 8? (No for PHP 7.4)")


echo "##### Generating Values #####"
WP_DIR="/var/www/wordpress"
DB_ROOT_PASS=$(openssl rand -base64 36)
DB_NAME="wordpress"
DB_USER="wordpress"
DB_USER_PASS=$(openssl rand -base64 36)
WP_USER_PASS=$(openssl rand -base64 36)
LOG_FILE="$HOME/wp_install.log"
echo -e "Domain: $DOMAIN
WWW Add: $WWW_SUBDOMAIN
DB Root Pass: $DB_ROOT_PASS
DB User: $DB_USER
DB User Pass: $DB_USER_PASS
WP User Email: $WP_USER_EMAIL
WP User Name: $WP_USER
WP User Pass: $WP_USER_PASS" >> $HOME/secrets.txt


echo "##### Installing Apache & Updating Firewall ####"
sudo apt-get install apache2 -y >> $LOG_FILE
sudo ufw allow "Apache Full" >> $LOG_FILE
sudo systemctl stop apache2 >> $LOG_FILE
sudo a2enmod rewrite >> $LOG_FILE
echo -e "\nServerName localhost" | sudo tee -a /etc/apache2/apache2.conf >> $LOG_FILE

if [ $WWW_SUBDOMAIN == true ]; then	
	APACHE_CONFIG="
<VirtualHost *:80>
	ServerName $DOMAIN
	ServerAlias www.$DOMAIN
	ServerAdmin webmaster@localhost
	DocumentRoot /var/www/wordpress
	ErrorLog ${APACHE_LOG_DIR}/error.log
	CustomLog ${APACHE_LOG_DIR}/access.log combined
	<Directory /var/www/wordpress/>
		AllowOverride All
	</Directory>
</VirtualHost>"
else
APACHE_CONFIG="
<VirtualHost *:80>
	ServerName $DOMAIN
	ServerAdmin webmaster@localhost
	DocumentRoot /var/www/wordpress
	ErrorLog ${APACHE_LOG_DIR}/error.log
	CustomLog ${APACHE_LOG_DIR}/access.log combined
	<Directory /var/www/wordpress/>
		AllowOverride All
	</Directory>
</VirtualHost>"
fi

echo "$APACHE_CONFIG" | sudo tee /etc/apache2/sites-available/$DOMAIN.conf >> $LOG_FILE
sudo a2dissite 000-default >> $LOG_FILE
sudo a2ensite $DOMAIN >> $LOG_FILE


echo "##### Installing & Configuring MySQL #####"
sudo apt-get install mysql-server -y >> $LOG_FILE
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$DB_ROOT_PASS'" >> $LOG_FILE																# Set root password
mysql --password="$DB_ROOT_PASS" --user=root -e "DELETE FROM mysql.user WHERE User=''" 2>> $LOG_FILE >> $LOG_FILE																# Remove anonymous users
mysql --password="$DB_ROOT_PASS" --user=root -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')" 2>> $LOG_FILE >> $LOG_FILE			# Disallow remote root login
mysql --password="$DB_ROOT_PASS" --user=root -e "CREATE USER '$DB_USER' IDENTIFIED WITH mysql_native_password BY '$DB_USER_PASS'"  2>> $LOG_FILE >> $LOG_FILE				# Create wordpress db user
mysql -e "FLUSH PRIVILEGES" 2>> $LOG_FILE >> $LOG_FILE																															# Flush privileges



echo "##### Installing PHP & Related Libraries #####"
if [ $PHP_VER == true ]; then
  echo "Installing PHP 8"
  sudo apt-get install php php-mysql libapache2-mod-php php-curl php-gd php-mbstring php-xml php-xmlrpc php-soap php-intl php-zip -y >> $LOG_FILE
else
  echo "Installing PHP 7"
  sudo apt-get install php7.4 php7.4-mysql php7.4-curl php7.4-gd php7.4-mbstring php7.4-xml php7.4-xmlrpc php7.4-soap php7.4-intl php7.4-zip libapache2-mod-php7.4 -y >> $LOG_FILE

fi


echo "##### Installing WP CLI #####"
echo "Fetching"
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar >> $LOG_FILE
chmod +x wp-cli.phar
sudo mv wp-cli.phar /usr/local/bin/wp-raw
echo "Creating alias"
WP_ALIAS="#"'!'"/bin/bash\nsudo -u www-data wp-raw \"\$@\""
echo -e "$WP_ALIAS" | sudo tee /usr/local/bin/wp
sudo chmod +x /usr/local/bin/wp


echo "##### Prepping Wordpress Directory #####"
sudo rm -rf /var/www/html
sudo mkdir $WP_DIR
sudo chown www-data:www-data $WP_DIR
sudo chmod 755 $WP_DIR


echo "##### Installing Wordpress #####"wp co
cd $WP_DIR
wp core download
wp config create --dbname=$DB_NAME --dbuser=$DB_USER --dbpass=$DB_USER_PASS
wp db create
wp core install --url=$DOMAIN --title="$SITE_NAME" --admin_user=$WP_USER --admin_password=$WP_USER_PASS --admin_email=$WP_USER_EMAIL


echo "##### Stating Apache #####"
sudo systemctl start apache2 >> $LOG_FILE

echo -e "\033[31m ***** WARNING! *****\nYour passwords have been saved to $HOME/secrets.txt.\nMake sure you delete this file."

