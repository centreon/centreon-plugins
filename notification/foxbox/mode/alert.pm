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

package notification::foxbox::mode::alert;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::http;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "foxbox-username:s" => { name => 'foxbox_username', default => 'centreon' },
        "foxbox-password:s" => { name => 'foxbox_password' },
        "from:s"            => { name => 'from',     default => 'centreon' },
        "proto:s"           => { name => 'proto',    default => 'http' },
        "urlpath:s"         => { name => 'url_path', default => '/source/send_sms.php' },
        "phonenumber:s"     => { name => 'phonenumber' },
        "hostname:s"        => { name => 'hostname' },
        "texto:s"           => { name => 'texto' },
        "timeout:s"         => { name => 'timeout',  default => 10 },
    });

    $self->{http} = centreon::plugins::http->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;

    $self->SUPER::init(%options);
    if (!defined($self->{option_results}->{foxbox_password})) {
        $self->{output}
            ->add_option_msg(short_msg => "You need to set --foxbox-username and --foxbox-password options");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{phonenumber})) {
        $self->{output}->add_option_msg(short_msg => "Please set the --phonenumber option");
        $self->{output}->option_exit();
    }

    if (!defined($self->{option_results}->{texto})) {
        $self->{output}->add_option_msg(short_msg => "Please set the --texto option");
        $self->{output}->option_exit();
    }

    $self->{http}->set_options(%{ $self->{option_results} });
}

sub run {
    my ($self, %options) = @_;

    my $response = $self->{http}->request(method => 'POST', 
        post_param => [
            'username=' . $self->{option_results}->{foxbox_username},
            'pwd=' . $self->{option_results}->{foxbox_password},
            'from=' . $self->{option_results}->{from},
            'nphone=' . $self->{option_results}->{phonenumber},
            'testo=' . $self->{option_results}->{texto},
        ]
    );
    
    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'message sent'
    );
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Send SMS with Foxbox API.

=over 8

=item B<--hostname>

url of the Foxbox Server.

=item B<--urlpath>

The url path. (Default: /source/send_sms.php)

=item B<--foxbox-username>

Specify username for API authentification (Default: centreon).

=item B<--foxbox-password>

Specify password for API authentification (Required).

=item B<--proto>

Specify http or https protocol. (Default: http)

=item B<--phonenumber>

Specify phone number (Required).

=item B<--texto>

Specify the content of your SMS message (Required).

=item B<--from>

Specify the sender. It should NOT start with a number and have a max of 11 characters (Default: centreon).

=item B<--timeout>

Timeout in seconds for the command (Default: 10).

=back

=cut
