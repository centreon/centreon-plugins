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

package apps::vmware::connector::mode::countvmhost;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return 'status ' . $self->{result_values}->{status};
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_state'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
        { name => 'host', type => 1, cb_prefix_output => 'prefix_host_output', message_multiple => 'All ESX Hosts are ok' }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'total-on', nlabel => 'host.vm.poweredon.current.count', set => {
                key_values => [ { name => 'poweredon' }, { name => 'total' } ],
                output_template => '%s VM(s) poweredon',
                perfdatas => [
                    { label => 'poweredon', template => '%s', min => 0, max => 'total' }
                ]
            }
        },
        { label => 'total-off', nlabel => 'host.vm.poweredoff.current.count', set => {
                key_values => [ { name => 'poweredoff' }, { name => 'total' } ],
                output_template => '%s VM(s) poweredoff',
                perfdatas => [
                    { label => 'poweredoff', template => '%s', min => 0, max => 'total' }
                ]
            }
        },
        { label => 'total-suspended', nlabel => 'host.vm.suspended.current.count', set => {
                key_values => [ { name => 'suspended' }, { name => 'total' } ],
                output_template => '%s VM(s) suspended',
                perfdatas => [
                    { label => 'suspended', template => '%s', min => 0, max => 'total' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{host} = [
        {
            label => 'status', type => 2, unknown_default => '%{status} !~ /^connected$/i',
            set => {
                key_values => [ { name => 'state' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'on', nlabel => 'host.vm.poweredon.current.count', set => {
                key_values => [ { name => 'poweredon' }, { name => 'total' } ],
                output_template => '%s VM(s) poweredon',
                perfdatas => [
                    { label => 'poweredon', template => '%s', min => 0, max => 'total', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'off', nlabel => 'host.vm.poweredoff.current.count', set => {
                key_values => [ { name => 'poweredoff' }, { name => 'total' } ],
                output_template => '%s VM(s) poweredoff',
                perfdatas => [
                    { label => 'poweredoff', template => '%s', min => 0, max => 'total', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'suspended', nlabel => 'host.vm.suspended.current.count', set => {
                key_values => [ { name => 'suspended' }, { name => 'total' } ],
                output_template => '%s VM(s) suspended',
                perfdatas => [
                    { label => 'suspended', template => '%s', min => 0, max => 'total', label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub prefix_host_output {
    my ($self, %options) = @_;

    return "Host '" . $options{instance_value}->{display} . "' : ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'esx-hostname:s'     => { name => 'esx_hostname' },
        'filter'             => { name => 'filter' },
        'scope-datacenter:s' => { name => 'scope_datacenter' },
        'scope-cluster:s'    => { name => 'scope_cluster' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = { poweredon => 0, poweredoff => 0, suspended => 0, total => 0 };
    $self->{host} = {};
    my $response = $options{custom}->execute(
        params => $self->{option_results},
        command => 'countvmhost'
    );

    foreach my $host_id (keys %{$response->{data}}) {
        my $host_name = $response->{data}->{$host_id}->{name};
        $self->{host}->{$host_name} = {
            display => $host_name, 
            state => $response->{data}->{$host_id}->{state},
            poweredon => $response->{data}->{$host_id}->{poweredon},
            poweredoff => $response->{data}->{$host_id}->{poweredoff},
            suspended => $response->{data}->{$host_id}->{suspended},
            total => $response->{data}->{$host_id}->{poweredon} + $response->{data}->{$host_id}->{poweredoff} + $response->{data}->{$host_id}->{suspended},
        };
        $self->{global}->{poweredon} += $response->{data}->{$host_id}->{poweredon} if (defined($response->{data}->{$host_id}->{poweredon}));
        $self->{global}->{poweredoff} += $response->{data}->{$host_id}->{poweredoff} if (defined($response->{data}->{$host_id}->{poweredoff}));
        $self->{global}->{suspended} += $response->{data}->{$host_id}->{suspended} if (defined($response->{data}->{$host_id}->{suspended}));
    }

    $self->{global}->{total} = $self->{global}->{poweredon} + $self->{global}->{poweredoff} + $self->{global}->{suspended};
}

1;

__END__

=head1 MODE

Check number of vm running/off on ESX hosts.

=over 8

=item B<--esx-hostname>

ESX hostname to check.
If not set, we check all ESX.

=item B<--filter>

ESX hostname is a regexp.

=item B<--scope-datacenter>

Search in following datacenter(s) (can be a regexp).

=item B<--scope-cluster>

Search in following cluster(s) (can be a regexp).

=item B<--unknown-status>

Set warning threshold for status (Default: '%{status} !~ /^connected$/i').
Can used special variables like: %{status}

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{status}

=item B<--critical-status>

Set critical threshold for status (Default: '').
Can used special variables like: %{status}

=item B<--warning-*>

Threshold warning.
Can be: 'total-on', 'total-off', 'total-suspended', 
'on', 'off', 'suspended'.

=item B<--critical-*>

Threshold critical.
Can be: 'total-on', 'total-off', 'total-suspended', 
'on', 'off', 'suspended'.

=back

=cut
