#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package apps::virtualization::vates::xenorchestra::mode::status;
use strict;
use warnings;
use base qw(centreon::plugins::templates::counter);
use centreon::plugins::misc qw/is_empty/;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw/json_decode/;


sub new {
    my ($class, %options) = @_;

    my $self = $class->SUPER::new(package => __PACKAGE__, force_new_perfdata => 1, %options);

    $options{options}->add_options(
        arguments => {}
    );

    return $self;
}


sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'status', type => COUNTER_TYPE_GLOBAL, message_separator => ' - ' }
    ];

    $self->{maps_counters}->{status} = [
        {
            label            => 'api-status',
            type             => COUNTER_TYPE_GROUP,
            set              => {
                key_values                     => [ { name => 'api_status' } ],
                output_template => "api returned '%{api_status}'",
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub manage_selection {
    my ($self, %options) = @_;

    my $response = $options{custom}->request_api(
        method => "GET",
        endpoint      => "ping",
        critical_status => '%{http_code} < 200 or %{http_code} >= 300',
    );
    my $json;
    eval {
        $json = json_decode($response, booleans_as_strings => 1, silence => 1);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response, use --debug to see the api output");
        $self->{output}->exit(2);
    }

    if ($json->{error}) {
        $self->{output}->set_status(exit_litteral => "CRITICAL");
        $self->{status} = { api_status => $json->{error}};
    }
    elsif ($json->{result} && $json->{result} eq "pong") {
        $self->{status} = { api_status => "ok"};
    }
    else {
        $self->{status} = { api_status => $response};
    }

}

1;

__END__

=head1 MODE

Check the status of a Vates Xen Orchestra pool: master host availability, power state and High Availability if configured.

=over 8

=item B<--pool-uuid>

Identify the pool by its exact uuid.

=item B<--pool-name>

Identify the pool by its name (only one pool is expected).

=item B<--is-ha>

Convenience shortcut to check that HA is enabled/disabled as expected, without having to write a
C<--critical-ha-status> expression by hand. Set to C<true> or C<1> to require HA enabled (equivalent
to the default C<--critical-ha-status>); any other value disables the HA status check entirely
(equivalent to C<--critical-ha-status=''>).

=item B<--warning-master-status>

Define the conditions to match for the master host status to be WARNING. You can use the following
variables: C<%{display}>, C<%{master_name}>, C<%{master_power_state}>.

=item B<--critical-master-status>

Define the conditions to match for the master host status to be CRITICAL. You can use the following
variables: C<%{display}>, C<%{master_name}>, C<%{master_power_state}>.
Default: C<%{master_power_state} !~ /^Running/i>

=item B<--warning-ha-status>

Define the conditions to match for the pool's High Availability status to be WARNING. You can use
the following variable: C<%{ha_enabled}>.

=item B<--critical-ha-status>

Define the conditions to match for the pool's High Availability status to be CRITICAL. You can use
the following variable: C<%{ha_enabled}>.
Default: C<%{ha_enabled} !~ /^true/i>

=back

=cut
