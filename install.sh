
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

# Verifica usuário
if [ "$(whoami)" != 'root' ]; then
	echo $"Você não tem permissão para rodar $0 como usuário comum (non-root). Por favor use sudo"
		exit 1;
fi
