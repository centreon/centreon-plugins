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

package notification::isendpro::mode::sms;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::misc;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'keyid:s'  => { name => 'keyid' },
        'num:s'    => { name => 'num' },
        'texto:s'  => { name => 'texto' },
        'nostop:s' => { name => 'nostop', default => '1' },
        'sandbox'  => { name => 'sandbox' }
    });

    $self->{http} = centreon::plugins::http->new(%options, default_backend => 'curl');
    return $self;
}

sub check_options {
    my ($self, %options) = @_;

    $self->SUPER::init(%options);
    if (!defined($self->{option_results}->{keyid}) || $self->{option_results}->{keyid} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Please set --keyid option');
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{num}) || $self->{option_results}->{num} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Please set --num option');
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{texto}) || $self->{option_results}->{texto} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Please set --texto option');
        $self->{output}->option_exit();
    }

    if (!defined($self->{option_results}->{nostop}) || $self->{option_results}->{nostop} !~ /^0|1$/) {
        $self->{option_results}->{nostop} = 1;
    }

    $self->{http}->set_options(%{ $self->{option_results} }, hostname => 'none');
}

sub run {
    my ($self, %options) = @_;

    my $payload = {
        keyid => $self->{option_results}->{keyid},
        num => $self->{option_results}->{num},
        sms => $self->{option_results}->{texto},
        nostop => $self->{option_results}->{nostop}
    };
    if (defined($self->{option_results}->{sandbox})) {
        $payload->{sandbox} = 1;
    }
    $payload = centreon::plugins::misc::json_encode($payload);
    unless ($payload) {
        $self->{output}->add_option_msg(short_msg => 'cannot encode json request');
        $self->{output}->option_exit();
    }

    my $response = $self->{http}->request(
        method => 'POST',
        full_url => 'https://apirest.isendpro.com/cgi-bin/sms',
        query_form_post => $payload,
        header => [
            'cache-control: no-cache',
            'Content-Type: application/json'
        ],
        unknown_status => '',
        warning_status => '',
        critical_status => ''
    );

    my $json = centreon::plugins::misc::json_decode($response);
    if (!defined($json->{etat})) {
        $self->{output}->output_add(
            severity => 'UNKNOWN',
            short_msg => 'wrong json format'
        );
    } elsif ($json->{etat}->{etat}->[0]->{code} == 0) {
        $self->{output}->output_add(
            severity => 'OK',
            short_msg => $json->{etat}->{etat}->[0]->{message}
        );
    } else {
        $self->{output}->output_add(
            severity => 'UNKNOWN',
            short_msg => $json->{etat}->{etat}->[0]->{message}
        );
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Send SMS with iPushPro API.

=over 8

=item B<--keyid>

Define key id of your account (required).

=item B<--num>

Define the phone number of the recipient (required. phone international format without the +) 

=item B<--texto>

Define the content of your SMS message (required).

=item B<--nostop>

Define if the SMS message shoud contain the stop line to unsubscribe (default: 1).

=item B<--sandbox>

Activate the sandbox mode (testing purpose. you don't pay the message).

=back

=cut
