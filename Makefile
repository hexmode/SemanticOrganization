.PHONY: ci test cs phpunit phpcs stan psalm parser

ci: test cs
test: phpunit parser
cs: phpcs stan psalm

phpunit:
	test ! -f phpunit.xml.dist																	||	\
		php ../../tests/phpunit/phpunit.php -c phpunit.xml.dist

phpcs:
	test ! -f phpcs.xml																		||	(	\
		cd ../..																				&&	\
		vendor/bin/phpcs -p -s --standard=$(shell pwd)/phpcs.xml								)

stan:
	test ! -f phpstan.neon																		||	\
		../../vendor/bin/phpstan analyse --configuration=phpstan.neon --memory-limit=2G

psalm:
	test ! -f psalm.xml																			||	\
		../../vendor/bin/psalm --config=psalm.xml

parser:
	test ! -f tests/parser/parserTests.txt														||	\
		php ../../tests/parser/parserTests.php --file=tests/parser/parserTests.txt
