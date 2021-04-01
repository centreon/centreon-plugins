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

package network::checkpoint::snmp::mode::hastate;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = "HA State: '" . $self->{result_values}->{hastate} . "' ";
    $msg .= "Role: '" . $self->{result_values}->{role} . "' ";
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'high_availability', type => 0 },
    ];
    $self->{maps_counters}->{high_availability} = [
        { label => 'status', threshold => 0,  set => {
                key_values => [ { name => 'hastate' }, { name => 'role' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'warning-status:s'  => { name => 'warning_status', default => '' },
        'critical-status:s' => { name => 'critical_status', default => '%{hastate} !~ /(UP|working)/' },
        'no-ha-status:s'    => { name => 'no_ha_status', default => 'UNKNOWN' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

my %map_status = (
    0 => 'Member is UP and working',
    1 => 'Problem preventing role switching',
    2 => 'HA is down',
);

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_haInstalled = '.1.3.6.1.4.1.2620.1.5.2.0';
    my $oid_haState = '.1.3.6.1.4.1.2620.1.5.6.0';
    my $oid_haStatCode = '.1.3.6.1.4.1.2620.1.5.101.0';
    my $oid_haStarted = '.1.3.6.1.4.1.2620.1.5.5.0';

    $self->{high_availability} = {};

    my $result = $options{snmp}->get_leef(
        oids => [$oid_haInstalled, $oid_haState, $oid_haStatCode, $oid_haStarted],
        nothing_quit => 1
    );

    if ($result->{$oid_haInstalled} < 1 or $result->{$oid_haStarted} eq "no") {
        $self->{output}->output_add(
            severity => $self->{option_results}->{no_ha_status},
            short_msg => sprintf("Looks like HA is not started, or not installed .."),
            long_msg => sprintf(
                "HA Installed : '%u' HA Started : '%s'",
                $result->{$oid_haInstalled},  $result->{$oid_haStarted}
            ),
        );
        $self->{output}->display();
        $self->{output}->exit();
    }
    $self->{high_availability} = {
        hastate => $map_status{$result->{$oid_haStatCode}},
        role => $result->{$oid_haState}
    };
}

1;

__END__

=head1 MODE

Check HA State of a Checkpoint node (chkpnt.mib).

=item B<--warning-status>

Trigger warning on %{role} or %{hastate} values
e.g --warning-status '%{role} !~ /master/' will warn when failover occurs

=item B<--critical-status>

Trigger critical on %{role} or %{hastate} values
(default: '%{hastate} !~ /(UP|working)/')

=item B<--no-ha-status>

Status to return when HA not running or not installed (default: 'UNKNOWN')

=back

=cut
