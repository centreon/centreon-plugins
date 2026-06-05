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
use centreon::plugins::lockfile;
use Digest::SHA qw(sha256_hex);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "refresh-frequency:s" => { name => 'refresh_frequency' }, # legacy
        "refresh-before:s"    => { name => 'refresh_before', default => 15 * 60 },
        "force-refresh"       => { name => 'force_refresh' },
        "api-token:s"         => { name => 'api_token', default => '' },
        "refresh-token:s"     => { name => 'refresh_token', default => '' },
        "status-if-unused:s"  => { name => 'status_if_unused', default => 'OK' },
    });

    $self->{lock} = centreon::plugins::lockfile->new(%options);

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    $self->{output}->option_exit(short_msg => "Invalid status-if-unused value '" . $self->{option_results}->{status_if_unused} . "'. Valid values are: OK, WARNING, CRITICAL, UNKNOWN")
        unless $self->{option_results}->{status_if_unused}=~/^(?:OK|WARNING|CRITICAL|UNKNOWN)$/i;

    $self->{output}->option_exit(exit_litteral => $self->{option_results}->{status_if_unused},
                                 short_msg => 'Using username-based authentication')
        if $self->{option_results}->{api_username} ne '' || $self->{option_results}->{api_password} ne '';

    $self->{output}->option_exit(short_msg => '--api-token and --refresh-token are mandatory')
        if $self->{option_results}->{api_token} eq '' || $self->{option_results}->{refresh_token} eq '';


    $self->{output}->option_exit(short_msg => '--refresh-before must be a number')
        unless $self->{option_results}->{refresh_before} =~ /^\d+$/;

    $self->{lock}->check_options(option_results => { %{$self->{option_results}},
                                                     lockfile => 'commvault_commserve_' . sha256_hex($self->{option_results}->{hostname} . '_' . $self->{option_results}->{instance}) . '.lock',
                                                     lock_expiration_timeout => 3600 });
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

    $self->{output}->option_exit(exit_literal => 'unknown', short_msg => 'Unable to acquire lock: will retry on next run')
        unless $self->{lock}->lock_file();

    my ($expiry_time, $authent_token, $refresh_token) = $options{custom}->load_authent_token();

    my $msg = 'Token available';
    my $severity = 'OK';
    if ($self->{option_results}->{api_token} ne '') {
        if ($expiry_time < $self->{option_results}->{refresh_before} || $self->{option_results}->{force_refresh}) {
            if ($authent_token eq '') {
                $authent_token = $self->{option_results}->{api_token};
                $refresh_token = $self->{option_results}->{refresh_token};
            }

            ($authent_token, $refresh_token, $expiry_time) = $options{custom}->refresh_authent_token(
                authentToken => $authent_token,
                refreshToken  => $refresh_token,
                expityTyme => $expiry_time,
                exit_on_failed => 1
            );

            if ($authent_token eq '') {
                $severity = 'CRITICAL';
                $msg = 'Token not refreshed: '.value_of(\%options, "->{custom}->{http}->get_code()", 'Cannot extract tokens !');
            } else {
                $options{custom}->write_authent_token(authentToken => $authent_token, refreshToken => $refresh_token, expiryTime => $expiry_time);
                $msg = 'Token refreshed';
            }
        } else {
            $msg = 'Token available';
        }
    } else {
        $msg = 'Using session authentication';
    }

    $self->{lock}->unlock();

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

=item B<--refresh-before>

Refresh the token when its expiration time is less than C<refresh-before> seconds away.
Default: --refresh-before=900 (15 minutes)

=item B<--force-refresh>

Force token renewal.

=item B<--status-if-unused>

Set return status if token authentication is not used (default: 'OK').

=back

=cut
