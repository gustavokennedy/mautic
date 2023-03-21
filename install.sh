#!/bin/bash
# Para problemas de permissão: chmod +x install.sh
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
pass='SenhaMautic@123'
db_name='Mautic'
db_user='UsuarioMautic'
web_root='/var/www/mautic'
domain='example.com'
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

	echo "${RED} Atualizando sistema...${RESET}"
        apt-get update
	echo "${GREEN}----OK SISTEMA ATUALIZADO COM SUCESSO!${RESET}"
        echo "### Instalando pacotes LEMP"
        apt-get --assume-yes install nginx mysql-server php php-cli php-fpm php-mysql unzip 
        apt-get --assume-yes install php-zip php-xml php-imap php-apcu php-memcached php-mbstring php-curl php-amqplib php-mbstring php-bcmath php-intl

        x=`lsb_release -rs`
        if (($(echo "$x < 18.04" | bc -l) ));then
                echo "${RED}ERRO: Versão Ubuntu antiga! ${RESET}"
                apt-get --assume-yes install php-mcrypt
        fi
else
        echo "ERRO: Instalação apenas compátivel com Linux Ubuntu!"
        exit 1
fi

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

echo "${RED}  Reiniciando Nginx...${RESET}"
sudo systemctl reload nginx && sudo systemctl restart nginx
echo "${GREEN}----OK NGINX REINICIADO COM SUCESSO!${RESET}"
