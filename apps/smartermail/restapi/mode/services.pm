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
# Authors : Roman Morandell - ivertix
#

package apps::smartermail::restapi::mode::services;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return 'state is ' . $self->{result_values}->{state};
}

sub prefix_service_output {
    my ($self, %options) = @_;

    return "Service '" . $options{instance_value}->{display} ."' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'services', type => 1, cb_prefix_output => 'prefix_service_output', message_multiple => 'All services are ok' }
    ];

    $self->{maps_counters}->{services} = [
        { label => 'status', type => 2, critical_default => '%{state} !~ /running/', set => {
                key_values => [ { name => 'state' }, { name => 'display' } ],
                closure_custom_perfdata => sub { return 0; },
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-service:s' => { name => 'filter_service' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->request_api(endpoint => '/settings/sysadmin/services');

    $self->{services} = {};
    foreach my $svc_name (keys %{$results->{services}}) {
        if (defined($self->{option_results}->{filter_service}) && $self->{option_results}->{filter_service} ne '' &&
            $svc_name !~ /$self->{option_results}->{filter_service}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $svc_name  . "': no matching filter.", debug => 1);
            next;
        }

        $self->{services}->{$svc_name} = {
            display => $svc_name,
            state => $results->{services}->{$svc_name} =~ /True|1/i ? 'running' : 'inactive'
        };
    }
}


1;

__END__

=head1 MODE

Check services.

=over 8

=item B<--filter-service>

Only display some counters (regexp can be used).
(Example: --filter-service='spool|smtp|pop')

=item B<--unknown-status>

Set unknown threshold for status.
Can used special variables like: %{state}, %{display}

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{state}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{state} !~ /running/').
Can used special variables like: %{state}, %{display}

=back

=cut
