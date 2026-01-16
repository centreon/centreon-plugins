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

package apps::backup::commvault::commserve::restapi::mode::token;

use base qw(centreon::plugins::mode);

use centreon::plugins::misc qw/format_opt value_of/;

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

        $options{options}->add_options(arguments => {
            "refresh-frequency:s" => { name => 'refresh_frequency', default => 25 * 60 },
            "force-refresh"       => { name => 'force_refresh' },
            "api-token:s"         => { name => 'api_token', default => '' },
            "refresh-token:s"     => { name => 'refresh_token', default => '' }
        });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    $self->{output}->option_exit(short_msg => 'Cannot use --api-username/--api-password options with "token" mode')
        if $self->{option_results}->{api_username} ne '' || $self->{option_results}->{api_password} ne '';

    $self->{output}->option_exit(short_msg => '--api-token and --refresh-token are mandatory')
        if $self->{option_results}->{api_token} eq '' || $self->{option_results}->{refresh_token} eq '';
}

# Information about the new access token authentication mode:
# The user creates a pair of tokens "access token" "refresh token" associated with the plugin
# "access token" is used to authenticate to the Commvault API. It is valid for 30 minutes, after this
# period it is automatically renewed by the plugin using "refresh token".
# When the renewal occurs, a completely new pair of "access token" "refresh token" is generated and
# the previous pair is revoked and can no longer be used.
# The plugin uses statfile to store the latest token pair to be used for authentication.
# Each token should be used by only one plugin, it must not have any other use and must not be shared
# with other applications.
# The --instance parameter is used to handle cases where multiple plugins are executed on the same poller
# in order to identify the correct statefile to use.

sub run {
    my ($self, %options) = @_;

    $options{custom}->settings(%{$self->{option_results}});
    my ($update_time, $authent_token, $refresh_token) = $options{custom}->load_authent_token();

    my $msg = 'Token available';
    my $severity = 'OK';
    if ($self->{option_results}->{api_token} ne '') {
        if ($update_time == 0 || $update_time + $self->{option_results}->{refresh_frequency} <= time() || $self->{option_results}->{force_refresh}) {

            if ($authent_token eq '') {
		$authent_token = $self->{option_results}->{api_token};
		$refresh_token = $self->{option_results}->{refresh_token};
	    }
            ($authent_token, $refresh_token) = $options{custom}->refresh_authent_token(
                authentToken => $authent_token,
                refreshToken  => $refresh_token,
                exit_on_failed => 0
            );

            if ($authent_token eq '') {
                $severity = 'CRITICAL';
                $msg = 'Token not refreshed: '.value_of(\%options, "->{custom}->{http}->get_code()", 'Cannot extract tokens !');
            } else {
                $options{custom}->write_authent_token(authentToken => $authent_token, refreshToken => $refresh_token);
                $msg = 'Token refreshed';
            }
        } else {
            $msg = 'Token available';
        }
    } else {
        $msg = 'Using session authentication';
    }

    $self->{output}->output_add(severity => $severity,
                                short_msg => $msg);
    $self->{output}->display(force_ignore_perfdata => 1);
    $self->{output}->exit();
}

1;

=head1 MODE

Authentication token renewal.

=over 8

=item B<--api-token>

Set API access token.
An access token has a validity period of 30 minutes and is automatically refreshed by the plugin using the refresh token.
After it is refreshed, the new login information is stored locally by the connector, so it is important to create a separate authentication token for each connector instance.
Each token should be used by only one connector, it must not have any other use and must not be shared with other applications.

=item B<--refresh-token>

Set API refresh token associated to the access token.
Refresh token is mandatory when --api-token is used.

=item B<--refresh-frequency>

Token validity duration (in seconds).
Tokens will be automatically renewed after this duration when operating in 'token' mode.
Default: --refresh-token=1500 (25 minutes)

=item B<--force-refresh>

Force token renewal.

=back

=cut
