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
            critical_default => '%{api_status} ne "ok"',
            set              => {
                key_values                     => [ { name => 'api_status' } ],
                output_template => "api returned '%{api_status}'",
            }
        }
    ];
}

sub manage_selection {
    my ($self, %options) = @_;
    my $response = $options{custom}->request_api(
        method          => "GET",
        endpoint        => "ping",
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

Check the status of a Vates Xen Orchestra appliance

=over 8

=item B<--warning-api-status>

Define the conditions to match for the API status to be WARNING. You can use the following
variables: C<%{api_status}>.

=item B<--critical-api-status>

Define the conditions to match for the API status to be CRITICAL. You can use the following
variables: C<%{api_status}>.
Default: %{api_status} ne "ok"

=back

=cut
