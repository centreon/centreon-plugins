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

package cloud::vmware::velocloud::restapi::mode::edgestatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf("State is '%s', Service State is '%s', HA State is '%s', Activation State is '%s'",
        $self->{result_values}->{edge_state},
        $self->{result_values}->{service_state},
        $self->{result_values}->{ha_state},
        $self->{result_values}->{activation_state});
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{edge_state} = $options{new_datas}->{$self->{instance} . '_edge_state'};
    $self->{result_values}->{service_state} = $options{new_datas}->{$self->{instance} . '_service_state'};
    $self->{result_values}->{ha_state} = $options{new_datas}->{$self->{instance} . '_ha_state'};
    $self->{result_values}->{activation_state} = $options{new_datas}->{$self->{instance} . '_activation_state'};
    
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'edges', type => 1, cb_prefix_output => 'prefix_output',
            message_multiple => 'All edges status are ok' },
    ];

    $self->{maps_counters}->{edges} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'edge_state' }, { name => 'service_state' }, { name => 'ha_state' },
                    { name => 'activation_state' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub prefix_output {
    my ($self, %options) = @_;

    return "Edge '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s'         => { name => 'filter_name' },
        'unknown-status:s'      => { name => 'unknown_status', default => '%{edge_state} =~ /NEVER_ACTIVATED/' },
        'warning-status:s'      => { name => 'warning_status', default => '' },
        'critical-status:s'     => { name => 'critical_status', default => '%{edge_state} !~ /CONNECTED/ && %{edge_state} !~ /NEVER_ACTIVATED/' },
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

    $self->{edges} = {};

    my $results = $options{custom}->list_edges;

    foreach my $edge (@{$results}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $edge->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $edge->{name} . "'.", debug => 1);
            next;
        }

        $self->{edges}->{$edge->{id}} = {
            display => $edge->{name},
            edge_state => $edge->{edgeState},
            service_state => $edge->{serviceState},
            ha_state => $edge->{haState},
            activation_state => $edge->{activationState}
        }
    }

    if (scalar(keys %{$self->{edges}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No edge found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check edge status.

=over 8

=item B<--filter-name>

Filter edge by name (Can be a regexp).

=item B<--unknown-status>

Set unknown threshold for status (Default: '%{edge_state} =~ /NEVER_ACTIVATED/').
Can used special variables like: %{edge_state}, %{service_state},
%{ha_state}, %{activation_state}.

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{edge_state}, %{service_state},
%{ha_state}, %{activation_state}.

=item B<--critical-status>

Set critical threshold for status (Default: '%{edge_state} !~ /CONNECTED/ && %{edge_state} !~ /NEVER_ACTIVATED/').
Can used special variables like: %{edge_state}, %{service_state},
%{ha_state}, %{activation_state}.

=back

=cut
