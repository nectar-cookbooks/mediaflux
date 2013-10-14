#!/bin/bash
# file name mediaflux

# chkconfig: 2345 90 05
# description: Mediaflux server daemon

# Novel/SuSE init.d parameters:
 
### BEGIN INIT INFO
# Provides:       mediaflux
# Required-Start: network
# Should-Start:  dmf
# Required-Stop:  network
# Default-Start:  2 3 5
# Default-Stop: 0 1 6
# Description:    Start Mediaflux
### END INIT INFO


# On Unix platforms, this file can be copied into /etc/init.d 
#
# If the operating system supports 'chkconfig' (e.g. Linux) then
# after copying into /etc/init.d, Mediaflux can be added as a
# service, using 'chkconfig --add mediaflux' and the service controlled
# using the 'service' command:
#
#  > service mediaflux [start,stop,status,restart]

# The following variables should be configured and are site specific. They
# should be placed in a separate script, that calls this script.
#
#   MFLUX_HOME       - location of the Mediaflux installation
#   MFLUX_DOMAIN     - the logon domain for this script
#   MFLUX_USER       - the logon user for this script
#   MFLUX_PASSWORD   - the logon password for this script
#   MFLUX_TRANSPORT  - the network transport type. One of: [http,tcpip]
#   MFLUX_PORT       - the network connection port
#

if [ -e /etc/mediaflux ] ; then
    . /etc/mediaflux
fi

MFLUX_PASSWORD=`echo $MFLUX_PASSWORD_ENC | base64 -d`

# Test if our configuration is valid
test -s ${MFLUX_HOME}/bin/aserver.jar || {
  echo 1>&2 "${MFLUX_HOME} is not a valid location of the Mediaflux installation" 
  echo 1>&2 "Check the configuration in /etc/sysconfig/mediaflux" 
  if test "$1" == "stop" ; then exit 0 ; else exit 6 ; fi
}


# PROG is used by this script to identify the name of the application
# Used for informational purposes only.

PROG=Mediaflux


# User credentials required so the script can execute the following services:
#
#   server.terminate
#   server.status
#
AUTHEN=$MFLUX_DOMAIN,$MFLUX_USER,$MFLUX_PASSWORD

if [ $MFLUX_RUN_AS_ROOT -eq 1 -o $MFLUX_SYSTEM_USER == "root" ] ; then
  DROP_PRIVILEGE=0
elif [[ $EUID -eq 0 ]]; then
  DROP_PRIVILEGE=1
else
  DROP_PRIVILEGE=0
fi

# Uncomment (or set) the following line (and set a preferred debug port) to
# enable remote attachment to the server using a Java debugger.
#
# The server will not suspend on startup.
#
#DEBUG=debug.port=8000

# Function: start
#
start() {
    echo "Starting $PROG. Check log files for status."
    if [[ $DROP_PRIVILEGE -eq 1 ]]; then
        su -c "umask $MFLUX_UMASK; java -jar $MFLUX_HOME/bin/aserver.jar application.home=$MFLUX_HOME nogui $DEBUG >> $MFLUX_HOME/volatile/logs/unix_start.log& " -s /bin/sh -l $MFLUX_SYSTEM_USER 
    else
        umask $MFLUX_UMASK; java -jar $MFLUX_HOME/bin/aserver.jar application.home=$MFLUX_HOME nogui $DEBUG >> $MFLUX_HOME/volatile/logs/unix_start.log&  
    fi
    RETVAL=$?
}

# Function: stop
#
stop() {
    echo "Stopping $PROG.."
    if [[ $DROP_PRIVILEGE -eq 1 ]]; then
        su -c "java -Djava.net.preferIPv4Stack=true -Dmf.transport=$MFLUX_TRANSPORT -Dmf.port=$MFLUX_PORT -jar $MFLUX_HOME/bin/aserver.jar authentication=$AUTHEN application.home=$MFLUX_HOME terminate" -s /bin/sh -l $MFLUX_SYSTEM_USER
    else
        java -Djava.net.preferIPv4Stack=true -Dmf.transport=$MFLUX_TRANSPORT -Dmf.port=$MFLUX_PORT -jar $MFLUX_HOME/bin/aserver.jar authentication=$AUTHEN application.home=$MFLUX_HOME terminate  
    fi
    RETVAL=$?
}

# Function: status
#
status() {
    echo "Checking status of $PROG.."
    if [[ $DROP_PRIVILEGE -eq 1 ]]; then
        su -c "java -Djava.net.preferIPv4Stack=true -Dmf.transport=$MFLUX_TRANSPORT -Dmf.port=$MFLUX_PORT -jar $MFLUX_HOME/bin/aserver.jar authentication=$AUTHEN application.home=$MFLUX_HOME status" -s /bin/sh -l $MFLUX_SYSTEM_USER
    else
        java -Djava.net.preferIPv4Stack=true -Dmf.transport=$MFLUX_TRANSPORT -Dmf.port=$MFLUX_PORT -jar $MFLUX_HOME/bin/aserver.jar authentication=$AUTHEN application.home=$MFLUX_HOME status
    fi
    RETVAL=$?
}

# Options:
#
case "$1" in 
  start) 
    start 
    ;;

  stop)
    stop
    ;;

  restart)
    echo "Restarting $PROG.."
    stop
    start
    ;;

  force-reload)
    echo "Force Reload: Restarting $PROG.."
    stop
    start
    ;;

  status)
    status
    RETVAL=$?
    ;;

  *)
    echo $"Usage: $0 {start|stop|restart|force-reload|status}"
    RETVAL=1
esac