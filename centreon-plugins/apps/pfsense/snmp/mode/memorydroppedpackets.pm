#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package apps::pfsense::snmp::mode::memorydroppedpackets;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use POSIX;
use centreon::plugins::statefile;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "warning:s"          => { name => 'warning', },
                                  "critical:s"         => { name => 'critical', },
                                });
    $self->{statefile_value} = centreon::plugins::statefile->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
       $self->{output}->option_exit();
    }

    $self->{statefile_value}->check_options(%options);
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};
    $self->{hostname} = $self->{snmp}->get_hostname();
    $self->{snmp_port} = $self->{snmp}->get_port();
   
    my $oid_pfsenseMemDropPackets = '.1.3.6.1.4.1.12325.1.200.1.2.6.0'; 
    my ($result, $value);
    
    $result = $self->{snmp}->get_leef(oids => [ $oid_pfsenseMemDropPackets ], nothing_quit => 1);
    $value = $result->{$oid_pfsenseMemDropPackets};
    
    $self->{statefile_value}->read(statefile => 'pfsense_' . $self->{hostname}  . '_' . $self->{snmp_port} . '_' . $self->{mode});
    my $old_timestamp = $self->{statefile_value}->get(name => 'last_timestamp');
    my $old_memDropPackets = $self->{statefile_value}->get(name => 'memDropPackets');

    my $new_datas = {};
    $new_datas->{last_timestamp} = time();
    $new_datas->{memDropPackets} = $value;

    $self->{statefile_value}->write(data => $new_datas);
    if (!defined($old_timestamp) || !defined($old_memDropPackets)) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => "Buffer creation...");
        $self->{output}->display();
        $self->{output}->exit();
    }
    $old_memDropPackets = 0 if ($old_memDropPackets > $new_datas->{memDropPackets});
    my $delta_time = $new_datas->{last_timestamp} - $old_timestamp;
    $delta_time = 1 if ($delta_time == 0);

    my $memDropPacketsPerSec = ($new_datas->{memDropPackets} - $old_memDropPackets) / $delta_time;

    my $exit_code = $self->{perfdata}->threshold_check(value => $memDropPacketsPerSec, 
                              threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);    
    $self->{output}->perfdata_add(label => 'dropped_packets_Per_Sec',
                                  value => sprintf("%.2f", $memDropPacketsPerSec),
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                  min => 0);

    $self->{output}->output_add(severity => $exit_code,
                                short_msg => sprintf("Dropped packets due to memory limitations : %.2f /s", 
                                    $memDropPacketsPerSec));

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check number of packets per second dropped due to memory limitations.

=over 8

=item B<--warning>

Threshold warning for dropped packets in packets per second.

=item B<--critical>

Threshold critical for dropped packets in packets per second.

=back

=cut
