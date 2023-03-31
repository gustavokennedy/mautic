#!/usr/bin/env bash
# Gustavo Kennedy Renkel
# Para problemas de permissão: chmod +x install.sh
# Antes de executar apontar DNS
# Problema de MySQL: usuário root não pode ter senha ""
#

# Functions
ok() { echo -e '\e[32m'$1'\e[m'; } # Green
die() { echo -e '\e[1;31m'$1'\e[m'; exit 1; }

RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 3`
BLUE=`tput setaf 4`
WHITE=`tput setaf 7`
BOLD=`tput bold`
RESET=`tput sgr0`

set -euo pipefail

echo "${GREEN}
   ______      ________ _____            _      _        _____ _      ____  _    _ _____  
  / __ \ \    / /  ____|  __ \     /\   | |    | |      / ____| |    / __ \| |  | |  __ \ 
 | |  | \ \  / /| |__  | |__) |   /  \  | |    | |     | |    | |   | |  | | |  | | |  | |
 | |  | |\ \/ / |  __| |  _  /   / /\ \ | |    | |     | |    | |   | |  | | |  | | |  | |
 | |__| | \  /  | |____| | \ \  / ____ \| |____| |____ | |____| |___| |__| | |__| | |__| |
  \____/   \/   |______|_|  \_\/_/    \_\______|______(_)_____|______\____/ \____/|_____/ 
                                                                                          
                                                                                          

"
# Variáveis
pass='root'
db_name='mautic'
db_user='mautic'
web_root='/var/www/html/mautic'
BLOCO='/etc/nginx/sites-enabled/'
dominio=$1
email='gustavo@overall.cloud'
timezone='America/Sao_Paulo'

# Verifica usuário
if [ "$(whoami)" != 'root' ]; then
	echo $"${RED} Você não tem permissão para rodar $0 como usuário comum (non-root). Por favor use sudo"
		exit 1;
fi

# Instala apps

if [  -n "$(uname -a | grep Ubuntu)" ]; then
        echo `lsb_release -d | grep -oh Ubuntu.*`
        echo "${RED} Instalando pacote LEMP...${RESET}"
	sudo apt -y install software-properties-common
	sudo add-apt-repository ppa:ondrej/php --yes
	sudo apt-get update
        apt-get --assume-yes install nginx mysql-server php7.4 php-cli php7.4-fpm unzip 
        apt-get --assume-yes install php7.4-cli php7.4-json php7.4-common php7.4-mysql php7.4-zip php7.4-gd php7.4-mbstring php7.4-curl php7.4-xml php7.4-bcmath

        x=`lsb_release -rs`
        if (($(echo "$x < 18.04" | bc -l) ));then
                echo "${RED}ERRO: Versão Ubuntu antiga! ${RESET}"
                apt-get --assume-yes install php-mcrypt
        fi
else
        echo "ERRO: Instalação apenas compátivel com Linux Ubuntu!"
        exit 1
fi

# Configura Timezone
echo "${RED} Configurando timezone do servidor...${RESET}"
sudo timedatectl set-timezone "America/Sao_Paulo"
sudo systemctl restart systemd-timesyncd.service
echo "${GREEN}----OK TIMEZONE ATUALIZADO COM SUCESSO!${RESET}"

# Configura MySQL
echo "${RED}  Configurando MySQL...${RESET}"
mysql -e "DROP DATABASE IF EXISTS ${db_name};"
mysql -e "CREATE DATABASE ${db_name} /*\!40100 DEFAULT CHARACTER SET utf8 */;"
mysql -e "DROP USER IF EXISTS ${db_user}@localhost;"
mysql -e "CREATE USER ${db_user}@localhost IDENTIFIED BY '${pass}';"
mysql -e "GRANT ALL PRIVILEGES ON ${db_name}.* TO '${db_user}'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"
echo "${GREEN}----OK MYSQL CONFIGURADO COM SUCESSO!${RESET}"
cd

# Download do Mautic
echo "${RED}  Baixando e Instalando Mautic...${RESET}"
curl -s https://api.github.com/repos/mautic/mautic/releases/latest \
| grep "browser_download_url.*zip" \
| cut -d : -f 2,3 \
| tr -d \" \
| tail -1 | wget -O mautic.zip -qi -

unzip -o mautic.zip -d $web_root
rm mautic.zip
echo "${GREEN}----OK MAUTIC INSTALADO COM SUCESSO!${RESET}"

# Define permissões
echo "${RED}  Definindo permissões...${RESET}"

cd $web_root
#chmod -R g+w app/cache/
#chmod -R g+w app/logs/
chmod -R g+w app/config/
chmod -R g+w media/files/
chmod -R g+w media/images/
chmod -R g+w translations/
echo "${GREEN}----OK PERMISSÕES DEFINIDAS COM SUCESSO!${RESET}"

# Reinicia Nginx
echo "${RED}  Reiniciando Nginx...${RESET}"
sudo systemctl reload nginx && sudo systemctl restart nginx
echo "${GREEN}----OK NGINX REINICIADO COM SUCESSO!${RESET}"

# Configura Nginx
# Check
[ $(id -g) != "0" ] && die "Script must be run as root."
[ $# != "1" ] && die "Usage: $(basename $0) domainName"

# Cria bloco Nginx
echo "${RED}  Configurando bloco Nginx...${RESET}"
cat >$BLOCO/$1 <<EOF
server {
	listen 80;
	server_name $1 www.$1;
    	root /var/www/html/mautic;
	index index.html index.htm index.php;

	location / {
                #try_files \$uri \$uri/ index.php;
		try_files $URI $URI/ /index.php?q=$URI&$ARGS;
        }

        location ~ \.php$ {
                include snippets/fastcgi-php.conf;
                fastcgi_pass unix:/run/php/php7.4-fpm.sock;
        }
}
EOF
echo "${GREEN}----OK BLOCO NGINX CONFIGURADO COM SUCESSO!${RESET}"

# Instala Certificado SSL
echo "${RED}  Configurando Certificado SSL...${RESET}"
sudo apt install certbot python3-certbot-nginx --assume-yes
certbot run -n --nginx --agree-tos -d $1,www.$1  -m  gustavo@overall.cloud  --redirect
echo "${GREEN}----OK CERTIFICADO SSL CONFIGURADO COM SUCESSO!${RESET}"

# Configura as crons
echo "${RED}  Configurando Cronjobs...${RESET}"
(crontab -l 2>/dev/null; echo "*/1 * * * * www-data /usr/bin/php /var/www/mautic/app/console mautic:segments:update > /dev/null 2>&1") | crontab -
(crontab -l 2>/dev/null; echo "*/1 * * * * www-data /usr/bin/php /var/www/mautic/app/console mautic:campaigns:trigger > /dev/null 2>&1") | crontab -
(crontab -l 2>/dev/null; echo "*/1 * * * * www-data /usr/bin/php /var/www/mautic/app/console mautic:campaigns:rebuild > /dev/null 2>&1") | crontab -
(crontab -l 2>/dev/null; echo "*/1 * * * * www-data /usr/bin/php /var/www/mautic/app/console mautic:iplookup:download > /dev/null 2>&1") | crontab -
(crontab -l 2>/dev/null; echo "*/1 * * * * www-data /usr/bin/php /var/www/mautic/app/console mautic:emails:send > /dev/null 2>&1") | crontab -
(crontab -l 2>/dev/null; echo "*/1 * * * * www-data /usr/bin/php /var/www/mautic/app/console mautic:email:fetch > /dev/null 2>&1") | crontab -
(crontab -l 2>/dev/null; echo "*/1 * * * * www-data /usr/bin/php /var/www/mautic/app/console mautic:social:monitoring > /dev/null 2>&1") | crontab -
(crontab -l 2>/dev/null; echo "*/1 * * * * www-data /usr/bin/php /var/www/mautic/app/console mautic:webhooks:process > /dev/null 2>&1") | crontab -
(crontab -l 2>/dev/null; echo "*/1 * * * * www-data /usr/bin/php /var/www/mautic/app/console mautic:broadcasts:send > /dev/null 2>&1") | crontab -
(crontab -l 2>/dev/null; echo "*/1 * * * * www-data /usr/bin/php /var/www/mautic/app/console mautic:import > /dev/null 2>&1") | crontab -
(crontab -l 2>/dev/null; echo "*/1 * * * * www-data /usr/bin/php /var/www/mautic/app/console mautic:campaigns:process_resets > /dev/null 2>&1") | crontab -

echo "${GREEN}----OK CRONJOBS CONFIGURADAS COM SUCESSO!${RESET}"

# Reinicia Nginx
echo "${RED}  Reiniciando Nginx...${RESET}"
sudo systemctl reload nginx && sudo systemctl restart nginx
echo "${GREEN}----OK NGINX REINICIADO COM SUCESSO!${RESET}"

# Mensagem ded finalizado
ok "Sucesso! Mautic instalado e configurado em $1"
