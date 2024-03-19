#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package apps::infor::eventhub::api::mode::publisher;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "status is '%s'",
        ($self->{result_values}->{connected} eq "true") ? "connected" : "not connected"
    );
}

sub prefix_publisher_output {
    my ($self, %options) = @_;

    return "Publisher '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name => 'publishers',
            type => 1,
            cb_prefix_output => 'prefix_publisher_output',
            message_multiple => 'All publishers are ok'
        }
    ];

    $self->{maps_counters}->{publishers} = [
        {
            label => 'status',
            type => 2,
            critical_default => '%{connected} !~ /true/',
            set => {
                key_values => [
                    { name => 'connected' },
                    { name => 'name' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'queued-events', nlabel => 'publisher.events.queued.count', set => {
                key_values => [
                    { name => 'queued_events' },
                    { name => 'name' }
                ],
                output_template => 'Queued events: %d',
                perfdatas => [
                    { template => '%d', min => 0,
                      label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'subscribers', nlabel => 'publisher.subscribers.count', set => {
                key_values => [
                    { name => 'subscribers' },
                    { name => 'name' }
                ],
                output_template => 'Subscribers: %d',
                perfdatas => [
                    { template => '%d', min => 0,
                      label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
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

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->get_publishers;

    foreach my $entry (@{$result}) {
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne ''
            && $entry->{name} !~ /$self->{option_results}->{filter_name}/);
        $self->{publishers}->{$entry->{name}} = {
            %{$entry}
        }
    }

    if (scalar(keys %{$self->{publishers}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No publishers found");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check publisher status.

=over 8

=item B<--filter-name>

Filter by name.

=item B<--warning-status>

Set warning threshold for status.
Can use special variables like: %{connected}, %{name}}.

=item B<--critical-status>

Set critical threshold for status (Default: "%{connected} !~ /true/").
Can use special variables like: %{connected}, %{name}}.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'queued-events', 'subscribers'.

=back

=cut