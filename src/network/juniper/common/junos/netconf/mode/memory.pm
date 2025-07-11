#
# Copyright 2025 Centreon (http://www.centreon.com/)
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

package network::juniper::common::junos::netconf::mode::memory;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_message_output {
    my ($self, %options) = @_;

    return "Memory '" . $options{instance_value}->{name} . "' usage: ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'memory', type => 1, cb_prefix_output => 'prefix_message_output', message_multiple => 'All memory usages are ok' }
    ];

    $self->{maps_counters}->{memory} = [
        { label => 'usage-prct', nlabel => 'memory.usage.percentage', set => {
            key_values      => [ { name => 'mem_used' } ],
            output_template => '%.2f %%',
            perfdatas       => [
                { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
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
        'filter-name:s' => { name => 'filter_name' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->get_memory_infos();

    $self->{memory} = {};
    foreach (@$result) {
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
                 $_->{name} !~ /$self->{option_results}->{filter_name}/);

        $self->{memory}->{ $_->{name} } = $_;
    }
}

1;

__END__

=head1 MODE

Check memory usage.

=over 8

=item B<--filter-name>

Filter memory by name.

=item B<--warning-usage-prct>

Warning threshold for memory usage (%).

=item B<--critical-usage-prct>

Critical threshold for memory usage (%).

=back

=cut
