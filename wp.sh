#!/usr/bin/env bash
# WordPress 5.2 onwards require PHP version 5.6 or more.Since php 5.6 or more is not available in yum yet, we are going for WordPress 5.1. 
# Name of the WordPress tarball
tar="wordpress-5.1.1.tar.gz"

# Checks to see if User passed a variable from the command line
# If they did not, sets the default password to Drawsap
password=${1:-root}

# Install and Start Apache Web Server. Setting up the firewall to allow HTTP/HTTPs traffic(Port 80)
install_apache () {
  echo "Install and Start Apache Web Server"
  cd $HOME
  sudo yum install httpd -y
  sudo yum install firewalld -y
  sudo systemctl enable firewalld
  sudo systemctl start firewalld
  sudo firewall-cmd --permanent --add-service=http
  sudo firewall-cmd --permanent --add-service=https
  sudo firewall-cmd --reload
  sudo systemctl start httpd.service
  sudo systemctl enable httpd.service
  echo "Finished"
}

# Install and Start MySQL(MariaDB)
install_mysql () {
  echo "Install and Start MySQL(MariaDB)"
  cd $HOME
  sudo yum install mariadb-server mariadb -y
  sudo systemctl start mariadb
  # mysql_secure_installation
  mysql -u root -e "UPDATE mysql.user SET Password=PASSWORD('$password') WHERE User='root';"
  mysql -u root -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
  mysql -u root -e "DELETE FROM mysql.user WHERE User='';"
  mysql -u root -e "DROP DATABASE IF EXISTS test;"
  mysql -u root -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%';"
  mysql -u root -e "FLUSH PRIVILEGES;"
  sudo systemctl enable mariadb.service
  echo "Finished"
}

# Install and Start PHP
install_php () {
  echo "Install and Start PHP"
  cd $HOME
  # sudo yum install wget -y
  # sudo yum install yum-utils -y
  sudo yum install php php-mysql -y
  # sudo wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
  # sudo yum install epel-release-latest-7.noarch.rpm -y
  # sudo yum install http://rpms.remirepo.net/enterprise/remi-release-7.rpm -y
  # sudo yum-config-manager --enable remi-php73 -y
  # sudo yum install php php-gd php-mysql -y
  sudo systemctl restart httpd.service
  echo "Finished"
}

# Create MySQL Database and User for WordPress
set_up_sql_user () {
  echo "Create MySQL Database and User for WordPress"
  cd $HOME
  mysql -u root -p$password -e "CREATE DATABASE IF NOT EXISTS wordpress;"
  mysql -u root -p$password -e "CREATE USER IF NOT EXISTS wordpressuser@localhost IDENTIFIED BY 'password';"
  mysql -u root -p$password -e "GRANT ALL PRIVILEGES ON wordpress.* TO wordpressuser@localhost IDENTIFIED BY 'password';"
  mysql -u root -p$password -e "FLUSH PRIVILEGES;"
  echo "Finished"
}

# Install WordPress
install_wordpress () {
  echo "Install WordPress"
  cd $HOME
  sudo yum install wget -y
  sudo yum install php-gd -y
  sudo systemctl restart httpd
  wget https://wordpress.org/$tar
  # wget http://wordpress.org/latest.tar.gz
  tar -xzf $tar
  sudo rsync -avP ~/wordpress/ /var/www/html/
  mkdir /var/www/html/wp-content/uploads
  sudo chown -R apache:apache /var/www/html/*
  sudo cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
  sed -i s/database_name_here/wordpress/ /var/www/html/wp-config.php
  sed -i s/username_here/wordpressuser/ /var/www/html/wp-config.php
  sed -i s/password_here/password/ /var/www/html/wp-config.php
  echo "Finished"
}

# Runs the Individual Scripts
echo "Starting Script to set up WordPress"
install_apache
install_mysql
install_php
set_up_sql_user
install_wordpress
echo "Script Finished"
