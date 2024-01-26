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

package apps::ceph::restapi::mode::health;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = 'health status is ' . $self->{result_values}->{status};
    if ($self->{result_values}->{message} ne '') {
        $msg .= ' [message: ' . $self->{result_values}->{message} . ']';
    }

    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' }
    ];

    $self->{maps_counters}->{global} = [
        { 
            label => 'status',
            type => 2,
            warning_default => '%{status} =~ /warn/i',
            critical_default => '%{status} =~ /error/i',
            set => {
                key_values => [ { name => 'status' }, { name => 'message' } ],
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
    
    $options{options}->add_options(arguments => {});

    $self->{cache_status} = centreon::plugins::statefile->new(%options);

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $health = $options{custom}->request_api(endpoint => '/api/health/full');
    my $map_status = { HEALTH_OK => 'ok', HEALTH_ERR => 'error', HEALTH_WARN => 'warn' };
    $self->{global} = { status => $map_status->{ $health->{health}->{status} } };

    my ($message, $append) = ('', '');
    foreach (@{$health->{health}->{checks}}) {
        $message .= $append . $_->{summary}->{message};
        $append = ', ';
    }

    $self->{global}->{message} = $message;
}

1;

__END__

=head1 MODE

Check overall cluster status.

=over 8

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '%{status} =~ /warn/i')
You can use the following variables: %{status}, %{message}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} =~ /error/i').
You can use the following variables: %{status}, %{message}

=back

=cut
