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

package apps::atlassian::statuspage::custom::json;

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::misc qw(json_decode);

sub new {
    my ($class, %options) = @_;
    my $self = {};
    bless $self, $class;

    if (!defined($options{noptions})) {
        $options{options}->add_options(arguments => {
            'hostname:s'             => { name => 'hostname',     default => '' },
            'port:s'                 => { name => 'port' },
            'proto:s'                => { name => 'proto',        default => 'https' },
            'timeout:s'              => { name => 'timeout',      default => 30 },
            'api-path:s'             => { name => 'api_path',     default => '/api/v2/' },
            'unknown-http-status:s'  => { name => 'unknown_http_status' },
            'warning-http-status:s'  => { name => 'warning_http_status' },
            'critical-http-status:s' => { name => 'critical_http_status' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options, default_backend => 'curl');

    return $self;
}

sub check_options {
    my ($self, %options) = @_;

    $self->{output}->option_exit(short_msg => 'Need to specify --hostname option.')
        if ($self->{option_results}->{hostname} eq '');

    return 0;
}

sub settings {
    my ($self, %options) = @_;

    return if (defined($self->{settings_done}));
    $self->{http}->set_options(%{$self->{option_results}});
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    $self->{settings_done} = 1;
}

sub request_api {
    my ($self, %options) = @_;

    $self->settings();
    my ($content) = $self->{http}->request(
        url_path        => $self->{option_results}->{api_path} . $options{endpoint},
        unknown_status  => $self->{option_results}->{unknown_http_status},
        warning_status  => $self->{option_results}->{warning_http_status},
        critical_status => $self->{option_results}->{critical_http_status}
    );

    if (!defined($content) || $content eq '') {
        $self->{output}->option_exit(short_msg => "API returns empty content [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']");
    }

    return json_decode($content, output => $self->{output}, errstr => 'Cannot decode response (add --debug option to display returned content)');
}

sub get_components {
    my ($self, %options) = @_;

    return $self->request_api(endpoint => 'components.json');
}

1;

__END__

=head1 NAME

Atlassian Statuspage public JSON API

=head1 SYNOPSIS

Atlassian Statuspage public JSON API custom mode

=head1 API OPTIONS

Atlassian Statuspage public JSON API

=over 8

=item B<--hostname>

Set hostname.

=item B<--port>

Port used (default: 443)

=item B<--proto>

Specify https if needed (default: 'https')

=item B<--api-path>

API base url path (default: '/api/v2/').

=item B<--timeout>

Set timeout in seconds (default: 30).

=item B<--unknown-http-status>

Threshold for unknown HTTP status (default: '%{http_code} < 200 or %{http_code} >= 300').

=item B<--warning-http-status>

Threshold for warning HTTP status.

=item B<--critical-http-status>

Threshold for critical HTTP status.

=back

=head1 DESCRIPTION

B<custom>.

=cut
