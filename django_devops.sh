#!/bin/bash

set -e

django_has() {
	type "$1" > /dev/null 2>&1
	return $?
}

if [ -z "$DJANGO_DEVOPS_DIR" ]; then
	DJANGO_DEVOPS_DIR="$HOME/.django_devops"
fi

#
# Outputs the location to NVM depending on:
# * The availability of $DJANGO_SOURCE
# * The method used ("script" or "git" in the script, defaults to "git")
# DJANGO_SOURCE always takes precedence
#
django_source() {
	local DJANGO_METHOD
	DJANGO_METHOD="$1"
	if [ -z "$DJANGO_SOURCE" ]; then
		local DJANGO_SOURCE
	else
		echo "$DJANGO_SOURCE"
		return 0
	fi
	if [ "_$DJANGO_METHOD" = "_script" ]; then
		DJANGO_SOURCE="https://raw.githubusercontent.com/thuongdinh/django_devops/v0.1.5/django_devops.sh"
	elif [ "_$DJANGO_METHOD" = "_script-ddevops-exec" ]; then
		DJANGO_SOURCE="https://raw.githubusercontent.com/thuongdinh/django_devops/v0.1.5/django_devops-exec"
	elif [ "_$DJANGO_METHOD" = "_git" ] || [ -z "$DJANGO_METHOD" ]; then
		DJANGO_SOURCE="https://github.com/thuongdinh/django_devops.git"
	else
		echo >&2 "Unexpected value \"$DJANGO_METHOD\" for \$DJANGO_METHOD"
		return 1
	fi
	echo "$DJANGO_SOURCE"
	return 0
}

django_download() {
	if django_has "curl"; then
		curl $*
	elif django_has "wget"; then
		# Emulate curl with wget
		ARGS=$(echo "$*" | sed -e 's/--progress-bar /--progress=bar /' \
													 -e 's/-L //' \
													 -e 's/-I /--server-response /' \
													 -e 's/-s /-q /' \
													 -e 's/-o /-O /' \
													 -e 's/-C - /-c /')
		wget $ARGS
	fi
}

install_from_git() {
	if [ -d "$DJANGO_DEVOPS_DIR/.git" ]; then
		rm -rf $DJANGO_DEVOPS_DIR
	fi

	# Cloning to $DJANGO_DEVOPS_DIR
	# always clean clone is not a good idea
	# will fix later
	echo "=> Downloading django_devops from git to '$DJANGO_DEVOPS_DIR'"
	printf "\r=> "
	mkdir -p "$DJANGO_DEVOPS_DIR"
	git clone "$(django_source "git")" "$DJANGO_DEVOPS_DIR"

	cd "$DJANGO_DEVOPS_DIR" && git checkout --quiet v0.1.5 && git branch --quiet -D master >/dev/null 2>&1

	return
}

django_do_install() {
	local CURRENT_PATH
	CURRENT_PATH=$(pwd)
	CURRENT_PATH="$CURRENT_PATH/"

	if ! django_has "git"; then
		echo >&2 "You need git to install ddevops"
		exit 1
	fi

	if ! django_has "python"; then
		echo >&2 "You need python to install ddevops"
		exit 1
	fi

	if ! django_has "pip"; then
		echo >&2 "You need pip to install ddevops"
		exit 1
	fi

	install_from_git

	echo "=> Checkout file form repos"
	git checkout-index -f -a --prefix=$CURRENT_PATH

	# Remove unnessesary files
	cd $CURRENT_PATH
	rm ./django_devops.sh

	echo "=> Install requirements libs"
	sudo pip install -r requirements.txt

	echo "=> Install requirements vagrant plugin"
	vagrant plugin install vagrant-berkshelf


	# TODO fix issue here
	# echo "=> Start new project information"
	# cookiecutter https://github.com/thuongdinh/cookiecutter-django-tastypie.git

	echo "=> Finished, Refer README.md to continue steps"
	django_reset
}

#
# Unsets the various functions defined
# during the execution of the install script
#
django_reset() {
	unset -f django_do_install django_has django_download install_from_git django_reset
}

django_do_install
