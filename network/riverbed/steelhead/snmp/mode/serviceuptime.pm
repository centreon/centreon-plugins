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

package network::riverbed::steelhead::snmp::mode::serviceuptime;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use POSIX;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "warning:s"          => { name => 'warning', },
                                  "critical:s"         => { name => 'critical', },
                                  "seconds"            => { name => 'seconds', }
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
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    my $oid_serviceUptime = '.1.3.6.1.4.1.17163.1.1.2.4.0';
    my ($result, $value);

    $result = $self->{snmp}->get_leef(oids => [ $oid_serviceUptime ], nothing_quit => 1);
    $value = $result->{$oid_serviceUptime};

    my $exit_code = $self->{perfdata}->threshold_check(value => floor($value / 100),
                              threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
    $self->{output}->perfdata_add(label => 'uptime', unit => 's',
                                  value => floor($value / 100),
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                  min => 0);

    $self->{output}->output_add(severity => $exit_code,
                                short_msg => sprintf("Service uptime is: %s",
                                    defined($self->{option_results}->{seconds}) ? floor($value / 100) . " seconds" : floor($value / 86400 / 100) . " days" ));

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Uptime of the optimization service (STEELHEAD-MIB).

=over 8

=item B<--warning>

Threshold warning in seconds.

=item B<--critical>

Threshold critical in seconds.

=item B<--seconds>

Display uptime in seconds.

=back

=cut
