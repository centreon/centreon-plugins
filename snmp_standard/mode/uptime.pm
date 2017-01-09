#
# Copyright 2017 Centreon (http://www.centreon.com/)
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

package snmp_standard::mode::uptime;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use POSIX;
use centreon::plugins::misc;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "warning:s"          => { name => 'warning', },
                                  "critical:s"         => { name => 'critical', },
                                  "force-oid:s"        => { name => 'force_oid', },
                                });

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
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};
    
    # To be used first for OS
    my $oid_hrSystemUptime = '.1.3.6.1.2.1.25.1.1.0';
    # For network equipment or others
    my $oid_sysUpTime = '.1.3.6.1.2.1.1.3.0';
    my ($result, $value);
    
    if (defined($self->{option_results}->{force_oid})) {
        $result = $self->{snmp}->get_leef(oids => [ $self->{option_results}->{force_oid} ], nothing_quit => 1);
        $value = $result->{$self->{option_results}->{force_oid}};
    } else {
        $result = $self->{snmp}->get_leef(oids => [ $oid_hrSystemUptime, $oid_sysUpTime ], nothing_quit => 1);
        if (defined($result->{$oid_hrSystemUptime})) {
            $value = $result->{$oid_hrSystemUptime};
        } else {
            $value = $result->{$oid_sysUpTime};
        }
    }
    
    my $exit_code = $self->{perfdata}->threshold_check(value => floor($value / 100), 
                              threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);    
    $self->{output}->perfdata_add(label => 'uptime', unit => 's',
                                  value => floor($value / 100),
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                  min => 0);

    $self->{output}->output_add(severity => $exit_code,
                                short_msg => sprintf("System uptime is: %s",
                                                     centreon::plugins::misc::change_seconds(value => floor($value / 100), start => 'd')));

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check system uptime.

=over 8

=item B<--warning>

Threshold warning in seconds.

=item B<--critical>

Threshold critical in seconds.

=item B<--force-oid>

Can choose your oid (numeric format only).

=back

=cut
