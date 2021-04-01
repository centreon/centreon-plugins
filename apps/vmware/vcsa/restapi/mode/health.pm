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

package apps::vmware::vcsa::restapi::mode::health;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub custom_status_output { 
    my ($self, %options) = @_;

    my $msg .= 'health is ' . $self->{result_values}->{health};
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'service', type => 1, cb_prefix_output => 'prefix_service_output', message_multiple => 'All services are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{service} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'health' }, { name => 'display' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub prefix_service_output {
    my ($self, %options) = @_;

    return "Service '" . $options{instance_value}->{display} ."' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments => {
        'filter-service:s'  => { name => 'filter_service' },
        'unknown-status:s'  => { name => 'unknown_status', default => '' },
        'warning-status:s'  => { name => 'warning_status', default => '' },
        'critical-status:s' => { name => 'critical_status', default => '%{health} !~ /green/' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => [
        'warning_status', 'critical_status', 'unknown_status',
    ]);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $endpoint = '/rest/appliance/health/';
    my @services = ('applmgmt', 'database-storage', 'load', 'mem', 'software-packages', 'storage', 'swap', 'system');
    $self->{service} = {};
    foreach (@services) {
        if (defined($self->{option_results}->{filter_service}) && $self->{option_results}->{filter_service} ne '' &&
            $_ !~ /$self->{option_results}->{filter_service}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $_  . "': no matching filter.", debug => 1);
            next;
        }

        my $result = $options{custom}->request_api(url_path => $endpoint . $_);
        $self->{service}->{$_} = { 
            display => $_,
            health => $result->{value}, 
        };
    }
}

1;

__END__

=head1 MODE

Check service health.

=over 8

=item B<--filter-service>

Filter service (can be a regexp).

=item B<--unknown-status>

Set unknown threshold for status.
Can used special variables like: %{health}, %{display}

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{health}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{health} !~ /green/').
Can used special variables like: %{health}, %{display}

=back

=cut
