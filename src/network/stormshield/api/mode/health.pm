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

package network::stormshield::api::mode::health;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_service_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "health: %s",
        $self->{result_values}->{health}
    );
}

sub firewall_long_output {
    my ($self, %options) = @_;

    return "checking firewall '" . $options{instance_value}->{display} . "'";
}

sub prefix_firewall_output {
    my ($self, %options) = @_;

    return "firewall '" . $options{instance_value}->{display} . "' ";
}

sub prefix_service_output {
    my ($self, %options) = @_;

    return "service '" . $options{instance_value}->{service} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'firewalls', type => 3, cb_prefix_output => 'prefix_firewall_output', cb_long_output => 'firewall_long_output',
          indent_long_output => '    ', message_multiple => 'All firewalls are ok',
            group => [
                 { name => 'services', display_long => 1, cb_prefix_output => 'prefix_service_output',  message_multiple => 'all services are ok', type => 1, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{services} = [
        {
            label => 'service-status',
            type => 2,
            warning_default => '%{health} =~ /minor/i',
            critical_default => '%{health} =~ /major/i',
            set => {
                key_values => [ { name => 'health' }, { name => 'service' } ],
                closure_custom_output => $self->can('custom_service_status_output'),
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
        'filter-serial:s' => { name => 'filter_serial' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $health = $options{custom}->request(command => 'monitor health');

    $self->{firewalls} = {};
    foreach my $label (keys %$health) {
        next if ($label eq 'MAIN');

        next if (defined($self->{option_results}->{filter_serial}) && $self->{option_results}->{filter_serial} ne '' &&
            $label !~ /$self->{option_results}->{filter_serial}/);
        
        $self->{firewalls}->{$label} = {
            display => $label,
            services => {}
        };

        foreach my $service (keys %{$health->{$label}}) {
            $self->{firewalls}->{$label}->{services}->{$service} = {
                service => $service,
                health => $health->{$label}->{$service}
            };
        }
    }
}

1;

__END__

=head1 MODE

Check health.

=over 8

=item B<--filter-serial>

Filter by firewalls by serial (can be a regexp).

=item B<--unknown-service-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{health}, %{service}

=item B<--warning-service-status>

Define the conditions to match for the status to be WARNING (default: '%{health} =~ /minor/i').
You can use the following variables: %{health}, %{service}

=item B<--critical-service-status>

Define the conditions to match for the status to be CRITICAL (default: '%{health} =~ /major/i').
You can use the following variables: %{health}, %{service}

=back

=cut
