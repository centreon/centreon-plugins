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

package notification::prowl::mode::alert;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::http;
use XML::Simple;

my %priority = (
    up          => '0',
    down        => '2',
    unreachable => '-1',
    ok          => '0',
    warning     => '1',
    critical    => '2',
    unknown     => '-2',
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'hostname:s'    => { name => 'hostname', default => 'api.prowlapp.com' },
        'port:s'        => { name => 'port', default => 443 },
        'proto:s'       => { name => 'proto', default => 'https' },
        'urlpath:s'     => { name => 'url_path', default => "/publicapi/add" },
        'apikey:s'      => { name => 'apikey' },
        'providerkey:s' => { name => 'providerkey' },
        'priority:s'    => { name => 'priority' },
        'application:s' => { name => 'application' },
        'event:s'       => { name => 'event' },
        'message:s'     => { name => 'message' },
        'timeout:s'     => { name => 'timeout' },
    });

    $self->{http} = centreon::plugins::http->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;

    $self->SUPER::init(%options);
    if (!defined($self->{option_results}->{apikey})) {
        $self->{output}->add_option_msg(short_msg => "You need to set --apikey option");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{priority})) {
        $self->{output}->add_option_msg(short_msg => "You need to set --priority option");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{application})) {
        $self->{output}->add_option_msg(short_msg => "You need to set --application option");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{event})) {
        $self->{output}->add_option_msg(short_msg => "You need to set --event option");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{message})) {
        $self->{output}->add_option_msg(short_msg => "You need to set --message option");
        $self->{output}->option_exit();
    }

    $self->{http}->set_options(%{$self->{option_results}});
}

sub run {
    my ($self, %options) = @_;

    my $notification_param = [
        "apikey=$self->{option_results}->{apikey}",
        "providerkey=" . (defined($self->{option_results}->{providerkey}) ? $self->{option_results}->{providerkey} : ''),
        "priority=$priority{lc($self->{option_results}->{priority})}",
        "application=$self->{option_results}->{application}",
        "event=$self->{option_results}->{event}",
        "description=$self->{option_results}->{message}",
    ];
    my $response = $self->{http}->request(method => 'POST', post_param => $notification_param);

    my $decoded;
    eval {
        $decoded = XMLin($response);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode xml response: $@");
        $self->{output}->option_exit();
    }

    $self->{output}->output_add(short_msg => $decoded->{success}->{remaining} . ' notifications remaining until ' . gmtime($decoded->{success}->{resetdate}));
    $self->{output}->display(force_ignore_perfdata => 1);
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Send iOS push notifications via Prowl API (https://www.prowlapp.com/api.php).

=over 6

=item B<--hostname>

Hostname of the Prowl API (Default: 'api.prowlapp.com')

=item B<--port>

Port used by API (Default: '443')

=item B<--proto>

Specify https if needed (Default: 'https').

=item B<--urlpath>

Set path to the notifications API (Default: '/publicapi/add').

=item B<--apikey>

Specify API key(s), separated by commas.

=item B<--providerkey>

Specify API providerkey.

=item B<--priority>

The priority of the notification to send.

=item B<--application>

The application part of the notification to send.

=item B<--event>

The event part of the notification to send.

=item B<--message>

The message part of the notification to send.

=item B<--url>

The URL which should be attached to the notification.

=item B<--timeout>

Threshold for HTTP timeout

=back

=cut
