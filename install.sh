#!/bin/sh
###################################################################
# Oreon is developped with GPL Licence 2.0 
#
# GPL License: http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt
#
# Developped by : Julien Mathis - Romain Le Merlus 
#                 Christophe Coraboeuf - Sugumaran Mathavarajan
#
###################################################################
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
#    For information : contact@merethis.com
####################################################################

#Load install script functions
. ../functions

##
## VARIABLES
##
## Make sure you know what you do if you modify it !!

PWD=`pwd`

PLUGINS_DIR=""

LOG_FILE="../log/install_oreon.log"

date > $LOG_FILE

echo
echo "##########################################################################"
echo "#                     OREON Project (www.oreon-project.org)              #"
echo "#                         Thanks for using OREON                         #"
echo "#                                                                        #"
echo "#                                                                        #"
echo "#                            infos@oreon-project.org                     #"
echo "#                                                                        #"
echo "#                  Make sure you have installed and configured           #"
echo "#                             perl - sed                                 #"
echo "#                                                                        #"
echo "#                                                                        #"
echo "##########################################################################"
echo "#                              The Team OREON                            #"
echo "##########################################################################"
echo ""
echo ""
$SETCOLOR_WARNING
echo "                     Make sure you have root permissions !"
$SETCOLOR_NORMAL
echo ""

echo "Are you sure to continue?"
echo -n "[y/n], default to [n]:"
read temp
if [ -z $temp ];then
    temp=n
fi

if [ $temp = "n" ];then
    echo "Bye bye !"
    exit
fi

test_answer()
{
    #$1 variable to fill
    #$2 text typed by user
    if [ ! -z $2 ];then
        if [ $2 != "" ];then
      eval $1=$2
        fi
    fi
}

##
## CONFIGURATION
##
if test -a $OREON_CONF ; then
	echo ""
	echo_success "Finding Oreon configuration file '$OREON_CONF' :" "OK"
	echo "You already seem to have to install Oreon."
    echo "Do you want use last Oreon install parameters ?"
	echo -n "[y/n], default to [y]:"
	read temp
	if [ -z $temp ];then
	    temp=y
	fi

	if [ $temp = "y" ];then
	    echo ""
		echo_passed "Using '$OREON_CONF' :" "PASSED"
	    . $OREON_CONF
	    echo ""
	else
		echo ""
		echo "First, let's talk about you !"
		echo "-----------------------------"
		echo ""
	fi
fi
	if [ -z $INSTALL_DIR_NAGIOS ];then
		INSTALL_DIR_NAGIOS="/usr/local/nagios"
		echo "Where is installed Nagios ?"
		echo -n "default to [$INSTALL_DIR_NAGIOS]:"
		read temp
		test_answer INSTALL_DIR_NAGIOS $temp
		echo ""
	fi

	if [ -z $NAGIOS_ETC ];then
		#nagios etc directory for oreon
		NAGIOS_ETC="$INSTALL_DIR_NAGIOS/etc"
		echo "Where are your nagios etc directory ?"
		echo -n "default to [$NAGIOS_ETC]:"
		read temp
		test_answer NAGIOS_ETC $temp
		echo ""
	fi

	if [ -z $NAGIOS_PLUGINS ];then
		#nagios plugins directory for oreon
		NAGIOS_PLUGINS="$INSTALL_DIR_NAGIOS/libexec"
		echo "Where are your nagios plugin / libexec  directory ?"
		echo -n "default to [$NAGIOS_PLUGINS]:"
		read temp
		test_answer NAGIOS_PLUGINS $temp
		echo ""
	fi

	if [ -z $INSTALL_DIR_OREON ];then
		#setup directory for oreon
		INSTALL_DIR_OREON="/usr/local/oreon"
		echo "Where do I install Oreon ?"
		echo -n "default to [$INSTALL_DIR_OREON]:"
		read temp
		test_answer INSTALL_DIR_OREON $temp
		echo ""
	fi

	if [ -z $SUDO_FILE ];then
		#Configuration file for sudo
		SUDO_FILE="/etc/sudoers"
		echo "Where is sudo ?"
		echo -n "default to [$SUDO_FILE]:"
		read temp
		test_answer SUDO_FILE $temp
		echo ""
	fi

	if [ -z $RRD_PERL ];then
		#RRDTOOL perl module directory
		RRD_PERL="/usr/local/rrdtool/lib/perl"
		echo "Where is RRD perl modules RRDs.pm ?"
		echo -n "default to [$RRD_PERL]:"
		read temp
		test_answer RRD_PERL $temp
		echo ""
	fi

##
## FUNCTION
##

# When exit on error

function error()
{
    echo "ERROR"
    exit 2
}

# install OREON PLUGIN

function confirm_oreon()
{
    	install_oreon_plugins
}

# installation script

#check_group_nagios
#check_user_nagios
#check_group_nagiocmd
#confirm_oreon

##
## INSTALL
##
echo "Users Management"
echo "----------------"
# check for httpd directory
check_httpd_directory
## group apache
check_group_apache
## user apache
check_user_apache
check_group_nagios
check_user_nagios
echo ""

echo "Other Stuff"
echo "------------"
if test -d $NAGIOS_PLUGINS ; then
    echo_success "Nagios libexec directory" "OK"
else
    mkdir -p $NAGIOS_PLUGINS > /dev/null
    echo_success "Nagios libexec directory created" "OK"
fi

# installation script

confirm_oreon
#oreon_post_install

echo ""
echo "###############################################################################"
echo "#                                                                             #"
echo "#                    Report bugs at bugs@oreon-project.org                    #"
echo "#                                                                             #"
echo "#                             Thanks for using OREON.                         #"
echo "#                             -----------------------                         #"
echo "#                        Contact : infos@oreon-project.org                    #"
echo "#                           http://www.oreon-project.org                      #"
echo "###############################################################################"
