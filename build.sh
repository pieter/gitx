#!/bin/bash

# enter the directory the script is in
cd "`dirname $0`"

scheme="GitX"
workspace="${scheme}.xcodeproj/project.xcworkspace"
configuration=""
clean=""
pause=10

print_usage()
{
    echo "Usage: `basename $0` [-c] -d|-r"
    echo "Where   -c clean before building"
    echo "        -d build for Debug configuration"
    echo "        -r build for Release configuration"
}

while getopts drch flag
    do
        case $flag in

            d)
		configuration="Debug"
                  ;;
            r)
		configuration="Release"
                 ;;
	    c)
		clean="clean"
		;;
	    h)
		print_usage
		exit
		;;
            ?)
		print_usage
                exit
                ;;
        esac
   done
shift $(( OPTIND - 1 ))  # shift past the last flag or argument

if [ -z "$configuration" ]; then
    echo "`basename $0`: error: must specify -d or -r"
    print_usage
    exit 1
fi

if [ -z "$clean" ];
then
    echo "Building $scheme from $workspace for $configuration in ${pause}..."
else
    echo "Building $scheme (cleanly) from $workspace for $configuration in ${pause}..."
fi
sleep $pause

xcrun xcodebuild -scheme "$scheme" -workspace "$workspace" -configuration "$configuration" "$clean" build CONFIGURATION_BUILD_DIR="`pwd`/build/${configuration}"
