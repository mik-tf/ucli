build:
	bash ucli.sh install
	ucli

rebuild:
	ucli uninstall
	bash ucli.sh install
	ucli
	
delete:
	ucli uninstall
