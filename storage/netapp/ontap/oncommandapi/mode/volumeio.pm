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

package storage::netapp::ontap::oncommandapi::mode::volumeio;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_output {
    my ($self, %options) = @_;

    return "Volume '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'volumes', type => 1, cb_prefix_output => 'prefix_output', message_multiple => 'All volumes IOs are ok' },
    ];
    
    $self->{maps_counters}->{volumes} = [
        { label => 'read-iops', set => {
                key_values => [ { name => 'read_ops' }, { name => 'name' } ],
                output_template => 'Read IOPS: %.2f ops/s',
                perfdatas => [
                    { label => 'read_iops', value => 'read_ops', template => '%.2f',
                      min => 0, unit => 'ops/s', label_extra_instance => 1, instance_use => 'name' },
                ],
            }
        },
        { label => 'write-iops', set => {
                key_values => [ { name => 'write_ops' }, { name => 'name' } ],
                output_template => 'Write IOPS: %.2f ops/s',
                perfdatas => [
                    { label => 'write_iops', value => 'write_ops', template => '%.2f',
                      min => 0, unit => 'ops/s', label_extra_instance => 1, instance_use => 'name' },
                ],
            }
        },
        { label => 'other-iops', set => {
                key_values => [ { name => 'other_ops' }, { name => 'name' } ],
                output_template => 'Other IOPS: %.2f ops/s',
                perfdatas => [
                    { label => 'other_iops', value => 'other_ops', template => '%.2f',
                      min => 0, unit => 'ops/s', label_extra_instance => 1, instance_use => 'name' },
                ],
            }
        },
        { label => 'avg-latency', set => {
                key_values => [ { name => 'avg_latency' }, { name => 'name' } ],
                output_template => 'Average latency: %.2f ms',
                perfdatas => [
                    { label => 'avg_latency', value => 'avg_latency', template => '%.2f',
                      min => 0, unit => 'ms', label_extra_instance => 1, instance_use => 'name' },
                ],
            }
        },
        { label => 'read-latency', set => {
                key_values => [ { name => 'read_latency' }, { name => 'name' } ],
                output_template => 'Read latency: %.2f ms',
                perfdatas => [
                    { label => 'read_latency', value => 'read_latency', template => '%.2f',
                      min => 0, unit => 'ms', label_extra_instance => 1, instance_use => 'name' },
                ],
            }
        },
        { label => 'write-latency', set => {
                key_values => [ { name => 'write_latency' }, { name => 'name' } ],
                output_template => 'Write latency: %.2f ms',
                perfdatas => [
                    { label => 'write_latency', value => 'write_latency', template => '%.2f',
                      min => 0, unit => 'ms', label_extra_instance => 1, instance_use => 'name' },
                ],
            }
        },
        { label => 'other-latency', set => {
                key_values => [ { name => 'other_latency' }, { name => 'name' } ],
                output_template => 'Other latency: %.2f ms',
                perfdatas => [
                    { label => 'other_latency', value => 'other_latency', template => '%.2f',
                      min => 0, unit => 'ms', label_extra_instance => 1, instance_use => 'name' },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-name:s'  => { name => 'filter_name' },
        'filter-state:s' => { name => 'filter_state' },
        'filter-style:s' => { name => 'filter_style' },
        'filter-type:s'  => { name => 'filter_type' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my %names_hash;
    my $names = $options{custom}->get(path => '/volumes');
    foreach my $volume (@{$names}) {
        $names_hash{$volume->{key}} = {
            name => $volume->{name},
            state => $volume->{state},
            style => $volume->{style},
            vol_type => $volume->{vol_type},
        };
    }

    my $args = '';
    my $append = '';
    foreach my $metric ('read_ops', 'write_ops', 'other_ops', 'avg_latency', 'read_latency', 'write_latency', 'other_latency') {
        $args .= $append . 'name=' . $metric;
        $append = '&';
    }

    my $result = $options{custom}->get(path => '/volumes/metrics', args => $args);

    foreach my $volume (@{$result}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            defined($names_hash{$volume->{resource_key}}) && $names_hash{$volume->{resource_key}}->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $names_hash{$volume->{resource_key}}->{name} . "': no matching filter name.", debug => 1);
            next;
        }

        if (defined($self->{option_results}->{filter_state}) && $self->{option_results}->{filter_state} ne '' &&
            defined($names_hash{$volume->{resource_key}}) && $names_hash{$volume->{resource_key}}->{state} !~ /$self->{option_results}->{filter_state}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $names_hash{$volume->{resource_key}}->{name} . "': no matching filter state : '" . $names_hash{$volume->{resource_key}}->{state} . "'", debug => 1);
            next;
        }

        if (defined($self->{option_results}->{filter_style}) && $self->{option_results}->{filter_style} ne '' &&
            defined($names_hash{$volume->{resource_key}}) && $names_hash{$volume->{resource_key}}->{style} !~ /$self->{option_results}->{filter_style}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $names_hash{$volume->{resource_key}}->{name} . "': no matching filter style : '" . $names_hash{$volume->{resource_key}}->{style} . "'", debug => 1);
            next;
        }

        if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' &&
            defined($names_hash{$volume->{resource_key}}) && $names_hash{$volume->{resource_key}}->{vol_type} !~ /$self->{option_results}->{filter_type}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $names_hash{$volume->{resource_key}}->{name} . "': no matching filter type : '" . $names_hash{$volume->{resource_key}}->{vol_type} . "'", debug => 1);
            next;
        }

        foreach my $metric (@{$volume->{metrics}}) {
            $self->{volumes}->{$volume->{resource_key}}->{name} = $names_hash{$volume->{resource_key}}->{name};
            $self->{volumes}->{$volume->{resource_key}}->{read_ops} = ${$metric->{samples}}[0]->{value} if ($metric->{name} eq 'read_ops');
            $self->{volumes}->{$volume->{resource_key}}->{write_ops} = ${$metric->{samples}}[0]->{value} if ($metric->{name} eq 'write_ops');
            $self->{volumes}->{$volume->{resource_key}}->{other_ops} = ${$metric->{samples}}[0]->{value} if ($metric->{name} eq 'other_ops');
            $self->{volumes}->{$volume->{resource_key}}->{avg_latency} = ${$metric->{samples}}[0]->{value} / 1000 if ($metric->{name} eq 'avg_latency');
            $self->{volumes}->{$volume->{resource_key}}->{read_latency} = ${$metric->{samples}}[0]->{value} / 1000 if ($metric->{name} eq 'read_latency');
            $self->{volumes}->{$volume->{resource_key}}->{write_latency} = ${$metric->{samples}}[0]->{value} / 1000 if ($metric->{name} eq 'write_latency');
            $self->{volumes}->{$volume->{resource_key}}->{other_latency} = ${$metric->{samples}}[0]->{value} / 1000 if ($metric->{name} eq 'other_latency');
        }
    }

    if (scalar(keys %{$self->{volumes}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No entry found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check NetApp volumes IOs.

=over 8

=item B<--filter-*>

Filter volume.
Can be: 'name', 'state', 'style', 'type' (can be a regexp).

=item B<--warning-*>

Threshold warning.
Can be: 'read-iops', 'write-iops', 'other-iops',
'avg-latency', 'read-latency', 'write-latency', 'other-latency'.

=item B<--critical-*>

Threshold critical.
Can be: 'read-iops', 'write-iops', 'other-iops',
'avg-latency', 'read-latency', 'write-latency', 'other-latency'.

=back

=cut
