#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package apps::automation::opcon::restapi::mode::machines;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw/is_excluded/;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Number of machines ';
}

sub prefix_machine_output {
    my ($self, %options) = @_;

    return sprintf(
        "machine '%s' [type: %s] ",
        $options{instance_value}->{name},
        $options{instance_value}->{type}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL, cb_prefix_output => 'prefix_global_output' },
        { name => 'machines', type => COUNTER_TYPE_INSTANCE, cb_prefix_output => 'prefix_machine_output', message_multiple => 'All machines are ok' }
    ];

    $self->{maps_counters}->{global} = [
        {   label => 'machines-detected', display_ok => 0, nlabel => 'machines.detected.count',
            unknown_default => '@0',
            set => {
                key_values => [ { name => 'detected' } ],
                output_template => 'detected: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{machines} = [
        {
            label => 'machine-status',
            type => COUNTER_KIND_TEXT,
            warning_default => '%{state} =~ /limited/',
            critical_default => '%{state} =~ /down|error/',
            set => {
                key_values => [
                    { name => 'state' }, { name => 'name' }, { name => 'type' }
                ],
                output_template => 'state: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        {
            label => 'machine-operation-status',
            type => COUNTER_KIND_TEXT,
            warning_default => '%{operationStatus} =~ /limited/',
            critical_default => '%{operationStatus} =~ /down/',
            set => {
                key_values => [
                    { name => 'operationStatus' }, { name => 'name' }, { name => 'type' }
                ],
                output_template => 'operation status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        {
            label => 'machine-network-status',
            type => COUNTER_KIND_TEXT,
            warning_default => '%{networkStatus} =~ /limited/',
            critical_default => '%{networkStatus} =~ /down/',
            set => {
                key_values => [
                    { name => 'networkStatus' }, { name => 'name' }, { name => 'type' }
                ],
                output_template => 'network status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-id:s'   => { name => 'filter_id',   default => '' },
        'filter-name:s' => { name => 'filter_name', default => '' },
        'filter-type:s' => { name => 'filter_type', default => '' }
    });

    return $self;
}

my $map_state = {
    U => 'up',
    D => 'down',    # NetCom does not look at the machine, communication is stopped
    E => 'error',   # NetCom cannot connect to the machine (communication error)
    L => 'limited',
    W => 'waiting'  # NetCom is waiting on machine to respond (trying to connect, next state will either be UP/LIMITED or ERROR)
};

my $map_operation_status = {
    U => 'up',
    D => 'down',
    L => 'limited'
};

my $map_network_status = {
    U => 'up',
    D => 'down',
    L => 'limited'
};

sub manage_selection {
    my ($self, %options) = @_;

    my $machines = $options{custom}->get_machines();

    $self->{global} = { detected => 0 };
    $self->{machines} = {};
    foreach my $item (@$machines) {
        next if is_excluded($item->{id}, $self->{option_results}->{filter_id});
        next if is_excluded($item->{name}, $self->{option_results}->{filter_name});
        next if is_excluded($item->{type}, $self->{option_results}->{filter_type});

        $self->{machines}->{ $item->{id} } = {
            id => $item->{id},
            name => $item->{name},
            type => $item->{type},
            state => $map_state->{ $item->{state} },
            networkStatus => $map_network_status->{ $item->{networkStatus} },
            operationStatus => $map_operation_status->{ $item->{operationStatus} }
        };
        $self->{global}->{detected}++;
    }
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['id', 'name', 'type', 'state', 'networkStatus', 'operationStatus', 'osType']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(custom => $options{custom}, keep_disabled => 1);
    foreach (sort { $a->{name} cmp $b->{name} } values %{ $self->{machines} } ) {
        $self->{output}->add_disco_entry(%$_);
    }
}

1;

__END__

=head1 MODE

Check machines.

=over 8

=item B<--filter-id>

Filter machines by ID (can be a regexp).

=item B<--filter-name>

Filter machines by name (can be a regexp).

=item B<--filter-type>

Filter machines by type (can be a regexp).

=item B<--unknown-machine-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{state}, %{name}, %{type}

=item B<--warning-machine-status>

Define the conditions to match for the status to be WARNING (default: '%{state} =~ /limited/').
You can use the following variables: %{state}, %{name}, %{type}

=item B<--critical-machine-status>

Define the conditions to match for the status to be CRITICAL (default: '%{state} =~ /down|error/').
You can use the following variables: %{state}, %{name}, %{type}

=item B<--unknown-machine-operation-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{operationStatus}, %{name}, %{type}

=item B<--warning-machine-operation-status>

Define the conditions to match for the status to be WARNING (default: '%{operationStatus} =~ /limited/').
You can use the following variables: %{operationStatus}, %{name}, %{type}

=item B<--critical-machine-operation-status>

Define the conditions to match for the status to be CRITICAL (default: '%{operationStatus} =~ /down/').
You can use the following variables: %{operationStatus}, %{name}, %{type}

=item B<--unknown-machine-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{networkStatus}, %{name}, %{type}

=item B<--warning-machine-network-status>

Define the conditions to match for the status to be WARNING (default: '%{networkStatus} =~ /limited/').
You can use the following variables: %{networkStatus}, %{name}, %{type}

=item B<--critical-machine-network-status>

Define the conditions to match for the status to be CRITICAL (default: '%{networkStatus} =~ /down/').
You can use the following variables: %{networkStatus}, %{name}, %{type}

=item B<--warning-machines-detected>

Thresholds.

=item B<--critical-machines-detected>

Thresholds.

=back

=cut
