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

package notification::orangesms::mode::alerts;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use centreon::plugins::misc qw/json_encode json_decode/;
use URI::Escape;
use Digest::SHA qw/sha256_hex/;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    unless ($options{output}) {
        print "Class Custom: Need to specify 'output' argument.\n";
        exit 3;
    }
    $options{output}->option_exit(short_msg => "Need to specify 'options' argument.")
        unless $options{options};

    $options{options}->add_options(arguments => {
        'hostname:s'    => { name => 'hostname',    not_empty => 1 },
        'port:s'        => { name => 'port',        default => 443, type => 'port' },
        'proto:s'       => { name => 'proto',       default => 'https', type => 'http_protocol' },
        'username:s'    => { name => 'username',    not_empty => 1 },
        'password:s'    => { name => 'password',    not_empty => 1 },
        'group-id:s'    => { name => 'group_id',    not_empty => 1 },
        'to:s@'         => { name => 'to',          not_empty => 1 },
        'from:s'        => { name => 'from',        default => '' },
        'diffusion-name:s' => { name => 'diffusion_name', default => '' },
        'message:s'     => { name => 'message',     not_empty => 1 },
        'endpoint:s'    => { name => 'endpoint',    default => '/api/v1.2/', not_empty => 1 },
        'disable-cache' => { name => 'disable_cache' }
    });

    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options, default_backend => 'curl');
    $self->{cache} = centreon::plugins::statefile->new(%options);

    return $self;
}

sub check_options {
    my ($self, %options) = @_;

    $self->SUPER::init(%options);

    $self->{output}->option_exit(short_msg => 'Please specify at least one recipient using the --to parameter.')
        unless $self->{option_results}->{to} && @{$self->{option_results}->{to}};

    foreach (@{$self->{option_results}->{to}}) {
        $self->{output}->option_exit(short_msg => "Invalid phone number '$_' in the --to parameter.")
            unless /^\+?\d+$/;
    }

    $self->{option_results}->{endpoint} .= '/' unless $self->{option_results}->{endpoint} =~ /\/$/;

    $self->{cache}->check_options(option_results => $self->{option_results});
    $self->{http}->set_options(%{$self->{option_results}});
}

sub get_access_token {
    my ($self, %options) = @_;

    $self->{cache}->read(statefile => 'centreon_opentickets_' . sha256_hex($self->{option_results}->{hostname} . '_' . $self->{option_results}->{username}));
    my $token = $self->{cache}->get(name => 'token');
    my $expire = $self->{cache}->get(name => 'expire_at', default => 0);
    return $token if $token && !$self->{option_results}->{disable_cache} && time() < $expire - 30;

    my $response = $self->{http}->request(  method => 'POST',
                                            url_path => $self->{option_results}->{endpoint}.'oauth/token',
                                            post_params => [ 'username' => $self->{option_results}->{username},
                                                             'password' => $self->{option_results}->{password} ],
                                            header => [ 'Accept: application/json', ],
                                            warning_status => '', unknown_status => '', critical_status => ''
                                         );

    $self->{output}->option_exit(short_msg => "API returns invalid content [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']")
        unless $response;

    my $json = json_decode($response, output => $self->{output}, no_exit => 1);

    $self->{output}->option_exit(short_msg => "API returns error [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']")
        unless ref $json eq 'HASH' && $json->{access_token};

    my $data = { token => $json->{access_token},
                 epire_at => time() + $json->{ttl}
               };
    $self->{cache}->write(data => $data);

    return $json->{access_token};
}


sub create_sms_diffusion {
    my ($self, %options) = @_;

    my $data = { msisdns => $self->{option_results}->{to},
                 smsParam => { "encoding" => "GSM7",
                               "body" => $self->{option_results}->{message} }
               };
    $data->{name} = $self->{option_results}->{diffusion_name} if $self->{option_results}->{diffusion_name} ne '';
    $data->{smsParam}->{senderName} = $self->{option_results}->{from} if $self->{option_results}->{from} ne '';

    $self->{http}->add_header(key => 'Content-Type', value => 'application/json' );
    my $response = $self->{http}->request(  method => 'POST',
                                            url_path => $self->{option_results}->{endpoint}.uri_escape($self->{option_results}->{group_id}).'/diffusion-requests',
                                            header => [ 'Accept: application/json',
                                                        'Content-Type: application/json',
                                                        'Authorization: Bearer ' . $options{token}
                                                      ],
                                            query_form_post => json_encode($data),
                                            warning_status => '', unknown_status => '', critical_status => ''
                                         );

    $self->{output}->option_exit(short_msg => "API returns invalid content [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']")
        unless $response;

    my $json = json_decode($response, output => $self->{output}, no_exit => 1);

    return $json->{id} if ref $json eq 'HASH' && $json->{id};
   
    $self->{output}->option_exit(short_msg => "API returns error [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']")
}

sub run {
    my ($self, %options) = @_;

    my $token = $self->get_access_token();
    my $id = $self->create_sms_diffusion( token => $token );

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => "message sent #$id"
    );

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Send SMS with Orange Contact Everyone API.

=over 8

=item B<--hostname>

URL of the Orange Contact Everyone platform.

=item B<--port>

Port used by Orange Contact Everyone API (default: 443).

=item B<--proto>

Specify http or https protocol (default: https).

=item B<--username>

Specify username for API authentication.

=item B<--password>

Specify password for API authentication.

=item B<--group-id>

Specify the group ID for SMS diffusion.

=item B<--to>

Specify recipient phone number(s) (can be used multiple times for multiple recipients).

=item B<--from>

Specify sender name (optional).

=item B<--diffusion-name>

Specify the diffusion name (optional).

=item B<--message>

Specify the message to send.

=item B<--endpoint>

Specify the API endpoint (default: /api/v1.2/).

=item B<--disable-cache>

Disable token caching.

=back

=cut
