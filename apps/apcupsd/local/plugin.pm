#
# Copyright 2021 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and application monitoring for
# service performance.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#
# see http://manned.org/apcaccess
#
#sprung:~# apcaccess                        # 
#APC      : 001,048,1163                    # version, number of records and number of bytes following
#DATE     : 2014-03-15 19:30:58 +0100       # Date and time of last update from UPS
#HOSTNAME : sprung                          # hostname of computer running apcupsd
#VERSION  : 3.14.8 (16 January 2010) debian # apcupsd version number, date and operating system
#UPSNAME  : APC_ESX_SERVER                  # UPS name from configuration file (dumb) or EEPROM (smart)
#CABLE    : Custom Cable Smart              # Cable type specified in the configuration file
#MODEL    : Smart-UPS 620                   # UPS model derived from UPS information
#UPSMODE  : ShareUPS Master                 # Mode in which UPS is operating
#STARTTIME: 2014-03-13 22:40:39 +0100       # Date and time apcupsd was started
#STATUS   : ONLINE                          # UPS status (online, charging, on battery etc)
#LINEV    : 224.6 Volts                     # Current input line voltage
#LOADPCT  :  58.5 Percent Load Capacity     # Percentage of UPS load capacity used as estimated by UPS
#BCHARGE  : 100.0 Percent                   # Current battery capacity charge percentage
#TIMELEFT :  11.0 Minutes                   # Remaining runtime left on battery as estimated by UPS
#MBATTCHG : 10 Percent                      # Min battery charge % (BCHARGE) required for system shutdown
#MINTIMEL : 4 Minutes                       # Min battery runtime (MINUTES) required for system shutdown
#MAXTIME  : 0 Seconds                       # Max battery runtime (TIMEOUT) after which system is shutdown
#MAXLINEV : 227.5 Volts                     # Maximum input line voltage since apcupsd startup
#MINLINEV : 224.6 Volts                     # Minimum input line voltage since apcupsd startup
#OUTPUTV  : 227.5 Volts                     # UPS output voltage
#SENSE    : High                            # Current UPS sensitivity setting for voltage fluctuations
#DWAKE    : 060 Seconds                     # Time UPS waits after power off when the power is restored
#DSHUTD   : 600 Seconds                     # Delay before UPS powers down after command received
#DLOWBATT : 02 Minutes                      # Low battery signal sent when this much runtime remains
#LOTRANS  : 208.0 Volts                     # Input line voltage below which UPS will switch to battery
#HITRANS  : 253.0 Volts                     # Input line voltage above which UPS will switch to battery
#RETPCT   : 015.0 Percent                   # Battery charge % required after power off to restore power
#ALARMDEL : 30 seconds                      # Delay period before UPS starts sounding alarm
#BATTV    : 13.8 Volts                      # Current battery voltage
#LINEFREQ : 50.0 Hz                         # Current line frequency in Hertz
#LASTXFER : No transfers since turnon       # Reason for last transfer to battery since apcupsd startup
#NUMXFERS : 0                               # Number of transfers to battery since apcupsd startup
#TONBATT  : 0 seconds                       # Seconds currently on battery
#CUMONBATT: 0 seconds                       # Cumulative seconds on battery since apcupsd startup
#XOFFBATT : N/A                             # Date, time of last transfer off battery since apcupsd startup
#SELFTEST : NO                              # Date and time of last self test since apcupsd startup
#STESTI   : OFF                             # Self-test interval
#STATFLAG : 0x07000008 Status Flag          # UPS status flag in hex
#REG1     : 0x00 Register 1                 # Fault register 1 in hex
#REG2     : 0x00 Register 2                 # Fault register 2 in hex
#REG3     : 0x00 Register 3                 # Fault register 3 in hex
#MANDATE  : 08/09/01                        # UPS date of manufacture
#SERIALNO : NS0132263041                    # UPS serial number
#BATTDATE : 11/01/08                        # Date battery last replaced (if set)
#NOMOUTV  : 230 Volts                       # Nominal output voltage to supply when on battery power
#NOMBATTV : 12.0 Volts                      # Nominal battery voltage
#FIRMWARE : 22.6.I                          # UPS firmware version
#APCMODEL : CWI                             # APC model information
#END APC  : 2014-03-15 19:31:00 +0100       # Date and time of status information was written

package apps::apcupsd::local::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_simple);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '0.1';
    %{$self->{modes}} = (
                'batterycharge'       => 'apps::apcupsd::local::mode::batterycharge',   # BCHARGE
                'temperature'          => 'apps::apcupsd::local::mode::temperature',    # ITEMP
                'timeleft'            => 'apps::apcupsd::local::mode::timeleft',        # TIMELEFT MAXTIME MINTIMEL
                'linevoltage'         => 'apps::apcupsd::local::mode::linevoltage',     # LINEV
                'batteryvoltage'      => 'apps::apcupsd::local::mode::batteryvoltage',  # BATTV
                'outputvoltage'       => 'apps::apcupsd::local::mode::outputvoltage',   # OUTPUTV
                'linefrequency'       => 'apps::apcupsd::local::mode::linefrequency',   # LINEFREQ
                'loadpercentage'      => 'apps::apcupsd::local::mode::loadpercentage',  # LOADPCT
                        );
    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check apcupsd through local commands (the plugin can use SSH).

=cut
