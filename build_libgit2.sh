#!/bin/sh

# build_libgit2.sh
# GitX
#
# Created by BrotherBard on 7/3/10.
# Copyright 2010 BrotherBard. All rights reserved.
# 
# based on: http://log.yeahrightkeller.com/post/270155578/run-script-while-cleaning-in-xcode

buildAction () {
    echo "Building libgit2..."
	if [[ -d .git ]]
	then
		export PATH=$PATH:$HOME/bin:$HOME/local/bin:/sw/bin:/opt/local/bin:`"$TARGET_BUILD_DIR"/gitx --git-path`
		git submodule init
		git submodule update
		cd libgit2
		rm -f libgit2.a
		make CFLAGS="-arch i386 -arch ppc -arch x86_64"
		ranlib libgit2.a
	else
		echo "error: Not a git repository."
		echo "error: clone GitX first so that the libgit2 submodule can be updated"
		exit 1
	fi
}

cleanAction () {
	echo "Cleaning libgit2..."
	cd libgit2
	make clean
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# MAIN

#echo "Running with ACTION=${ACTION}"

case $ACTION in
	# NOTE: it gets set to "" rather than "build" when doing a build.
	"")
		buildAction
		;;

	"clean")
		cleanAction
		;;
esac

exit 0

