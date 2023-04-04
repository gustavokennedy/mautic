# Mautic
Repo for configs, initial setup and installation of Mautic (latest version) on Ubuntu Server. 
Repo para configurações, configuração inicial e instalação do Mautic (última versão) no Ubuntu Server.

## Download
Download repository:

```shell
git clone https://github.com/gustavokennedy/mautic.git
chmod +x install.sh
```

## Change Vars

```shell
sudo vi install.sh
```

```shell
pass='root'
db_name='mautic'
db_user='mautic'
web_root='/var/www/html/mautic'
BLOCO='/etc/nginx/sites-enabled/'
dominio=$1
email='gustavo@overall.cloud'
timezone='America/Sao_Paulo'
```



## Run
Execute:

```shell
./install.sh example.com
```
