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

package notification::highsms::mode::alert;

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
        "hostname:s"      => { name => 'hostname' },
        "port:s"          => { name => 'port', default => 443 },
        "proto:s"         => { name => 'proto', default => 'https' },
        "username:s"      => { name => 'username' },
        "password:s"      => { name => 'password' },
        "timeout:s"       => { name => 'timeout' },
        "phonenumber:s"   => { name => 'phonenumber' },
        "message:s"       => { name => 'message' },
        "sender:s"        => { name => 'sender', default => 'API_HIGHSMS' },
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
        $self->{output}->add_option_msg(short_msg => "Please set the --phonenumber option");
        $self->{output}->option_exit();
    }

    if (!defined($self->{option_results}->{message})) {
        $self->{output}->add_option_msg(short_msg => "Please set the --message option");
        $self->{output}->option_exit();
    }

    $self->{http}->set_options(%{$self->{option_results}});
}

sub run {
    my ($self, %options) = @_;

    $self->{http}->add_header(key => 'Content-Type', value => 'text/xml');
    $self->{http}->add_header(key => 'Accept', value => 'text/xml');
    my $xml_arg = << "END_MESSAGE";
                  <?xml version="1.0" encoding="iso-8859-1"?>
                  <push
                  accountid="$self->{option_results}->{username}"
                  password="$self->{option_results}->{password}"
                  sender="$self->{option_results}->{sender}"
                  >
                  <message>
                  <text><![CDATA[$self->{option_results}->{message}]]></text>
                  <to>$self->{option_results}->{phonenumber}</to>
                  </message>
                  </push>
END_MESSAGE

    my $api_path = '/api';
    my $url = $self->{option_results}->{proto} . '://' . $self->{option_results}->{hostname} . $api_path;
    
    my $response = $self->{http}->request(full_url => $url, method => 'POST', query_form_post => $xml_arg);
    
    $self->{output}->output_add(short_msg => 'push_id : ' . $response);
    $self->{output}->display(force_ignore_perfdata => 1);
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Send SMS with HighSMS API.

=over 6

=item B<--hostname>

url of the HighSMS Server.

=item B<--port>

Port used by HighSMS API. (Default: 443)

=item B<--proto>

Specify http or https protocol. (Default: https)

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

=item B<--sender>

Specify the sender. It should NOT start with a number and have a max of 11 charracter.

=back

=cut
