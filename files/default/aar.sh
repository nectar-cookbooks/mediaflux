#!/bin/sh
#
# Run the Arcitecta 'aar' tool.
#

if [ -r /etc/mediaflux/mfluxrc ] ; then
    . /etc/mediaflux/mfluxrc
fi
if [ -r $HOME/.mfluxrc ] ; then
    . $HOME/.mfluxrc
fi

if [ -z "$MFLUX_JAVA" ] ; then
    JAVA=`which java`
else
    JAVA="$MFLUX_JAVA"
fi

JAR=`dirname $0`/aar.jar
if [ ! -f "${JAR}" ]; then
    echo "Error: could not find file aar.jar." >&2
    exit 1
fi

if [ $# -eq 0 ] ; then 
    $JAVA -jar $JAR -help
else 
    $JAVA -jar $JAR "$@"
fi

