################################################################################
# Copyright 2005-2013 MERETHIS
# Centreon is developped by : Julien Mathis and Romain Le Merlus under
# GPL Licence 2.0.
# 
# This program is free software; you can redistribute it and/or modify it under 
# the terms of the GNU General Public License as published by the Free Software 
# Foundation ; either version 2 of the License.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along with 
# this program; if not, see <http://www.gnu.org/licenses>.
# 
# Linking this program statically or dynamically with other modules is making a 
# combined work based on this program. Thus, the terms and conditions of the GNU 
# General Public License cover the whole combination.
# 
# As a special exception, the copyright holders of this program give MERETHIS 
# permission to link this program with independent modules to produce an executable, 
# regardless of the license terms of these independent modules, and to copy and 
# distribute the resulting executable under terms of MERETHIS choice, provided that 
# MERETHIS also meet, for each linked independent module, the terms  and conditions 
# of the license of that module. An independent module is a module which is not 
# derived from this program. If you modify this program, you may extend this 
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
# 
# For more information : contact@centreon.com
# Authors : Florian Asche <info@florian-asche.de>
#
####################################################################################

package apps::apcupsd::local::mode::libgetdata;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;

sub getdata {
    my ($self, %options) = @_;

    my $stdout = centreon::plugins::misc::execute(output => $self->{output},
                                                  options => $self->{option_results},
                                                  sudo => $self->{option_results}->{sudo},
                                                  command => $self->{option_results}->{command},
                                                  command_path => $self->{option_results}->{command_path},
                                                  command_options => $self->{option_results}->{command_options} . $self->{option_results}->{apchost} . ":" . $self->{option_results}->{apcport} . $self->{option_results}->{command_options2});

    my $searchpattern = $self->{option_results}->{searchpattern};
    my ($valueok);
    my ($value);
    #print $stdout;
    foreach (split(/\n/, $stdout)) {
        if (/^$searchpattern\s*:\s*(.*)\s(Percent Load Capacity|Percent|Minutes|Seconds|Volts|Hz|seconds|C Internal|F Internal)/i) {
            $valueok = "1";
            $value = $1;
            #print $value;
            #print "\n";
        };
    };

    if ($valueok == "1") {
        #print $value;
        return $value;
    } else {
        $self->{output}->output_add(severity => 'CRITICAL',
                                    short_msg => 'NO DATA FOUND');     
        $self->{output}->display();
        $self->{output}->exit();
    };
};

1;