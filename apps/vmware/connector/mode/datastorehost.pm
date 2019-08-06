#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package apps::vmware::connector::mode::datastorehost;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = 'status ' . $self->{result_values}->{status};
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_state'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'host', type => 3, cb_prefix_output => 'prefix_host_output', cb_long_output => 'host_long_output', indent_long_output => '    ', message_multiple => 'All ESX hosts are ok', 
            group => [
                { name => 'global', type => 0, skipped_code => { -10 => 1 } },
                { name => 'datastore', cb_prefix_output => 'prefix_datastore_output',  message_multiple => 'All datastores latencies are ok', type => 1, skipped_code => { -10 => 1 } },
            ]
        }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'state' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
    
    $self->{maps_counters}->{datastore} = [
        { label => 'read-latency', nlabel => 'host.datastore.latency.read.milliseconds', set => {
                key_values => [ { name => 'read_latency' }, { name => 'display' } ],
                output_template => 'read : %s ms',
                perfdatas => [
                    { label => 'trl', value => 'read_latency_absolute', template => '%s', unit => 'ms', 
                      min => 0, label_extra_instance => 1 },
                ],
            }
        },
        { label => 'write-latency', nlabel => 'host.datastore.latency.write.milliseconds', set => {
                key_values => [ { name => 'write_latency' }, { name => 'display' } ],
                output_template => 'write : %s ms',
                perfdatas => [
                    { label => 'twl', value => 'write_latency_absolute', template => '%s', unit => 'ms', 
                      min => 0, label_extra_instance => 1 },
                ],
            }
        },
    ];
}

sub prefix_host_output {
    my ($self, %options) = @_;

    return "Host '" . $options{instance_value}->{display} . "' : ";
}

sub host_long_output {
    my ($self, %options) = @_;

    return "checking host '" . $options{instance_value}->{display} . "'";
}

sub prefix_datastore_output {
    my ($self, %options) = @_;

    return "datastore '" . $options{instance_value}->{display} . "' latency : ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        "esx-hostname:s"        => { name => 'esx_hostname' },
        "filter"                => { name => 'filter' },
        "scope-datacenter:s"    => { name => 'scope_datacenter' },
        "scope-cluster:s"       => { name => 'scope_cluster' },
        "datastore-name:s"      => { name => 'datastore_name' },
        "filter-datastore:s"    => { name => 'filter_datastore' },
        "unknown-status:s"      => { name => 'unknown_status', default => '%{status} !~ /^connected$/i' },
        "warning-status:s"      => { name => 'warning_status', default => '' },
        "critical-status:s"     => { name => 'critical_status', default => '' },
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    
    $self->change_macros(macros => ['unknown_status', 'warning_status', 'critical_status']);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{host} = {};
    my $response = $options{custom}->execute(params => $self->{option_results},
        command => 'datastorehost');

    foreach my $host_id (keys %{$response->{data}}) {
        my $host_name = $response->{data}->{$host_id}->{name};
        $self->{host}->{$host_name} = { display => $host_name, 
            datastore => {}, 
            global => {
                state => $response->{data}->{$host_id}->{state},    
            },
        };
        
        foreach my $ds_id (sort keys %{$response->{data}->{$host_id}->{datastore}}) {
            $self->{host}->{$host_name}->{datastore}->{$ds_id} = {
                display => $ds_id, 
                read_latency => $response->{data}->{$host_id}->{datastore}->{$ds_id}->{'datastore.totalReadLatency.average'},
                write_latency => $response->{data}->{$host_id}->{datastore}->{$ds_id}->{'datastore.totalWriteLatency.average'},
            };
        }
    }
}

1;

__END__

=head1 MODE

Check ESX datastore latency.

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

=item B<--datastore-name>

Datastore to check.
If not set, we check all datastores.

=item B<--filter-datastore>

Datastore name is a regexp.

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
Can be: 'read-latency', 'write-latency'.

=item B<--critical-*>

Threshold critical.
Can be: 'read-latency', 'write-latency'.

=back

=cut
