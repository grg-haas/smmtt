#!/bin/bash
set -o pipefail
set -e

# Ninja generates build lines which start with [xxxx/yyyy] where xxxx
# is the number of the current file being built and yyyy is the number
# of files total which will be built. This confuses clion, which expects
# the first bit of the command line output to be the compiler. Therefore,
# we have a tiny wrapper around ninja which returns the output without
# any of the [xxxx/yyyy] lines -- this does not affect the functionality
# of any other parts of the build system.

NINJA=`which ninja`
if [[ ! -z "$VERBOSE" ]] && [[ "$VERBOSE" != 0 ]]; then
	$NINJA "$@" | while read line ; do
	    if [[ "$line" =~ \[[0-9]+\/[0-9]+\] ]]; then
	        OUTPUT=`echo "$line" | sed 's/\[[0-9]*\/[0-9]*\] \(.*\)/\1/p'`
	    else
	        OUTPUT="$line"
	    fi

	    echo "$OUTPUT"
	done
else
	$NINJA "$@"
fi
