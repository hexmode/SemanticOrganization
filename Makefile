.PHONY: ci test cs phpunit phpcs stan psalm parser verifyExtName

MW_INSTALL_PATH  ?= /var/www/html
EXT_NAME         ?= ext-name-not-set
MW_INSTALL_PATH  ?= /var/www/html
MW_EXT_PATH      ?= /var/www/html/extensions
DB_ROOT_USER     ?= root
DB_ROOT_PWD      ?= database
MW_DB_TYPE       ?= sqlite
MW_DB_SERVER     ?= localhost
MW_DB_PATH       ?= /var/www/data
MW_DB_USER       ?= wiki
MW_DB_PWD        ?= wiki
MW_DB_NAME       ?= wiki
COMPOSER_VERSION ?= 2

verifyExtName:
	test "${EXT_NAME}" != "ext-name-not-set"				||	(	\
		echo "You must set EXT_NAME to use this Makefile."	&&	\
		exit 1													\
	)

ci: test cs
test: phpunit parser
cs: phpcs stan psalm

phpunit:
	test ! -f phpunit.xml.dist								||	\
		php ${MW_INSTALL_PATH}/tests/phpunit/phpunit.php		\
			-c phpunit.xml.dist

phpcs:
	test ! -f phpcs.xml									||	(	\
		cd ${MW_INSTALL_PATH}								&&	\
		vendor/bin/phpcs -p -s									\
			--standard=$(shell pwd)/phpcs.xml					\
	)

stan:
	test ! -f phpstan.neon									||	\
		${MW_INSTALL_PATH}/vendor/bin/phpstan analyse			\
			--configuration=phpstan.neon --memory-limit=2G

psalm:
	test ! -f psalm.xml										||	\
		${MW_INSTALL_PATH}/vendor/bin/psalm --config=psalm.xml

parser:
	test ! -f tests/parser/parserTests.txt					||	\
		php ${MW_INSTALL_PATH}/tests/parser/parserTests.php		\
			--file=tests/parser/parserTests.txt

getComposer:
	apt update
	apt install -y unzip
	php -r "copy('https://getcomposer.org/installer', 			\
			'installer');"
	php -r "copy('https://composer.github.io/installer.sig',	\
			 'expected');"
	echo `cat expected` " installer" | sha384sum -c -
	php installer --${COMPOSER_VERSION}
	rm -f installer expected
	mv composer.phar /usr/local/bin/composer

mediaWikiComposerUpdate:
	COMPOSER=composer.local.json composer require --no-update	\
		--working-dir ${MW_INSTALL_PATH}						\
		mediawiki/semantic-media-wiki @dev
	composer update --working-dir ${MW_INSTALL_PATH}

mediaWikiInstall: verifyExtName
	php ${MW_INSTALL_PATH}/maintenance/install.php				\
		--pass=Password123456									\
		--server="http://localhost:8000"						\
		--scriptpath=""											\
		--dbtype=${MW_DB_TYPE}									\
		--dbserver=${MW_DB_SERVER}								\
		--installdbuser=${DB_ROOT_USER}							\
		--installdbpass=${DB_ROOT_PWD}							\
		--dbname=${MW_DB_NAME}									\
		--dbuser=${MW_DB_USER}									\
		--dbpass=${MW_DB_PWD}									\
		--dbpath=${MW_DB_PATH}									\
		--extensions=SemanticMediaWiki,${EXT_NAME}				\
		${EXT_NAME}-test WikiSysop


enableDebugOutput:
	(															\
		echo 'error_reporting(E_ALL| E_STRICT);'			&&	\
		echo 'ini_set("display_errors", 1);'				&&	\
		echo '$$wgShowExceptionDetails = true;'				&&	\
		echo '$$wgDevelopmentWarnings = true;'					\
	) >> ${MW_INSTALL_PATH}/LocalSettings.php

installSemanticMediaWiki:
	echo "enableSemantics( 'localhost' );"					>>  \
		${MW_INSTALL_PATH}/LocalSettings.php
	tail -n5 ${MW_INSTALL_PATH}/LocalSettings.php
	php ${MW_INSTALL_PATH}/maintenance/update.php --quick
