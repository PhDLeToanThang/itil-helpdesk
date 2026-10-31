#!/bin/bash
# ============================================================
# deploy_itsm_v11007.sh
# GLPI VERSION 11.0.7 updated: 31/05/2026
#
# Code Deploy ITIL Server On-premise
# Install GLPI 11.0.7 on Ubuntu 22.04 LTS / 24.04 LTS
#
# GLPI is a powerful open source IT service management (ITSM)
# software tool designed to help you plan and easily manage
# your IT operations.
#
# This is source code deploy for Multi-tenancy for more
# instance ITIL - ITSM.
# ============================================================

############### Tham số cần thay đổi ở đây ###################

echo "FQDN: e.g: demo.company.vn"
read -e FQDN

echo "dbname: e.g: itildata"
read -e dbname

echo "dbuser: e.g: userdata"
read -e dbuser

echo "Database Password: e.g: P@$$w0rd-1.22"
read -s dbpass

echo "phpmyadmin folder name: e.g: phpmyadmin"
read -e phpmyadmin

echo "ITIL Folder Data: e.g: itildata"
read -e FOLDERDATA

echo "dbtype name: e.g: mariadb"
read -e dbtype

echo "dbhost name: e.g: localhost"
read -e dbhost

echo "Your Email address for Certbot e.g: thang@company.vn"
read -e emailcertbot

echo "Your MySQL/MariaDB root password (leave empty if using unix_socket auth):"
read -s rootpass

GitGLPIversion="11.0.7"

echo "run install? (y/n)"
read -e run

if [ "$run" == n ] ; then
    exit
else

# ============================================================
# Step 1. Install NGINX
# ============================================================
sudo apt-get update -y
sudo apt-get install nginx -y
sudo systemctl enable nginx.service
sudo systemctl start nginx.service

# ============================================================
# Step 2. Install MariaDB/MySQL
# GLPI 11.0+ requires MariaDB >= 10.6 or MySQL >= 8.0
# ============================================================
sudo apt-get install mariadb-server mariadb-client -y

sudo systemctl enable mysql.service
sudo systemctl start mysql.service

# Secure MariaDB installation
if [ -z "$rootpass" ]; then
    # Use unix_socket auth - no password set
    sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED VIA unix_socket;"
    mysql_secure_installation <<EOF
n
y
n
y
y
EOF
else
    sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${rootpass}';"
    mysql_secure_installation <<EOF
n
${rootpass}
${rootpass}
y
n
y
y
EOF
fi

# ============================================================
# Step 3. Install PHP-FPM & Related modules
# GLPI 11.0+ requires PHP >= 8.2 (recommended 8.3)
# Mandatory modules: bcmath, curl, dom, fileinfo, gd, intl,
#   json, mbstring, mysqli, session, simplexml, xml, zip,
#   bz2, xmlreader, xmlwriter, filter, ldap, openssl
# ============================================================
sudo apt-get install software-properties-common -y
sudo add-apt-repository ppa:ondrej/php -y
sudo apt update -y

sudo apt install -y php8.3-fpm php8.3-common php8.3-cli php8.3-curl \
    php8.3-gd php8.3-intl php8.3-mbstring php8.3-mysql php8.3-xml \
    php8.3-zip php8.3-bz2 php8.3-bcmath php8.3-ldap php8.3-soap \
    php8.3-xmlrpc php8.3-opcache php-ldap

# Configure PHP settings for GLPI
PHP_INI="/etc/php/8.3/fpm/php.ini"
sudo sed -i "s/memory_limit = .*/memory_limit = 256M/" $PHP_INI
sudo sed -i "s/upload_max_filesize = .*/upload_max_filesize = 50M/" $PHP_INI
sudo sed -i "s/post_max_size = .*/post_max_size = 50M/" $PHP_INI
sudo sed -i "s/max_execution_time = .*/max_execution_time = 600/" $PHP_INI
sudo sed -i "s/max_input_vars = .*/max_input_vars = 5000/" $PHP_INI
sudo sed -i "s/;date.timezone =.*/date.timezone = Asia\/Ho_Chi_Minh/" $PHP_INI
sudo sed -i "s/session.cookie_httponly =.*/session.cookie_httponly = on/" $PHP_INI
sudo sed -i "s/;session.cookie_secure =.*/session.cookie_secure = on/" $PHP_INI
sudo sed -i "s/expose_php = .*/expose_php = Off/" $PHP_INI
sudo sed -i "s/allow_url_fopen = .*/allow_url_fopen = On/" $PHP_INI

sudo systemctl restart php8.3-fpm.service

# ============================================================
# Step 4. Create GLPI Database
# ============================================================
MYSQL_CMD="mysql"
if [ -n "$rootpass" ]; then
    MYSQL_CMD="mysql -uroot -p${rootpass}"
fi

$MYSQL_CMD -e "DROP DATABASE IF EXISTS ${dbname};"
$MYSQL_CMD -e "CREATE DATABASE IF NOT EXISTS ${dbname} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
$MYSQL_CMD -e "CREATE USER IF NOT EXISTS '${dbuser}'@'${dbhost}' IDENTIFIED BY '${dbpass}';"
$MYSQL_CMD -e "GRANT ALL PRIVILEGES ON ${dbname}.* TO '${dbuser}'@'${dbhost}';"
$MYSQL_CMD -e "GRANT SELECT ON mysql.time_zone_name TO '${dbuser}'@'${dbhost}';"
$MYSQL_CMD -e "FLUSH PRIVILEGES;"
$MYSQL_CMD -e "SHOW DATABASES;"

# ============================================================
# Step 5. Configure MariaDB for GLPI
# ============================================================
sudo tee -a /etc/mysql/mariadb.conf.d/50-server.cnf > /dev/null <<END

[mysqld]
innodb_file_per_table = 1
innodb_large_prefix = ON
max_allowed_packet = 128M
default-time-zone = +07:00
END

sudo systemctl restart mariadb

# ============================================================
# Step 6. Download & Install GLPI
# ============================================================
sudo apt install -y git wget tar

cd /opt

# Download GLPI
sudo wget "https://github.com/glpi-project/glpi/releases/download/${GitGLPIversion}/glpi-${GitGLPIversion}.tgz"

# Extract
sudo tar xvf "glpi-${GitGLPIversion}.tgz"

# Copy to web root
sudo mkdir -p "/var/www/html/${FQDN}"
sudo cp -R /opt/glpi/* "/var/www/html/${FQDN}/"
sudo mkdir -p "/var/www/html/${FOLDERDATA}"

# Set permissions
sudo chown -R www-data:www-data "/var/www/html/${FQDN}/"
sudo find "/var/www/html/${FQDN}/" -type d -exec chmod 755 {} \;
sudo find "/var/www/html/${FQDN}/" -type f -exec chmod 644 {} \;
sudo chown www-data:www-data "/var/www/html/${FOLDERDATA}"

# ============================================================
# Step 7. Configure /etc/hosts
# ============================================================
sudo tee /etc/hosts <<END
127.0.0.1 ${FQDN}
127.0.0.1 localhost

::1 ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
END

# ============================================================
# Step 8. Configure NGINX
# ============================================================
sudo tee "/etc/nginx/conf.d/${FQDN}.conf" <<END
server {
    listen 80;
    server_name ${FQDN};

    root /var/www/html/${FQDN};
    index index.php index.html index.htm;

    client_max_body_size 512M;
    autoindex off;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location /${FOLDERDATA}/ {
        internal;
        alias /var/www/html/${FOLDERDATA}/;
    }

    location ~ [^/]\.php(/|\$) {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ ^/(doc|sql|setup)/ {
        deny all;
    }
}
END

sudo nginx -t
sudo systemctl reload nginx

# ============================================================
# Step 9. Setup and Configure PhpMyAdmin
# ============================================================
sudo apt update -y
sudo apt install phpmyadmin -y 2>/dev/null || true

# Remove Apache if installed
sudo service apache2 stop 2>/dev/null || true
sudo apt-get purge -y apache2 apache2-utils apache2-bin apache2.2-common 2>/dev/null || true
sudo apt-get autoremove -y 2>/dev/null || true

# Create symlink for phpMyAdmin
sudo ln -sf /usr/share/phpmyadmin "/var/www/html/${FQDN}/${phpmyadmin}"
sudo chown -R root:root /var/lib/phpmyadmin 2>/dev/null || true

sudo nginx -t
sudo systemctl reload nginx

# ============================================================
# Step 10. Install Certbot (Let's Encrypt SSL)
# ============================================================
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d "${FQDN}" --email "${emailcertbot}" --agree-tos --redirect --hsts --non-interactive || \
    echo "Certbot non-interactive failed. Run manually: sudo certbot --nginx -d ${FQDN}"

# ============================================================
# Step 11. Configure firewall
# ============================================================
sudo ufw allow 22/tcp 2>/dev/null || true
sudo ufw allow 80/tcp 2>/dev/null || true
sudo ufw allow 443/tcp 2>/dev/null || true
sudo ufw --force enable 2>/dev/null || true

# ============================================================
# Hoàn tất cài đặt
# ============================================================
echo ""
echo "=== GLPI 11.0.7 Installation Complete ==="
echo "Website: https://${FQDN}"
echo "Database name: ${dbname}"
echo "Database user: ${dbuser}"
echo ""
echo "Default GLPI admin accounts:"
echo "  glpi/glpi (administrator)"
echo "  tech/tech (technician)"
echo "  normal/normal (normal user)"
echo "  post-only/postonly (post-only)"
echo ""
echo "phpMyAdmin: https://${FQDN}/${phpmyadmin}"
echo ""
echo "IMPORTANT: Change default passwords on first login!"
echo ""

fi
