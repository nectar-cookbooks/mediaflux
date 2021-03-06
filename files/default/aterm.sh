#!/bin/sh
if [ -r /etc/mediaflux/mfluxrc ] ; then
    . /etc/mediaflux/mfluxrc
fi
if [ -r ~/.mfluxrc ] ; then
    . ~/.mfluxrc
fi

if [ -z "$MFLUX_JAVA" ] ; then
    JAVA=`which java`
else
    JAVA="$MFLUX_JAVA"
fi

exec $JAVA -jar "$MFLUX_HOME/bin/aterm.jar" "$@"
