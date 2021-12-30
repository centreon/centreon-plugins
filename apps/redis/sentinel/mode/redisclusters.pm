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

package apps::redis::sentinel::mode::redisclusters;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "status: %s",
        $self->{result_values}->{status}
    );
}

sub prefix_cluster_output {
    my ($self, %options) = @_;

    return "cluster '" . $options{instance} . "' ";
}

sub cluster_long_output {
    my ($self, %options) = @_;

    return "checking cluster '" . $options{instance} . "'";
}

sub prefix_instance_output {
    my ($self, %options) = @_;

    return "instance '" . $options{instance_value}->{address} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'clusters', type => 3, cb_prefix_output => 'prefix_cluster_output', cb_long_output => 'cluster_long_output', indent_long_output => '    ', message_multiple => 'All redis clusters are ok', 
            group => [
                { name => 'global', type => 0, skipped_code => { -10 => 1 } },
                { name => 'instances', type => 1, display_long => 1, cb_prefix_output => 'prefix_instance_output', message_multiple => 'All instances are ok', skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'group-transition-change', nlabel => 'nsrp.group.transition.change.count', set => {
                key_values => [ { name => 'cnt_state_change', diff => 1 } ],
                output_template => 'number of state transition events: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{instances} = [
        {
            label => 'status',
            type => 2,
            unknown_default => '%{status} =~ /undefined/i',
            critical_default => '%{status} =~ /ineligible|inoperable/i',
            set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->command(command => 'sentinel masters');

    $self->{clusters} = {};
    foreach my $entry (@$results) {
        use Data::Dumper; print Data::Dumper::Dumper($entry);
    }
}

1;

__END__

=head1 MODE

Check redis instances of clusters.

=over 8

=item B<--unknown-status>

Set unknown threshold for status (Default: '%{status} =~ /undefined/i').
Can used special variables like: %{status}, %{statusLast}

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{status}, %{statusLast}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /ineligible|inoperable/i').
Can used special variables like: %{status}, %{statusLast}

=item B<--warning-*> B<--critical-*>

Threshold warning.
Can be: 'group-transition-change'.

=back

=cut
