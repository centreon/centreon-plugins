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

package notification::ovhsms::mode::alert;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::http;
use JSON::XS;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "hostname:s"        => { name => 'hostname', default => 'www.ovh.com' },
        "port:s"            => { name => 'port', default => 443 },
        "proto:s"           => { name => 'proto', default => 'https' },
        "urlpath:s"         => { name => 'url_path', default => "/cgi-bin/sms/http2sms.cgi" },
        "account:s"         => { name => 'account' },
        "login:s"           => { name => 'login' },
        "password:s"        => { name => 'password' },
        "from:s"            => { name => 'from'},
        "to:s"              => { name => 'to' },
        "message:s"         => { name => 'message' },
        "class:s"           => { name => 'class', default => 1 },
        "nostop:s"          => { name => 'nostop', default => 1 },
        "smscoding:s"       => { name => 'smscoding', default => 1 },
        "timeout:s"         => { name => 'timeout' },
    });

    $self->{http} = centreon::plugins::http->new(%options);

    return $self;
}


sub check_options {
    my ($self, %options) = @_;

    $self->SUPER::init(%options);
    if (!defined($self->{option_results}->{account})) {
        $self->{output}->add_option_msg(short_msg => "You need to set --account option");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{login})) {
        $self->{output}->add_option_msg(short_msg => "You need to set --login option");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{password})) {
        $self->{output}->add_option_msg(short_msg => "You need to set --password option");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{from})) {
        $self->{output}->add_option_msg(short_msg => "You need to set --from option");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{to})) {
        $self->{output}->add_option_msg(short_msg => "You need to set --to option");
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

    $self->{http}->add_header(key => 'Content-Type', value => 'text/plain');
    $self->{http}->add_header(key => 'Accept', value => 'text/plain');

    my $sms_param = [
        "account=$self->{option_results}->{account}",
        "login=$self->{option_results}->{login}",
        "password=$self->{option_results}->{password}",
        "to=$self->{option_results}->{to}",
        "from=$self->{option_results}->{from}",
        "message=$self->{option_results}->{message}",
        "class=" . (defined($self->{option_results}->{class}) ? $self->{option_results}->{class} : ''),
        "noStop=" . (defined($self->{option_results}->{nostop}) ? $self->{option_results}->{nostop} : ''),
        "contentType=application/json",
        "smsCoding=" . (defined($self->{option_results}->{smsCoding}) ? $self->{option_results}->{smsCoding} : ''),
    ];
    my $response = $self->{http}->request(method => 'GET', get_param => $sms_param);

    my $decoded;
    eval {
        $decoded = JSON::XS->new->utf8->decode($response);
    };
    if ($@) {
        $self->{output}->output_add(long_msg => $response, debug => 1);
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
        $self->{output}->option_exit();
    }
    if (defined($decoded->{status}) && ($decoded->{status} < 100 || $decoded->{status} >= 200)) {
        $self->{output}->add_option_msg(short_msg => "API returned status '" . $decoded->{status} . "' and message '" . $decoded->{message} . "'");
        $self->{output}->option_exit();
    }

    $self->{output}->output_add(short_msg => 'smsIds : ' . join(', ', @{$decoded->{smsIds}}));
    $self->{output}->display(force_ignore_perfdata => 1);
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Send SMS with OVH API (https://docs.ovh.com/fr/sms/envoyer_des_sms_depuis_une_url_-_http2sms/)

=over 6

=item B<--hostname>

Hostname of the OVH SMS API (Default: 'www.ovh.com')

=item B<--port>

Port used by API (Default: '443')

=item B<--proto>

Specify https if needed (Default: 'https').

=item B<--urlpath>

Set path to the SMS API (Default: '/cgi-bin/sms/http2sms.cgi').

=item B<--account>

Specify SMS Account for API authentification.

=item B<--login>

Specify login for API authentification.

=item B<--password>

Specify password for API authentification.

=item B<--from>

Specify sender linked to account.

=item B<--to>

Specify receiver phone number (format 00336xxxx for French Number).

=item B<--message>

Specify the message to send.

=item B<--class>

Specify the class of message. (Default : '1').

=item B<--nostop>

Specify the nostop option. (Default : '1').

=item B<--smsdoding>

Specify the coding of message. (Default : '1').

=item B<--timeout>

Threshold for HTTP timeout

=back

=cut
