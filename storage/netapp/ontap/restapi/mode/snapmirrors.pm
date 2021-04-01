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

package storage::netapp::ontap::restapi::mode::snapmirrors;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'healthy: %s [state: %s] [transfer state: %s]',
        $self->{result_values}->{healthy},
        $self->{result_values}->{state},
        $self->{result_values}->{transfer_state}
    );
}

sub prefix_snapmirror_output {
    my ($self, %options) = @_;

    return "Snapmirror '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'snapmirrors', type => 1, cb_prefix_output => 'prefix_snapmirror_output', message_multiple => 'All snapmirrors are ok' }
    ];
    
    $self->{maps_counters}->{snapmirrors} = [
        { label => 'status', type => 2, critical_default => '%{healthy} ne "true" or %{state} eq "broken_off"', set => {
                key_values => [ { name => 'healthy' }, { name => 'state' }, { name => 'transfer_state' }, { name => 'display' } ],
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
        'filter-name:s' => { name => 'filter_name' }
    });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $snapmirrors = $options{custom}->request_api(endpoint => '/api/snapmirror/relationships?fields=*');

    $self->{snapmirrors} = {};
    foreach (@{$snapmirrors->{records}}) {
        my $name = $_->{source}->{path} . '-' . $_->{destination}->{path};
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping snapmirror '" . $name . "': no matching filter.", debug => 1);
            next;
        }

        $self->{snapmirrors}->{$name} = {
            display => $name,
            healthy => $_->{healthy} =~ /true|1/i ? 'true' : 'false',
            state => $_->{state},
            transfer_state => $_->{transfer}->{state}
        };
    }
    
    if (scalar(keys %{$self->{snapmirrors}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No snapmirror found");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check snapmirrors.

=over 8

=item B<--filter-name>

Filter snapmirror name (can be a regexp).

=item B<--unknown-status>

Set unknown threshold for status.
Can used special variables like: %{healthy}, %{state}, %{transfer_state}, %{display}

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{healthy}, %{state}, %{transfer_state}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{healthy} ne "true" or %{state} eq "broken_off"').
Can used special variables like: %{healthy}, %{state}, %{transfer_state}, %{display}

=back

=cut
