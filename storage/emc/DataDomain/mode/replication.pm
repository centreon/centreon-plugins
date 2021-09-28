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

package storage::emc::DataDomain::mode::replication;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use storage::emc::DataDomain::lib::functions;

sub prefix_repl_output {
    my ($self, %options) = @_;

    return "Replication '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'repl', type => 1, cb_prefix_output => 'prefix_repl_output', message_multiple => 'All replications are ok' }
    ];

    $self->{maps_counters}->{repl} = [
         {
             label => 'status',
             type => 2,
             warning_default => '%{state} =~ /initializing|recovering/i',
             critical_default => '%{state} =~ /disabledNeedsResync|uninitialized/i',
             set => {
                key_values => [ { name => 'state' } ],
                output_template => "status is '%s'",
                output_use => 'state',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'offset', set => {
                key_values => [ { name => 'offset' }, { name => 'display' } ],
                output_template => 'last time peer sync : %s seconds ago',
                perfdatas => [
                    { label => 'offset', template => '%s', 
                      label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_sysDescr = '.1.3.6.1.2.1.1.1.0'; # 'Data Domain OS 5.4.1.1-411752'
    my $oid_replicationInfoEntry = '.1.3.6.1.4.1.19746.1.8.1.1.1';

    my $snmp_result = $options{snmp}->get_leef(
        oids => [ $oid_sysDescr ],
        nothing_quit => 1
    );

    if (!($self->{os_version} = storage::emc::DataDomain::lib::functions::get_version(value => $snmp_result->{$oid_sysDescr}))) {
        $self->{output}->output_add(
            severity => 'UNKNOWN',
            short_msg => 'Cannot get DataDomain OS version.'
        );
        $self->{output}->display();
        $self->{output}->exit();
    }

    $snmp_result = $options{snmp}->get_table(
        oid => $oid_replicationInfoEntry,
        nothing_quit => 1
    );

    my ($oid_replSource, $oid_replDestination, $oid_replState);
    my %map_state = (
        1 => 'enabled', 2 => 'disabled', 3 => 'disabledNeedsResync',
    );
    if (centreon::plugins::misc::minimal_version($self->{os_version}, '5.4')) {
        %map_state = (
            1 => 'initializing', 2 => 'normal', 3 => 'recovering', 4 => 'uninitialized',
        );
        $oid_replSource = '.1.3.6.1.4.1.19746.1.8.1.1.1.7';
        $oid_replDestination = '.1.3.6.1.4.1.19746.1.8.1.1.1.8';
        $oid_replState = '.1.3.6.1.4.1.19746.1.8.1.1.1.3';
    } elsif (centreon::plugins::misc::minimal_version($self->{os_version}, '5.0')) {
        $oid_replSource = '.1.3.6.1.4.1.19746.1.8.1.1.1.7';
        $oid_replDestination = '.1.3.6.1.4.1.19746.1.8.1.1.1.8';
        $oid_replState = '.1.3.6.1.4.1.19746.1.8.1.1.1.3';
    } else {
        $oid_replSource = '.1.3.6.1.4.1.19746.1.8.1.1.1.6';
        $oid_replDestination = '.1.3.6.1.4.1.19746.1.8.1.1.1.7';
        $oid_replState = '.1.3.6.1.4.1.19746.1.8.1.1.1.2';
    }

    my $mapping = {
        replState           => { oid => $oid_replState, map => \%map_state },
        replSource          => { oid => $oid_replSource },
        replDestination     => { oid => $oid_replDestination },
        replSyncedAsOfTime  => { oid => '.1.3.6.1.4.1.19746.1.8.1.1.1.14' }
    };

    $self->{repl} = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{replState}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        $self->{repl}->{$instance} = {
            display => $result->{replSource} . '/' . $result->{replDestination},
            state => $result->{replState},
            offset => (time() - $result->{replSyncedAsOfTime})
        };
    }
}

1;

__END__

=head1 MODE

Check replication.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^status$'

=item B<--unknown-status>

Set warning threshold for status (Default: none).
Can used special variables like: %{state}

=item B<--warning-status>

Set warning threshold for status (Default: '%{state} =~ /initializing|recovering/i').
Can used special variables like: %{state}

=item B<--critical-status>

Set critical threshold for status (Default: '%{state} =~ /disabledNeedsResync|uninitialized/i').
Can used special variables like: %{state}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'offset'.

=back

=cut
