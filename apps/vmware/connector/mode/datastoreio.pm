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

package apps::vmware::connector::mode::datastoreio;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return 'accessible ' . $self->{result_values}->{accessible};
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
        { name => 'datastore', type => 1, cb_prefix_output => 'prefix_datastore_output', message_multiple => 'All datastores are ok' }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'total-read', nlabel => 'datastore.read.usage.bytespersecond', set => {
                key_values => [ { name => 'read' } ],
                output_template => 'Total rate of reading data: %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'total_read_rate', template => '%s',
                      unit => 'B/s', min => 0 }
                ]
            }
        },
        { label => 'total-write', nlabel => 'datastore.write.usage.bytespersecond', set => {
                key_values => [ { name => 'write' } ],
                output_template => 'Total rate of writing data: %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'total_write_rate', template => '%s',
                      unit => 'B/s', min => 0 }
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
        { label => 'read', nlabel => 'datastore.read.usage.bytespersecond', set => {
                key_values => [ { name => 'read' } ],
                output_template => 'rate of reading data: %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'read_rate', template => '%s',
                      unit => 'B/s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'write', nlabel => 'datastore.write.usage.bytespersecond', set => {
                key_values => [ { name => 'write' } ],
                output_template => 'rate of writing data: %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'write_rate', template => '%s',
                      unit => 'B/s', min => 0, label_extra_instance => 1 }
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

    $self->{global} = { read => 0, write => 0 };
    $self->{datastore} = {};
    my $response = $options{custom}->execute(
        params => $self->{option_results},
        command => 'datastoreio'
    );

    foreach my $ds_id (keys %{$response->{data}}) {
        my $ds_name = $response->{data}->{$ds_id}->{name};
        $self->{datastore}->{$ds_name} = {
            display => $ds_name, 
            accessible => $response->{data}->{$ds_id}->{accessible},
            read => $response->{data}->{$ds_id}->{'datastore.read.average'},
            write => $response->{data}->{$ds_id}->{'datastore.write.average'},
        };
        $self->{global}->{read} += $response->{data}->{$ds_id}->{'datastore.read.average'} if (defined($response->{data}->{$ds_id}->{'datastore.read.average'}));
        $self->{global}->{write} += $response->{data}->{$ds_id}->{'datastore.write.average'} if (defined($response->{data}->{$ds_id}->{'datastore.write.average'}));
    }    
}

1;

__END__

=head1 MODE

Check datastore IO.

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
Can be: 'total-read', 'total-write', 'read', 'write'.

=item B<--critical-*>

Threshold critical.
Can be: 'total-read', 'total-write', 'read', 'write'.

=back

=cut
