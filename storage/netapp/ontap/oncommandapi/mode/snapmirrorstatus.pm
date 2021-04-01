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

package storage::netapp::ontap::oncommandapi::mode::snapmirrorstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf("State is '%s', Update is '%s'", $self->{result_values}->{state}, $self->{result_values}->{update});
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{source_location} = $options{new_datas}->{$self->{instance} . '_source_location'};
    $self->{result_values}->{state} = $options{new_datas}->{$self->{instance} . '_mirror_state'};
    $self->{result_values}->{update} = $options{new_datas}->{$self->{instance} . '_is_healthy'} ? "healthy" : "not healthy";

    return 0;
}

sub prefix_output {
    my ($self, %options) = @_;

    return "Snap mirror '" . $options{instance_value}->{source_location} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'snapmirrors', type => 1, cb_prefix_output => 'prefix_output', message_multiple => 'All snap mirrors status are ok' },
    ];
    
    $self->{maps_counters}->{snapmirrors} = [
        { label => 'status', set => {
                key_values => [ { name => 'source_location' }, { name => 'mirror_state' }, { name => 'is_healthy' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s'     => { name => 'filter_name' },
        'warning-status:s'  => { name => 'warning_status' },
        'critical-status:s' => { name => 'critical_status', default => '%{state} !~ /snapmirrored/i || %{update} =~ /not healthy/i' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
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
            mirror_state => $snapmirror->{mirror_state},
            is_healthy => $snapmirror->{is_healthy},
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

Check NetApp snap mirrors status.

=over 8

=item B<--filter-name>

Filter snapmirror name (can be a regexp).

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{state}, %{update}

=item B<--critical-status>

Set critical threshold for status (Default: '%{state} !~ /snapmirrored/i || %{update} =~ /not healthy/i').
Can used special variables like: %{state}, %{update}

=back

=cut
