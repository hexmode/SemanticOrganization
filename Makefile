ifndef VERBOSE
.SILENT:
endif

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

MW_VER           ?= 1.35
COMPOSER_VERSION ?= 2

IN_CONTAINER     ?= false

# If this is being run on Github, then we're in a container and
# GITHUB_ACTIONS is true.
ifeq ("${GITHUB_ACTIONS}","true")
IN_CONTAINER := true
endif

# Ditto for Gitlab, except we'll check for GITLAB_CI.
ifeq ("${GITLAB_CI}","true")
IN_CONTAINER := true
endif

# If we're in a container then use the targets in the
# Makefile.inContainer file
ifeq ("${IN_CONTAINER}","true")
include Makefile.inContainer

else
# We are not in a container (or, at least, IN_CONTAINER is not
# set to true).  In this case, since we want the other targets to
# only be used in a container, we'll set up the container and
# call ourself in the container.

# Since MAKECMDGOALS contains whatever the first target is, we
# make the first target from the command line our default target
# (but only if we aren't already calling "inContainer").

ifneq ("$(word 1,${MAKECMDGOALS})","inContainer")
.PHONY: $(word 1,${MAKECMDGOALS})
$(word 1,${MAKECMDGOALS}):
	${MAKE} inContainer goals="${MAKECMDGOALS}"
endif

containerID := docker.io/library/mediawiki:${MW_VER}
containerName ?= ${EXT_NAME}-mediawiki
dockerCli ?= sudo docker
copyVars := EXT_NAME MW_INSTALL_PATH MW_EXT_PATH DB_ROOT_USER	\
	DB_ROOT_PWD MW_DB_TYPE MW_DB_SERVER MW_DB_PATH MW_DB_USER	\
	MW_DB_PWD MW_DB_NAME MW_VER COMPOSER_VERSION
SHELL := /bin/bash
ciPath ?= ${PWD}/conf/${MW_VER}
ciExtPath ?= ${ciPath}/extensions
ciDataPath ?= ${ciPath}/data
lsPath ?= ${ciPath}/LocalSettings.php
goals ?= ci

mirrorPath ?= ${ciPath}/mirror
extJsonJson ?= ${mirrorPath}/extjsonuploader.toolforge.org/ExtensionJson.json
extJsonJsonSrc ?= https://extjsonuploader.toolforge.org/ExtensionJson.json
mwDotComposer ?= ${ciPath}/dot-composer
mwVendor ?= ${ciPath}/vendor
smwGitUrl ?= "https://github.com/SemanticMediaWiki/SemanticMediaWiki.git"

mounts := "${PWD}:/target"										\
			"${mwDotComposer}:/root/.cache/composer"			\
			"${mwVendor}:${MW_INSTALL_PATH}/vendor"				\
			"${ciDataPath}:${MW_DB_PATH}"						\
			"${ciExtPath}/SemanticMediaWiki:${MW_EXT_PATH}/SemanticMediaWiki"

.PHONY: inContainer
inContainer: ${lsPath} ${mwVendor}
	${dockerCli} run --rm -w /target							\
		$(foreach mount,${mounts},-v ${mount})					\
		--env-file <(env -i										\
			$(foreach var,${copyVars},${var}=$(${var})))		\
		${containerID}											\
			${MAKE} -f Makefile.inContainer setupLinks ${goals}

${lsPath}: ${mwVendor} ${ciExtPath}/SemanticMediaWiki
	mkdir -p ${ciDataPath}
	chmod 1777 ${ciDataPath}
	cid=`${dockerCli} create									\
		$(foreach mount,${mounts},-v ${mount})					\
		--env-file <(env -i										\
			$(foreach var,${copyVars},${var}=$(${var})))		\
		${containerID}`										&&	\
	${dockerCli} start $$cid								&&	\
	${dockerCli} exec -w /target $$cid							\
			${MAKE} -f Makefile.inContainer						\
				getComposer 									\
				mediaWikiComposerUpdate							\
				setupLinks										\
				mediaWikiInstall								\
				enableDebugOutput								\
				installSemanticMediaWiki					&&	\
	${dockerCli} rm -f $$cid
	touch $@

${mwVendor}:
	mkdir -p ${ciPath}
	cid=`${dockerCli} create ${containerID}`				&&	\
	${dockerCli} cp "$$cid:${MW_INSTALL_PATH}/vendor"			\
		${mwVendor}											&&	\
	${dockerCli} rm -f $$cid
	touch $@

${ciExtPath}/SemanticMediaWiki:
	git clone ${smwGitUrl} $@
	touch $@

${extJsonJson}:
	test -d ${mirrorPath}									||	\
		mkdir -p ${mirrorPath}
	older=$(shell find $@ -mmin +120 | wc -l)				&&	\
	test $$older -ne 1									||	(	\
		cd ${mirrorPath}									&&	\
		wget --mirror ${extJsonJsonSrc}							\
	)

endif
# Local Variables:
# eval: (display-fill-column-indicator-mode)
# eval: (set (make-local-variable 'fill-column) 65)
# End:
