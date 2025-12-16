#
# Copyright 2025 Centreon (http://www.centreon.com/)
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

package notification::orange::mode::alert;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::http;
use JSON;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'username=s'   => \$username,
        'password=s'   => \$password,
        'group_id=s'   => \$group_id,
        'msisdns=s@{1,}' => \@msisdns,
        'message=s'    => \$message,
        'proxy=s'      => \$proxy_url,
        'proxy-auth=s' => \$proxy_auth,
    });

    $self->{http} = centreon::plugins::http->new(%options);

    return $self;
}


sub check_options {
    my ($self, %options) = @_;

    $self->SUPER::init(%options);
    if ((!defined($self->{option_results}->{username}) && !defined($self->{option_results}->{password}))) {
        $self->{output}->add_option_msg(short_msg => "You need to set --username= and --password= option");
        $self->{output}->option_exit();
    }

    if (!defined($self->{option_results}->{hostname})) {
        $self->{output}->add_option_msg(short_msg => "Please set the --hostname option");
        $self->{output}->option_exit();
    }

    if (!defined($self->{option_results}->{phonenumber})) {
        $self->{output}->add_option_msg(short_msg => "Please set the --group_id option");
        $self->{output}->option_exit();
    }

    if (!defined($self->{option_results}->{message})) {
        $self->{output}->add_option_msg(short_msg => "Please set the --message option");
        $self->{output}->option_exit();
    }

    $self->{http}->set_options(%{$self->{option_results}});
}

sub get_access_token {
    my ($username, $password) = @_;

    my $proxy_option = $proxy_url ? "--proxy $proxy_url" : "";
    my $proxy_auth_option = $proxy_auth ? $proxy_auth : "";

    my $curl_command = qq{
        curl -s -X POST "$SERVER_URL/api/v1.2/oauth/token" \\
             $proxy_option \\
             $proxy_auth_option \\
             -H "Content-Type: application/x-www-form-urlencoded" \\
             -d "username=$username" \\
             -d "password=$password"
    };

    my $response = execute_curl($curl_command);
    my $json = decode_json($response);
    return $json->{access_token};
}


sub create_sms_diffusion {
    my ($access_token, $group_id, $msisdns, $message) = @_;

    my $msisdns_json = encode_json($msisdns);

    my $proxy_option = $proxy_url ? "--proxy $proxy_url" : "";
    my $proxy_auth_option = $proxy_auth ? $proxy_auth : "";

    my $curl_command = qq{
        curl -s -X POST "$SERVER_URL/api/v1.2/groups/$group_id/diffusion-requests" \\
             $proxy_option \\
             $proxy_auth_option \\
             -H "Authorization: Bearer $access_token" \\
             -H "Content-Type: application/json" \\
             -d '{"msisdns": $msisdns_json, "smsParam": {"encoding": "GSM7", "body": "$message"}}'
    };

    my $response = execute_curl($curl_command);
    return decode_json($response);
}

eval {
    my $access_token = get_access_token($username, $password);
    my $diffusion = create_sms_diffusion($access_token, $group_id, \@msisdns, $message);
};

1;

__END__

=head1 MODE

Send SMS with Orange Contact Everyone API.

=over 6

=item B<--hostname>

url of the Orange Contact Everyone plateforem.

=item B<--port>

Port used by Orange Contact Everyone API. (default: 443)

=item B<--proto>

Specify http or https protocol. (default: https)

=item B<--username>

Specify username for API authentification.

=item B<--password>

Specify password for API authentification.

=item B<--timeout>

Threshold for HTTP timeout

=item B<--phonenumber>

Specify phone number.

=item B<--message>

Specify the message to send.

=back

=cut
