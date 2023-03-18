
#!/bin/bash
# Gustavo Kennedy Renkel
# Overall.Cloud

# Variáveis
pass='SenhaMautic@123'
db_name='Mautic'
db_user='UsuarioMautic'
web_root='/var/www/mautic'
domain='example.com'
email='gustavo@overall.cloud'
timezone='America/Sao_Paulo	'

if [ "$(whoami)" != 'root' ]; then
	echo $"You have no permission to run $0 as non-root user. Please use sudo"
		exit 1;
fi
