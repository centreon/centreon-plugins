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

package network::fortinet::fortigate::restapi::mode::health;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub prefix_vdom_output {
    my ($self, %options) = @_;

    return sprintf(
        "vdom '%s' ",
        $options{instance_value}->{name}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'vdoms', type => 1, cb_prefix_output => 'prefix_vdom_output', message_multiple => 'All vdom firewall health are ok' }
    ];
    
   $self->{maps_counters}->{vdoms} = [
        {
            label => 'health',
            type => 2,
            critical_default => '%{status} !~ /success/i',
            set => {
                key_values => [
                    { name => 'status' }, { name => 'name' }
                ],
                output_template => "health status: %s",
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
        'filter-vdom:s' => { name => 'filter_vdom' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $resources = $options{custom}->request_api(
        endpoint => '/api/v2/monitor/firewall/health/select/',
        get_param => ['global=1']
    );

    $self->{vdoms} = {};

    # Handle both array and hash response
    $resources = [ $resources ] if ref $resources eq 'HASH';

    foreach my $resource (@$resources) {
        next if (defined($self->{option_results}->{filter_vdom}) && $self->{option_results}->{filter_vdom} ne '' &&
            $resource->{vdom} !~ /$self->{option_results}->{filter_vdom}/);

        $self->{vdoms}->{ $resource->{vdom} } = {
            name => $resource->{vdom},
            status => $resource->{status}
        };
    }
}

1;

__END__

=head1 MODE

Check firewall health.

=over 8

=item B<--filter-vdom>

Filter vdom by name.

=item B<--unknown-health>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{status}, %{name}

=item B<--warning-health>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{status}, %{name}

=item B<--critical-health>

Define the conditions to match for the status to be CRITICAL (default: '%{status} !~ /success/i').
You can use the following variables: %{status}, %{name}

=back

=cut
