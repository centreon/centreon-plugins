#
# Copyright 2017 Centreon (http://www.centreon.com/)
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

package notification::foxbox::mode::alert;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::http;
use JSON;

# use Data::Dumper;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                       {
                                           "username:s"      => { name => 'username', default => 'centreon' },
                                           "password:s"      => { name => 'password' },
                                           "from:s"          => { name => 'from', default => 'Centreon' },
                                           "proto:s"         => { name => 'proto', default => 'http' },
                                           "phonenumber:s"   => { name => 'phonenumber' },
                                           "hostname:s"      => { name => 'hostname' },
                                           "testo:s"         => { name => 'testo' },
                                           "timeout:s"       => { name => 'timeout', default => 10 },
                                       });
    
    $self->{http} = centreon::plugins::http->new(output => $self->{output});

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

    if (!defined($self->{option_results}->{testo})) {
        $self->{output}->add_option_msg(short_msg => "Please set the --testo option");
        $self->{output}->option_exit();
    }

    $self->{http}->set_options(%{$self->{option_results}});
}

sub run {
    my ($self, %options) = @_;

    $self->{http}->add_header(key => 'Content-Type', value => 'text/xml');
    $self->{http}->add_header(key => 'Accept', value => 'text/xml');

    my $api_path = '/source/send_sms.php';
    my $url = $self->{option_results}->{proto} . '://' . $self->{option_results}->{hostname} . $api_path;

    my $arg = [
        "username" => $self->{option_results}->{username},
        "pwd" => $self->{option_results}->{password},
        "from" => $self->{option_results}->{from},
        "nphone" => $self->{option_results}->{phonenum},
        "testo" => $self->{option_results}->{testo},
        "nc" => $url,
    ];

    my $response = $self->{http}->request(full_url => $url, method => 'POST', query_form_post => $arg);
    
    $self->{output}->display(force_ignore_perfdata => 1);
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Send SMS with Foxbox API.

=over 6

=item B<--hostname>

url of the Foxbox Server.

=item B<--username>

Specify username for API authentification.

=item B<--password>

Specify password for API authentification.

=item B<--phonenumber>

Specify phone number.

=item B<--testo>

Specify the testo to send.

=item B<--from>

Specify the sender. It should NOT start with a number and have a max of 11 charracter.

=item B<--timeout>

Timeout in seconds for the command (Default: 10).

=back

=cut
