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

package apps::vmware::connector::mode::datastoresnapshot;

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
        { name => 'datastore', type => 3, cb_prefix_output => 'prefix_datastore_output', cb_long_output => 'datastore_long_output', indent_long_output => '    ', message_multiple => 'All datastores are ok', 
            group => [
                { name => 'global', type => 0, skipped_code => { -10 => 1 } },
                { name => 'global_snapshot', type => 0, skipped_code => { -10 => 1 } },
                { name => 'files', cb_prefix_output => 'prefix_files_output',  message_multiple => 'All snapshot files are ok', type => 1, skipped_code => { -10 => 1 } }
            ]
        }
    ];
    
    $self->{maps_counters}->{global} = [
        {
            label => 'status', type => 2, unknown_default => '%{accessible} !~ /^true|1$/i',
            set => {
                key_values => [ { name => 'accessible' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
    
    $self->{maps_counters}->{global_snapshot} = [
        { label => 'total', nlabel => 'datastore.snapshots.usage.bytes', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'total snapshots [size = %s %s]',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'total_size', template => '%s', unit => 'B', 
                      min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];
    
    $self->{maps_counters}->{files} = [
        { label => 'snapshot', nlabel => 'datastore.snapshot.usage.bytes', set => {
                key_values => [ { name => 'total' } ],
                output_template => '[size = %s %s]',
                output_change_bytes => 1,
                closure_custom_perfdata => sub { return 0; }
            }
        }
    ];
}

sub prefix_datastore_output {
    my ($self, %options) = @_;

    return "Datastore '" . $options{instance_value}->{display} . "' : ";
}

sub datastore_long_output {
    my ($self, %options) = @_;

    return "checking datastore '" . $options{instance_value}->{display} . "'";
}

sub prefix_files_output {
    my ($self, %options) = @_;

    return sprintf("file snapshot [%s]=>[%s] ", $options{instance_value}->{folder_path}, $options{instance_value}->{path});
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

    $self->{datastore} = {};
    my $response = $options{custom}->execute(
        params => $self->{option_results},
        command => 'datastoresnapshot'
    );

    my $i = 0;
    foreach my $ds_id (keys %{$response->{data}}) {
        my $ds_name = $response->{data}->{$ds_id}->{name};
        $self->{datastore}->{$ds_name} = { display => $ds_name, 
            files => {}, 
            global => {
                accessible => $response->{data}->{$ds_id}->{accessible},    
            },
            global_snapshot => {
                total => 0
            }
        };
        
        foreach (@{$response->{data}->{$ds_id}->{snapshost}}) {
            $self->{datastore}->{$ds_name}->{files}->{$i} = { 
                folder_path => $_->{folder_path},
                path        => $_->{path},
                total       => $_->{size}
            };
            $self->{datastore}->{$ds_name}->{global_snapshot}->{total} += $_->{size};
            $i++;
        }
    }
}

1;

__END__

=head1 MODE

Check snapshots usage on datastores.

=over 8

=item B<--datastore-name>

datastore name to list.

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
Can be: 'total', 'snapshot'.

=item B<--critical-*>

Threshold critical.
Can be: 'total', 'snapshot'.

=back

=cut
