.PHONY: ci test cs phpunit phpcs stan psalm parser

ci: test cs
test: phpunit parser
cs: phpcs stan psalm

phpunit: phpunit.xml.dist
	php ../../tests/phpunit/phpunit.php -c phpunit.xml.dist

phpcs:
	cd ../.. && vendor/bin/phpcs -p -s --standard=$(shell pwd)/phpcs.xml

stan:
	../../vendor/bin/phpstan analyse --configuration=phpstan.neon --memory-limit=2G

psalm:
	../../vendor/bin/psalm --config=psalm.xml

parser:
	test ! -f tests/parser/parserTests.txt														||	\
		php ../../tests/parser/parserTests.php --file=tests/parser/parserTests.txt

phpunit.xml.dist:
	(																								\
		echo '<phpunit colors="true">'															&&	\
		echo '<testsuites>'																		&&	\
		echo '<testsuite name="All">'															&&	\
		echo '<directory>tests</directory>'														&&	\
		echo '</testsuite>'																		&&	\
		echo '</testsuites>'																	&&	\
		echo '</phpunit>'																			\
	) > $@
