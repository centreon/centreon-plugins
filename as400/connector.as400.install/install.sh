#!/bin/bash

#################################################
##Functions and vars for actions results printing
#################################################

RES_COL=80
MOVE_TO_COL="echo -en \\033[${RES_COL}G"
SETCOLOR_INFO="echo -en \\033[1;38m"
SETCOLOR_SUCCESS="echo -en \\033[1;32m"
SETCOLOR_FAILURE="echo -en \\033[1;31m"
SETCOLOR_NORMAL="echo -en \\033[0;39m"
SETCOLOR_WARNING="echo -en \\033[1;33m"

function  echo_success() {
    echo -n "$1"
    $MOVE_TO_COL
    $SETCOLOR_SUCCESS
    echo -n "$2"
    $SETCOLOR_NORMAL
    echo -e "\r"
    echo ""
}

function echo_failure() {
    echo -n "$1"
    $MOVE_TO_COL
    $SETCOLOR_FAILURE
    echo -n "$2"
    $SETCOLOR_NORMAL
    echo -e "\r"
    echo ""
}

function echo_passed() {
    echo -n "$1"
    $MOVE_TO_COL
    $SETCOLOR_WARNING
    echo -n "$2"
    $SETCOLOR_NORMAL
    echo -e "\r"
    echo ""
}

##################
##Static variables
##################

INIT_FOLDER="init-script/"
INIT_FILE="centreon-as400.service"
SYSCONFIG_FILE="centreon-as400-sysconfig"

CONNECTOR_VERSION=2.0.0
CONNECTOR_HOME="/usr/share/centreon-as400/"
CONNECTOR_LOG="/var/log/centreon-as400/"
CONNECTOR_ETC="/etc/centreon-as400/"
LOG_ETC_FILE="log4j.xml"

CONNECTOR_USER="centreon-as400"
CONNECTOR_GROUP="centreon-as400"

JAVA_BIN=""

ETC_PASSWD="/etc/passwd"
ETC_GROUP="/etc/group"
ETC_INITD="/etc/systemd/system/"
ETC_SYSCONFIG="/etc/sysconfig/"

######
##INIT
######

$SETCOLOR_WARNING
echo "Starting setup..."
$SETCOLOR_NORMAL
echo ""

##############################
##Getting modules install path
##############################
DONE="no"
CREATE_HOME="no"
temp_folder="$CONNECTOR_HOME"
while [ "$DONE" = "no" ]; do
	echo  "Centreon AS400 home Directory [$CONNECTOR_HOME]? "
	echo -n ">"
	read temp_folder
	if [ -z "$temp_folder" ]; then
		temp_folder="$CONNECTOR_HOME"
	fi
	temp_folder=`echo "$temp_folder" | sed "s/$/\//"`

	if [ -d "$temp_folder" ]; then
		DONE="yes"
	else
	    echo_failure "$temp does not exists" "CRITICAL"
	    echo  "Specified path does not exists, do you want to create it ?[Y/n]"
	    echo -n ">"
	    read temp
	    if [ -z "$temp" ]; then
		temp="Y"
	    fi
	    while [ "$temp" != "Y" ] && [ "$temp" != "y" ] && [ "$temp" != "n" ] && [ "$temp" != "N" ]; do
			echo  "Specified path does not exists, do you want to create it ?[Y/n]"
			echo -n ">"
			read temp
			if [ -z "$temp" ]; then
			    temp="Y"
			fi
	    done
	    if [ "$temp" = "Y" ] || [ "$temp" = "y" ]; then
			DONE="yes"
			CREATE_HOME="yes"
	    fi
 	fi
done
temp_folder=$(echo $temp_folder | sed "s/\/\/$/\//")
CONNECTOR_HOME=${temp_folder}
echo_success "Centreon AS400 home directory" "$CONNECTOR_HOME"

#############################
##Getting java home directory
#############################

JAVA_HOME="/usr/"
temp=$JAVA_HOME
while [ ! -x "$temp/bin/java" ]; do
    echo_failure "Cannot find java binary" "FAILURE"
    echo "Java home directory?"
    echo -n ">"
    read temp
    if [ -z "$temp" ]; then
        temp="$JAVA_HOME"
    fi
done
temp=`echo "$temp" | sed "s/$/\//"`
JAVA_BIN=`echo $temp | sed "s/\/\/$/\//"`"bin/java"
echo_success "Java bin path :" "$JAVA_BIN"

###################
# CONNECTOR INIT SCRIPT
###################

echo "Do you want to install AS400 systemd script [y/N]?"
echo -n ">"
read response
if [ -z "$response" ]; then
    response="N"
fi
while [ "$response" != "Y" ] && [ "$response" != "y" ] &&  [ "$response" != "N" ] && [ "$response" != "n" ]; do
    echo "Do you want to install AS400 systemd script [y/N]?"
    echo -n ">"
    read response
    if [ -z "$response" ]; then
        response="N"
    fi
done
INSTALL_CONNECTOR_INIT=$response
echo_success "CONNECTOR systemd script :" "$ETC_INITD/$INIT_FILE"

########################
## Centreon BI user and Group
########################
exists=`cat $ETC_PASSWD | grep "^$CONNECTOR_USER:"`
if [ -z "$exists" ]; then
    useradd -m $CONNECTOR_USER -d $CONNECTOR_HOME
fi
echo_success "CONNECTOR run user :" "$CONNECTOR_USER"

exists=`cat $ETC_GROUP | grep "^$CONNECTOR_GROUP:"`
if [ -z "$exists" ]; then
	groupadd $CONNECTOR_GROUP
fi
echo_success "CONNECTOR run group :" "$CONNECTOR_GROUP"

#######################
# DEPLOYING CENTREON BI
#######################
echo ""
echo_success "Creating directories and moving binaries..." "OK"
if [ ! -d "${CONNECTOR_HOME}" ]; then
     mkdir -p $CONNECTOR_HOME
fi
if [ ! -d "${CONNECTOR_HOME}/bin" ]; then
    mkdir ${CONNECTOR_HOME}/bin
fi

if [ -d bin/ ] ; then
    cp -f bin/*.jar ${CONNECTOR_HOME}/bin/
fi

if [ ! -d "${CONNECTOR_LOG}" ]; then
     mkdir -p ${CONNECTOR_LOG}
fi
if [ ! -d "${CONNECTOR_ETC}" ]; then
     mkdir -p ${CONNECTOR_ETC}
fi

cp etc/log4j.xml ${CONNECTOR_ETC}
cp etc/config.properties ${CONNECTOR_ETC}

###################
##Macro replacement
###################

ETC_FILE=${CONNECTOR_ETC}${CONNECTOR_ETC_FILE}

if [ "$INSTALL_CONNECTOR_INIT" = "y" ] || [ "$INSTALL_CONNECTOR_INIT" = "Y" ]; then
    echo_success "Copying CONNECTOR init script..." "OK"
    sed -e 's|@JAVA_BIN@|'"$JAVA_BIN"'|g' \
        $INIT_FOLDER/$INIT_FILE > $ETC_INITD/$INIT_FILE
    chmod 644 $ETC_INITD/$INIT_FILE
    sed -e 's|@CONNECTOR_HOME@|'"$CONNECTOR_HOME"'|g' \
        -e 's|@JAVA_BIN@|'"$JAVA_BIN"'|g' \
        -e 's|@CONNECTOR_USER@|'"$CONNECTOR_USER"'|g' \
        -e 's|@CONNECTOR_ETC@|'"${CONNECTOR_ETC}"'|g' \
        -e 's|@CONNECTOR_LOG@|'"${CONNECTOR_LOG}"'|g' \
        -e 's|@CONNECTOR_VERSION@|'"${CONNECTOR_VERSION}"'|g' \
        $INIT_FOLDER/$SYSCONFIG_FILE > $ETC_SYSCONFIG/centreon-as400
fi
echo_success "Deploying Centreon-AS400..." "OK"

###################################################
##Rights settings on install directory and binaries
###################################################

chown -R $CONNECTOR_USER.$CONNECTOR_GROUP $CONNECTOR_HOME
chown -R $CONNECTOR_USER.$CONNECTOR_GROUP $CONNECTOR_LOG
chown -R $CONNECTOR_USER.$CONNECTOR_GROUP $CONNECTOR_ETC
chmod -R 775 $CONNECTOR_HOME

echo_success "Rights settings..." "OK"

systemctl enable $INIT_FILE

#########
# THE END
#########

echo ""
$SETCOLOR_WARNING
echo "Setup finished."
echo ""
