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

package apps::vmware::connector::mode::datastorecountvm;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return 'accessible ' . $self->{result_values}->{accessible};
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
        { name => 'datastore', type => 1, cb_prefix_output => 'prefix_datastore_output', message_multiple => 'All Datastores are ok' }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'total-on', nlabel => 'datastore.vm.poweredon.current.count', set => {
                key_values => [ { name => 'poweredon' }, { name => 'total' } ],
                output_template => '%s VM(s) poweredon',
                perfdatas => [
                    { label => 'poweredon', template => '%s',
                      min => 0, max => 'total' }
                ]
            }
        },
        { label => 'total-off', nlabel => 'datastore.vm.poweredoff.current.count', set => {
                key_values => [ { name => 'poweredoff' }, { name => 'total' } ],
                output_template => '%s VM(s) poweredoff',
                perfdatas => [
                    { label => 'poweredoff', template => '%s',
                      min => 0, max => 'total' }
                ]
            }
        },
        { label => 'total-suspended', nlabel => 'datastore.vm.suspended.current.count', set => {
                key_values => [ { name => 'suspended' }, { name => 'total' } ],
                output_template => '%s VM(s) suspended',
                perfdatas => [
                    { label => 'suspended', template => '%s',
                      min => 0, max => 'total' }
                ]
            }
        }
    ];
    
    $self->{maps_counters}->{datastore} = [
        {
            label => 'status', type => 2, unknown_default => '%{accessible} !~ /^true|1$/i',
            set => {
                key_values => [ { name => 'accessible' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'on', nlabel => 'datastore.vm.poweredon.current.count', set => {
                key_values => [ { name => 'poweredon' }, { name => 'total' } ],
                output_template => '%s VM(s) poweredon',
                perfdatas => [
                    { label => 'poweredon', template => '%s',
                      min => 0, max => 'total', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'off', nlabel => 'datastore.vm.poweredoff.current.count', set => {
                key_values => [ { name => 'poweredoff' }, { name => 'total' } ],
                output_template => '%s VM(s) poweredoff',
                perfdatas => [
                    { label => 'poweredoff', template => '%s',
                      min => 0, max => 'total', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'suspended', nlabel => 'datastore.vm.suspended.current.count', set => {
                key_values => [ { name => 'suspended' }, { name => 'total' } ],
                output_template => '%s VM(s) suspended',
                perfdatas => [
                    { label => 'suspended', template => '%s',
                      min => 0, max => 'total', label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub prefix_datastore_output {
    my ($self, %options) = @_;

    return "Datastore '" . $options{instance_value}->{display} . "' : ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'datastore-name:s'   => { name => 'datastore_name' },
        'filter'             => { name => 'filter' },
        'scope-datacenter:s' => { name => 'scope_datacenter' }
    });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = { poweredon => 0, poweredoff => 0, suspended => 0, total => 0 };
    $self->{datastore} = {};
    my $response = $options{custom}->execute(
        params => $self->{option_results},
        command => 'datastorecountvm'
    );

    foreach my $ds_id (keys %{$response->{data}}) {
        my $ds_name = $response->{data}->{$ds_id}->{name};
        $self->{datastore}->{$ds_name} = {
            display => $ds_name, 
            accessible => $response->{data}->{$ds_id}->{accessible},
            poweredon => $response->{data}->{$ds_id}->{poweredon},
            poweredoff => $response->{data}->{$ds_id}->{poweredoff},
            suspended => $response->{data}->{$ds_id}->{suspended},
            total => $response->{data}->{$ds_id}->{poweredon} + $response->{data}->{$ds_id}->{poweredoff} + $response->{data}->{$ds_id}->{suspended},
        };
        $self->{global}->{poweredon} += $response->{data}->{$ds_id}->{poweredon} if (defined($response->{data}->{$ds_id}->{poweredon}));
        $self->{global}->{poweredoff} += $response->{data}->{$ds_id}->{poweredoff} if (defined($response->{data}->{$ds_id}->{poweredoff}));
        $self->{global}->{suspended} += $response->{data}->{$ds_id}->{suspended} if (defined($response->{data}->{$ds_id}->{suspended}));
    }
    
    $self->{global}->{total} = $self->{global}->{poweredon} + $self->{global}->{poweredoff} + $self->{global}->{suspended};
}

1;

__END__

=head1 MODE

Check number of vm running/off on datastores.

=over 8

=item B<--datastore-name>

datastore name to check.

=item B<--filter>

Datastore name is a regexp.

=item B<--scope-datacenter>

Search in following datacenter(s) (can be a regexp).

=item B<--unknown-status>

Set warning threshold for status (Default: '%{accessible} !~ /^true|1$/i').
Can used special variables like: %{accessible}

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{accessible}

=item B<--critical-status>

Set critical threshold for status (Default: '').
Can used special variables like: %{accessible}

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
