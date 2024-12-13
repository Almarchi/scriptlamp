#!/bin/bash

# Actualiza el sistema
sudo apt update && sudo apt full-upgrade -y

# Instalar Apache
sudo apt install apache2 -y
sudo systemctl enable apache2
sudo systemctl start apache2

# Instalar MySQL Server
sudo apt install mysql-server -y
sudo systemctl enable mysql
sudo systemctl start mysql

# Configuración de MySQL: Cambio de autenticación y contraseña para root
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'usuario';"
sudo mysql -e "FLUSH PRIVILEGES;"

# Instalar PHP y módulos necesarios
sudo apt install php libapache2-mod-php php-mysql -y
sudo systemctl restart apache2

# Crear un archivo PHP de prueba
cat <<EOT | sudo tee /var/www/html/info.php
<?php
phpinfo();
?>
EOT

# Instalar phpMyAdmin con configuración automatizada
export DEBIAN_FRONTEND="noninteractive"
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | sudo debconf-set-selections
echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | sudo debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/app-pass password NuevaContrasenaSegura" | sudo debconf-set-selections
echo "phpmyadmin phpmyadmin/app-password-confirm password NuevaContrasenaSegura" | sudo debconf-set-selections
sudo apt install phpmyadmin php-mbstring php-zip php-gd php-json php-curl -y
sudo phpenmod mbstring
sudo systemctl restart apache2

# Crear directorio protegido con autenticación básica
sudo mkdir -p /var/www/html/stats
sudo htpasswd -bc /etc/apache2/.htpasswd admin usuario

# Configurar acceso restringido en Apache
sudo bash -c 'cat <<EOT > /etc/apache2/sites-available/000-default.conf
<VirtualHost *:80>
    DocumentRoot /var/www/html

    <Directory "/var/www/html/stats">
        AuthType Basic
        AuthName "Acceso restringido"
        AuthBasicProvider file
        AuthUserFile "/etc/apache2/.htpasswd"
        Require valid-user
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOT'

sudo systemctl restart apache2

# Finalizar
clear
echo "\n\nInstalación y configuración de LAMP Stack completa.\n"
echo "PHP Info disponible en: http://IP_DEL_SERVIDOR/info.php"
echo "phpMyAdmin disponible en: http://IP_DEL_SERVIDOR/phpmyadmin"
echo "GoAccess Report disponible en: http://IP_DEL_SERVIDOR/report.html"
echo "Directorio protegido disponible en: http://IP_DEL_SERVIDOR/stats"
echo "Usuario: admin, Contraseña: usuario"
