#!/bin/sh
# file name mfcommand

if [ -e /etc/mediaflux/mfluxrc -a -r /etc/mediaflux/mfluxrc ] ; then
    . /etc/mediaflux/mfluxrc
fi

if [ -e $HOME/.mfluxrc ] ; then
    . $HOME/.mfluxrc
fi


# We use the hostname to qualify the location of the SID file
# Since a SID is only valid for a given host.

HOSTNAME=`hostname`

# MFLUX_SID_FILE is a file in which we will store the current 
# session id for this user. The session will then be valid for
# any session for that user on this host.

MFLUX_SID_FILE=~/.MFLUX_SID_$HOSTNAME

check_env() {
if [ -z "$MFLUX_HOME" ] 
then {
    echo "The environment variable MFLUX_HOME has not been defined.";
    echo "This environment variable must be set to the root of the Mediaflux";
    echo "installation."
    exit 1;
}
fi

if [ -z "$MFLUX_HOST" ] 
then {
    echo "The environment variable MFLUX_HOST has not been defined.";
    echo "This environment variable must be set to the DNS or IP address of"
    echo "the server.";
    exit 1;
}
fi

if [ -z "$MFLUX_PORT" ] 
then {
    echo "The environment variable MFLUX_PORT has not been defined.";
    echo "This environment variable must be set to the port number used"
    echo "for the network connection.";
    echo "";
    echo "The transport will be assumed as follows:";
    echo "";
    echo "   Port         Transport";
    echo "   ----------------------";
    echo "    80          HTTP";
    echo "    443         HTTPS";
    echo "    *           TCP/IP";
    echo "";
    echo "That is, any other port will be assumed to be TCP/IP unless";
    echo "the environment variable MFLUX_TRANSPORT is set.";
    exit 1;
}
fi

if [ -z "$MFLUX_OUTPUT" ] 
then {
	MFLUX_OUTPUT=shell 
}
fi
case "$MFLUX_OUTPUT" in 
  xml) 
    ;;

  shell) 
    ;;

  *)
    echo "If provided, the environment variable MFLUX_OUTPUT must be";
    echo "set to either 'shell' or 'xml'. Defaults to 'shell'";
    exit -1;
    ;;
esac


if [ -z "$MFLUX_TRANSPORT" ] 
then {
  case "$MFLUX_PORT" in 
    80) 
      MFLUX_TRANSPORT=HTTP 
      ;;

    443) 
      MFLUX_TRANSPORT=HTTPS 
      ;;

    *)
      MFLUX_TRANSPORT=TCPIP
      ;;
  esac
}
fi

if [ -z "$MFLUX_JAVA" ]
then
    MFLUX_JAVA=`which java`
fi
}


# Function: logon
#
logon() {
   
    check_env;

    if test -f "$MFLUX_SID_FILE" 
    then {
      logoff
    }
    fi

    MFLUX_SID=`$MFLUX_JAVA -Djava.net.preferIPv4Stack=true -Dmf.host=$MFLUX_HOST -Dmf.port=$MFLUX_PORT -Dmf.transport=$MFLUX_TRANSPORT -cp $MFLUX_HOME/bin/aterm.jar arc.mf.command.Execute logon $1 $2 $3`
    RETVAL=$?

    case $RETVAL in 
      0) echo $MFLUX_SID >> "$MFLUX_SID_FILE"
      ;;
      2) echo "Authentication failure"
      ;;
    esac
}

# Function: help
#
#  This executes displays command help
#
help() {

    if test -f "$MFLUX_SID_FILE"
    then {
      MFLUX_SID=`cat "$MFLUX_SID_FILE"`

      $MFLUX_JAVA -Djava.net.preferIPv4Stack=true -Dmf.host=$MFLUX_HOST -Dmf.port=$MFLUX_PORT -Dmf.transport=$MFLUX_TRANSPORT -Dmf.sid=$MFLUX_SID -Dmf.result=$MFLUX_OUTPUT -cp $MFLUX_HOME/bin/aterm.jar arc.mf.command.Execute $*

      RETVAL=$?

      case $RETVAL in 
        3) echo "Session has timed out - need to logon again."; 
           rm -f "$MFLUX_SID_FILE"
        ;;
      esac

    } else {

      echo "Not logged on"

      RETVAL=1      
    }
    fi

}

# Function: execute
#
#  This executes an arbitrary command.
#
execute() {

    check_env;

    if test -f "$MFLUX_SID_FILE"
    then {
      MFLUX_SID=`cat "$MFLUX_SID_FILE"`

      $MFLUX_JAVA -Djava.net.preferIPv4Stack=true -Dmf.host=$MFLUX_HOST -Dmf.port=$MFLUX_PORT -Dmf.transport=$MFLUX_TRANSPORT -Dmf.sid=$MFLUX_SID -Dmf.result=$MFLUX_OUTPUT -cp $MFLUX_HOME/bin/aterm.jar arc.mf.command.Execute $*

      RETVAL=$?

      case $RETVAL in 
        3) echo "Session has timed out - need to logon again."; 
           rm -f "$MFLUX_SID_FILE"
        ;;
      esac

    } else {

      echo "Not logged on"

      RETVAL=1      
    }
    fi

}


# Function: import
#
#  This executes an import command.
#
import() {

    check_env;

    if test -f "$MFLUX_SID_FILE"
    then {
      MFLUX_SID=`cat "$MFLUX_SID_FILE"`

      $MFLUX_JAVA -Djava.net.preferIPv4Stack=true -Dmf.host=$MFLUX_HOST -Dmf.port=$MFLUX_PORT -Dmf.transport=$MFLUX_TRANSPORT -Dmf.sid=$MFLUX_SID -Dmf.result=$MFLUX_OUTPUT -cp $MFLUX_HOME/bin/aterm.jar arc.mf.command.Execute import $*

      RETVAL=$?

      case $RETVAL in 
        3) echo "Session has timed out - need to logon again."; 
           rm -f "$MFLUX_SID_FILE"
        ;;
      esac

    } else {

      echo "Not logged on"

      RETVAL=1      
    }
    fi

}


# Function: logoff
#
logoff() {

    check_env;

    if test -f "$MFLUX_SID_FILE"
    then {
      MFLUX_SID=`cat "$MFLUX_SID_FILE"`

      # Remove the file now..
      rm -f "$MFLUX_SID_FILE"

      $MFLUX_JAVA -Djava.net.preferIPv4Stack=true -Dmf.host=$MFLUX_HOST -Dmf.port=$MFLUX_PORT -Dmf.transport=$MFLUX_TRANSPORT -Dmf.sid=$MFLUX_SID -cp $MFLUX_HOME/bin/aterm.jar arc.mf.command.Execute logoff

      RETVAL=$?
    } else {

      echo "Not logged on"

      RETVAL=1      
    }
    fi

}

# Function: status
#
status() {
    if test -f "$MFLUX_SID_FILE"
    then {
      MFLUX_SID=`cat "$MFLUX_SID_FILE"`
      echo "Logged on in session $MFLUX_SID"
    } else {
      echo "Not logged on"
    }
    fi

    RETVAL=1
}

# Options:
#
case "$1" in 
  logon) 
    logon $2 $3 $4 
    ;;

  logoff)
    logoff
    ;;

  import)
    import $2 $3 $4 $5 $6 $7 $8
    ;;

  status)
    status
    ;;

  help)
    help $*
    ;;

  --help)
    echo $"Usage: $0 {logon|logoff|status|help|<mediaflux service>}"
    RETVAL=1
    ;;

  *) 
    execute $*
    ;;

esac

exit $RETVAL

