###############################################################################
# Copyright 2005-2014 MERETHIS
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
# permission to link this program with independent modules to produce an timeelapsedutable, 
# regardless of the license terms of these independent modules, and to copy and 
# distribute the resulting timeelapsedutable under terms of MERETHIS choice, provided that 
# MERETHIS also meet, for each linked independent module, the terms  and conditions 
# of the license of that module. An independent module is a module which is not 
# derived from this program. If you modify this program, you may extend this 
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
# 
# For more information : contact@centreon.com
# Author : Simon BOMM <sbomm@merethis.com>
#
####################################################################################

package apps::vmware::connector::lib::common;

use strict;
use warnings;
use JSON;
use ZMQ::LibZMQ3;

sub connector_response {
    my ($self, %options) = @_;
    
    if (!defined($options{response})) {
        $self->{output}->add_option_msg(short_msg => "Cannot read response: $!");
        $self->{output}->option_exit();
    }
    
    my $data = zmq_msg_data($options{response});
    if ($data !~ /^RESPSERVER (.*)/msi) {
        $self->{output}->add_option_msg(short_msg => "Response not formatted: $data");
        $self->{output}->option_exit();
    }
    
    my $json = $1;
    my $result;
    
    eval {
        $result =  JSON->new->utf8->decode($json);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json result: $@");
        $self->{output}->option_exit();
    }
    
    foreach my $output (@{$result->{plugin}->{outputs}}) {
        if ($output->{type} == 1) {
            $self->{output}->output_add(severity => $output->{exit},
                                        short_msg => $output->{msg});
        } elsif ($output->{type} == 2) {
            $self->{output}->output_add(long_msg => $output->{msg});
        }
    }
    
    foreach my $perf (@{$result->{plugin}->{perfdatas}}) {
        $self->{output}->perfdata_add(label => $perf->{label}, unit => $perf->{unit},
                                      value => $perf->{value},
                                      warning => $perf->{warning},
                                      critical => $perf->{critical},
                                      min => $perf->{min}, max => $perf->{max});
    }
}

1;
