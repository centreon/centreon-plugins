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

package network::riverbed::steelhead::snmp::mode::connections;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '0.1';
    $options{options}->add_options(arguments =>
                                {
                                  "warning:s"               => { name => 'warning' },
                                  "critical:s"              => { name => 'critical' },
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

    my $oid_optimizedConnections = '.1.3.6.1.4.1.17163.1.1.5.2.1.0';
    my $oid_passthroughConnections = '.1.3.6.1.4.1.17163.1.1.5.2.2.0';
    my $oid_halfOpenedConnections = '.1.3.6.1.4.1.17163.1.1.5.2.3.0';
    my $oid_halfClosedConnections = '.1.3.6.1.4.1.17163.1.1.5.2.4.0';
    my $oid_establishedConnections = '.1.3.6.1.4.1.17163.1.1.5.2.5.0';
    my $oid_activeConnections = '.1.3.6.1.4.1.17163.1.1.5.2.6.0';
    my $oid_totalConnections = '.1.3.6.1.4.1.17163.1.1.5.2.7.0';

    my $result = $self->{snmp}->get_leef(oids => [$oid_optimizedConnections, $oid_passthroughConnections, $oid_halfOpenedConnections, $oid_halfClosedConnections,
                                                  $oid_establishedConnections, $oid_activeConnections, $oid_totalConnections, ], nothing_quit => 1);
    my $optimized = $result->{$oid_optimizedConnections};
    my $passthrough = $result->{$oid_passthroughConnections};
    my $halfOpened = $result->{$oid_halfOpenedConnections};
    my $halfClosed = $result->{$oid_halfClosedConnections};
    my $established = $result->{$oid_establishedConnections};
    my $active = $result->{$oid_activeConnections};
    my $total = $result->{$oid_totalConnections};

    my $exit = $self->{perfdata}->threshold_check(value => $total, threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("Connections: total %d, established %d, active %d, optimized %d, passthrough %d, half opened %d, half closed %d ",
                                                     $total, $established, $active, $optimized, $passthrough, $halfOpened, $halfClosed));

    $self->{output}->perfdata_add(label => "total",
                                  value => $total,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                  min => 0
                                  );
    $self->{output}->perfdata_add(label => "established",
                                  value => $established,
                                  min => 0
                                  );
    $self->{output}->perfdata_add(label => "active",
                                  value => $active,
                                  min => 0
                                  );
    $self->{output}->perfdata_add(label => "optimized",
                                  value => $optimized,
                                  min => 0
                                  );
    $self->{output}->perfdata_add(label => "passthrough",
                                  value => $passthrough,
                                  min => 0
                                  );
    $self->{output}->perfdata_add(label => "half opened",
                                  value => $halfOpened,
                                  min => 0
                                  );
    $self->{output}->perfdata_add(label => "half closed",
                                  value => $halfClosed,
                                  min => 0
                                  );

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Current connections: total, established, active, optimized, passthrough, half opened and half closed ones (STEELHEAD-MIB).

=over 8

=item B<--warning>

Threshold warning for total connections.

=item B<--critical>

Threshold critical for total connections.

=back

=cut
