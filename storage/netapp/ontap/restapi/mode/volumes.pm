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

package storage::netapp::ontap::restapi::mode::volumes;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return 'state: ' . $self->{result_values}->{state};
}

sub custom_usage_output {
    my ($self, %options) = @_;
    
    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total_space});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used_space});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free_space});
    return sprintf(
        'space usage total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used_space},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free_space}
    );
}

sub prefix_volume_output {
    my ($self, %options) = @_;

    return "Volume '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'volumes', type => 1, cb_prefix_output => 'prefix_volume_output', message_multiple => 'All volumes are ok' }
    ];
    
    $self->{maps_counters}->{volumes} = [
        { label => 'status', type => 2, critical_default => '%{state} !~ /online/i', set => {
                key_values => [ { name => 'state' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'usage', nlabel => 'volume.space.usage.bytes', set => {
                key_values => [ { name => 'used_space' }, { name => 'free_space' }, { name => 'prct_used_space' }, { name => 'prct_free_space' }, { name => 'total_space' }, { name => 'display' },  ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total_space',
                      unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'usage-free', nlabel => 'volume.space.free.bytes', display_ok => 0, set => {
                key_values => [ { name => 'free_space' }, { name => 'used_space' }, { name => 'prct_used_space' }, { name => 'prct_free_space' }, { name => 'total_space' }, { name => 'display' },  ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total_space',
                      unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'usage-prct', nlabel => 'volume.space.usage.percentage', display_ok => 0, set => {
                key_values => [ { name => 'prct_used_space' }, { name => 'used_space' }, { name => 'free_space' }, { name => 'prct_free_space' }, { name => 'total_space' }, { name => 'display' },  ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100,
                      unit => '%', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'read', nlabel => 'volume.io.read.usage.bytespersecond', display_ok => 0, set => {
                key_values => [ { name => 'read' } ],
                output_template => 'read: %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%d', unit => 'B/s', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'write', nlabel => 'volume.io.write.usage.bytespersecond', display_ok => 0, set => {
                key_values => [ { name => 'write' } ],
                output_template => 'write: %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%d', unit => 'B/s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'read-iops', nlabel => 'volume.io.read.usage.iops', set => {
                key_values => [ { name => 'read_iops' } ],
                output_template => 'read iops: %s',
                perfdatas => [
                    { template => '%s', unit => 'iops', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'write-iops', nlabel => 'volume.io.write.usage.iops', set => {
                key_values => [ { name => 'write_iops' } ],
                output_template => 'write iops: %s',
                perfdatas => [
                    { template => '%s', unit => 'iops', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'read-latency', nlabel => 'volume.io.read.latency.milliseconds', set => {
                key_values => [ { name => 'read_latency' } ],
                output_template => 'read latency: %s ms',
                perfdatas => [
                    { template => '%s', unit => 'ms', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'write-latency', nlabel => 'volume.io.write.latency.milliseconds', set => {
                key_values => [ { name => 'write_latency' } ],
                output_template => 'write latency: %s ms',
                perfdatas => [
                    { template => '%s', unit => 'ms', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'filter-name:s'         => { name => 'filter_name' },
        'filter-vserver-name:s' => { name => 'filter_vserver_name' }
    });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $volumes = $options{custom}->request_api(endpoint => '/api/storage/volumes?fields=*');

    $self->{volumes} = {};
    foreach (@{$volumes->{records}}) {
        my $name = defined($_->{svm}) && $_->{svm}->{name} ne '' ?
            $_->{svm}->{name} . ':' . $_->{name} :
            $_->{name};
        if (defined($self->{option_results}->{filter_vserver_name}) && $self->{option_results}->{filter_vserver_name} ne '' &&
            defined($_->{svm}) && $_->{svm}->{name} ne '' &&  $_->{svm}->{name} !~ /$self->{option_results}->{filter_vserver_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $_->{svm}->{name} . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $_->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping volume '" . $_->{name} . "': no matching filter.", debug => 1);
            next;
        }

        $self->{volumes}->{$name} = {
            display => $name,
            state => $_->{state},

            total_space => $_->{space}->{size},
            used_space => $_->{space}->{used},
            free_space => $_->{space}->{available},
            prct_used_space => (defined($_->{space}->{size}) && $_->{space}->{size} > 0) ? $_->{space}->{used} * 100 / $_->{space}->{size} : undef,
            prct_free_space => (defined($_->{space}->{size}) && $_->{space}->{size} > 0) ? $_->{space}->{available} * 100 / $_->{space}->{size} : undef,

            read          => $_->{metric}->{throughput}->{read},
            write         => $_->{metric}->{throughput}->{write},
            read_iops     => $_->{metric}->{iops}->{read},
            write_iops    => $_->{metric}->{iops}->{write},
            read_latency  => $_->{metric}->{latency}->{read},
            write_latency => $_->{metric}->{latency}->{write}
        };
    }

    if (scalar(keys %{$self->{volumes}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No volume found");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check volumes.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^usage$'

=item B<--filter-name>

Filter volumes by volume name (can be a regexp).

=item B<--filter-vserver-name>

Filter volumes by vserver name (can be a regexp).

=item B<--unknown-status>

Set unknown threshold for status.
Can used special variables like: %{state}, %{display}

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{state}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{state} !~ /online/i').
Can used special variables like: %{state}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'usage' (B), 'usage-free' (B), 'usage-prct' (%),
'read' (B/s), 'read-iops', 'write' (B/s), 'write-iops',
'read-latency' (ms), 'write-latency' (ms).

=back

=cut
