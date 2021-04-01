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

package storage::netapp::ontap::oncommandapi::mode::snapmirrorusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_output {
    my ($self, %options) = @_;

    return "Snap mirror '" . $options{instance_value}->{source_location} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'snapmirrors', type => 1, cb_prefix_output => 'prefix_output', message_multiple => 'All snap mirrors usage are ok' },
    ];
    
    $self->{maps_counters}->{snapmirrors} = [
        { label => 'last-transfer-duration', set => {
                key_values => [ { name => 'last_transfer_duration' }, { name => 'source_location' } ],
                output_template => 'Last transfer duration: %.2f s',
                perfdatas => [
                    { label => 'last_transfer_duration', value => 'last_transfer_duration', template => '%.2f',
                      min => 0, unit => 's', label_extra_instance => 1, instance_use => 'source_location' },
                ],
            }
        },
        { label => 'last-transfer-size', set => {
                key_values => [ { name => 'last_transfer_size' }, { name => 'source_location' } ],
                output_template => 'Last transfer size: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'last_transfer_size', value => 'last_transfer_size', template => '%d',
                      min => 0, unit => 'B', label_extra_instance => 1, instance_use => 'source_location' },
                ],
            }
        },
        { label => 'lag-time', set => {
                key_values => [ { name => 'lag_time' }, { name => 'source_location' } ],
                output_template => 'Lag time: %.2f s',
                perfdatas => [
                    { label => 'lag_time', value => 'lag_time', template => '%.2f',
                      min => 0, unit => 's', label_extra_instance => 1, instance_use => 'source_location' },
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
        'filter-name:s' => { name => 'filter_name' }
    });
   
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->get(path => '/snap-mirrors');

    foreach my $snapmirror (@{$result}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $snapmirror->{source_location} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $snapmirror->{source_location} . "': no matching filter name.", debug => 1);
            next;
        }

        $self->{snapmirrors}->{$snapmirror->{key}} = {
            source_location => $snapmirror->{source_location},
            last_transfer_duration => $snapmirror->{last_transfer_duration},
            last_transfer_size => $snapmirror->{last_transfer_size},
            lag_time => $snapmirror->{lag_time},
        }
    }

    if (scalar(keys %{$self->{snapmirrors}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No entry found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check NetApp snap mirrors usage.

=over 8

=item B<--filter-name>

Filter snapmirror name (can be a regexp).

=item B<--warning-*>

Threshold warning.
Can be: 'last-transfer-duration', 'last-transfer-size', 'lag-time'.

=item B<--critical-*>

Threshold critical.
Can be: 'last-transfer-duration', 'last-transfer-size', 'lag-time'.

=back

=cut
