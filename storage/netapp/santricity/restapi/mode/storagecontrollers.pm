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

package storage::netapp::santricity::restapi::mode::storagecontrollers;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use Digest::MD5 qw(md5_hex);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'status: %s',
        $self->{result_values}->{status}
    );
}

sub ss_long_output {
    my ($self, %options) = @_;

    return "checking storage system '" . $options{instance_value}->{display} . "'";
}

sub prefix_ss_output {
    my ($self, %options) = @_;

    return "storage system '" . $options{instance_value}->{display} . "' ";
}

sub prefix_controller_output {
    my ($self, %options) = @_;

    return "controller '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'ss', type => 3, cb_prefix_output => 'prefix_ss_output', cb_long_output => 'ss_long_output', indent_long_output => '    ', message_multiple => 'All storage systems are ok',
            group => [
                { name => 'controllers', display_long => 1, cb_prefix_output => 'prefix_controller_output',  message_multiple => 'controllers are ok', type => 1, skipped_code => { -10 => 1 } }
            ]
        }
    ];
    
    $self->{maps_counters}->{controllers} = [
        {
            label => 'controller-status',
            type => 2,
            unknown_default => '%{status} =~ /unknown/i',
            warning_default => '%{status} =~ /rpaParErr|degraded/i',
            critical_default => '%{status} =~ /failed/i',
            set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'cpu-utilization', nlabel => 'volume.cpu.utilization.percentage', set => {
                key_values => [ { name => 'cpu_util', per_second => 1 }, { name => 'display' } ],
                output_template => 'cpu usage: %.2f %%',
                perfdatas => [
                    { template => '%d', unit => '%', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'read', nlabel => 'volume.io.read.usage.bytespersecond', set => {
                key_values => [ { name => 'read_bytes', per_second => 1 }, { name => 'display' } ],
                output_template => 'read: %s %s/s',
                output_change_bytes => 1, 
                perfdatas => [
                    { template => '%d', unit => 'B/s', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'write', nlabel => 'volume.io.write.usage.bytespersecond', set => {
                key_values => [ { name => 'write_bytes', per_second => 1 }, { name => 'display' } ],
                output_template => 'write: %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%d', unit => 'B/s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'read-iops', nlabel => 'system.io.read.usage.iops', set => {
                key_values => [ { name => 'read_iops', per_second => 1 }, { name => 'display' } ],
                output_template => 'read: %.2f iops',
                perfdatas => [
                    { template => '%.2f', unit => 'iops', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'write-iops', nlabel => 'system.io.write.usage.iops', set => {
                key_values => [ { name => 'write_iops', per_second => 1 }, { name => 'display' } ],
                output_template => 'write: %.2f iops',
                perfdatas => [
                    { template => '%.2f', unit => 'iops', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'filter-storage-name:s'    => { name => 'filter_storage_name' },
        'filter-controller-name:s' => { name => 'filter_controller_name' }
    });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->execute_storages_request(
        endpoints => [
            { endpoint => '/controllers' },
            { endpoint => '/controller-statistics', get_param => 'usecache=false' }
        ],
        filter_name => $self->{option_results}->{filter_storage_name}
    );

    my $mapping_controller = {};
    $self->{ss} = {};
    foreach (@{$results->{storages}}) {
        my $storage_name = $_->{name};

        $self->{ss}->{$storage_name} = {
            display => $storage_name,
            controllers => {}
        };

        next if (!defined($_->{'/controllers'}));

        foreach my $entry (@{$_->{'/controllers'}}) {
            my $name = $entry->{physicalLocation}->{label} ne '' ? $entry->{physicalLocation}->{label} : 
                $entry->{physicalLocation}->{locationPosition} . ':' . $entry->{physicalLocation}->{slot};

            next if (defined($options{filter_controller_name}) && $options{filter_controller_name} ne '' &&
                $name !~ /$options{filter_controller_name}/);

            $mapping_controller->{ $entry->{id} } = $name;
            $self->{ss}->{$storage_name}->{controllers}->{ $name } = {
                display => $name,
                status => $entry->{status}
            };
        }

        foreach my $entry (@{$_->{'/controller-statistics'}}) {
            next if (!defined($mapping_controller->{ $entry->{controllerId} }));

            $self->{ss}->{$storage_name}->{controllers}->{ $mapping_controller->{ $entry->{controllerId} } }->{write_bytes} = $entry->{writeBytesTotal};
            $self->{ss}->{$storage_name}->{controllers}->{ $mapping_controller->{ $entry->{controllerId} } }->{read_bytes} = $entry->{readBytesTotal};
            $self->{ss}->{$storage_name}->{controllers}->{ $mapping_controller->{ $entry->{controllerId} } }->{read_iops} = $entry->{readIopsTotal};
            $self->{ss}->{$storage_name}->{controllers}->{ $mapping_controller->{ $entry->{controllerId} } }->{write_iops} = $entry->{writeIopsTotal};
            $self->{ss}->{$storage_name}->{controllers}->{ $mapping_controller->{ $entry->{controllerId} } }->{cpu_util} = $entry->{cpuUtilizationStats}->[0]->{sumCpuUtilization};
        }
    }

    $self->{cache_name} = 'netapp_santricity_' . $self->{mode} . '_' . $options{custom}->get_hostname()  . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_storage_name}) ? md5_hex($self->{option_results}->{filter_storage_name}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_controller_name}) ? md5_hex($self->{option_results}->{filter_controller_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check storage controllers.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='controller-status'

=item B<--filter-storage-name>

Filter storage name (can be a regexp).

=item B<--filter-controller-name>

Filter controller name (can be a regexp).

=item B<--unknown-controller-status>

Set unknown threshold for status (Default: '%{status} =~ /unknown/i').
Can used special variables like: %{status}, %{display}

=item B<--warning-controller-status>

Set warning threshold for status (Default: '%{status} =~ /rpaParErr|degraded/i').
Can used special variables like: %{status}, %{display}

=item B<--critical-controller-status>

Set critical threshold for status (Default: '%{status} =~ /failed/i').
Can used special variables like: %{status}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'cpu-utilization' (%), 'read' (B/s), 'write' (B/s), 'read-iops', 'write-iops'.

=back

=cut
