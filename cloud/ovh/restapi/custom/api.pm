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

package cloud::ovh::restapi::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use JSON::XS;
use Digest::SHA 'sha1_hex';

my %map_ovh_type = (
    OVH_API_EU => 'https://eu.api.ovh.com/1.0',
    OVH_API_CA => 'https://ca.api.ovh.com/1.0'
);

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    if (!defined($options{output})) {
        print "Class Custom: Need to specify 'output' argument.\n";
        exit 3;
    }
    if (!defined($options{options})) {
        $options{output}->add_option_msg(short_msg => "Class Custom: Need to specify 'options' argument.");
        $options{output}->option_exit();
    }

    if (!defined($options{noptions})) {
        $options{options}->add_options(arguments => {
            'ovh-type:s@'               => { name => 'ovh_type' },
            'ovh-application-key:s@'    => { name => 'ovh_application_key' },
            'ovh-application-secret:s@' => { name => 'ovh_application_secret' },
            'ovh-consumer-key:s@'       => { name => 'ovh_consumer_key' },
            'timeout:s@'                => { name => 'timeout' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options);

    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    $self->{ovh_type} = (defined($self->{option_results}->{ovh_type})) ? shift(@{$self->{option_results}->{ovh_type}}) : 'OVH_API_EU';
    $self->{ovh_application_key} = (defined($self->{option_results}->{ovh_application_key})) ? shift(@{$self->{option_results}->{ovh_application_key}}) : undef;
    $self->{ovh_application_secret} = (defined($self->{option_results}->{ovh_application_secret})) ? shift(@{$self->{option_results}->{ovh_application_secret}}) : undef;
    $self->{ovh_consumer_key} = (defined($self->{option_results}->{ovh_consumer_key})) ? shift(@{$self->{option_results}->{ovh_consumer_key}}) : undef;
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? shift(@{$self->{option_results}->{timeout}}) : 10;
 
    if (!defined($self->{ovh_application_key})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify --ovh-application-key option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{ovh_application_secret})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify --ovh-application-secret option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{ovh_consumer_key})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify --ovh-consumer-key option.");
        $self->{output}->option_exit();
    }

    if (!defined($self->{ovh_application_key}) ||
        scalar(@{$self->{option_results}->{ovh_application_key}}) == 0) {
        return 0;
    }

    return 1;
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{timeout} = $self->{timeout};
}

sub settings {
    my ($self, %options) = @_;    

    $self->build_options_for_httplib();
    $self->{http}->add_header(key => 'X-Ovh-Application', value => $self->{ovh_application_key});
    if (!defined($options{no_signature}) || $options{no_signature} == 0) {
        my $now = $self->time_delta() + time;
        my $method = defined($options{method}) ? uc($options{method}) : 'GET';
        my $body = '';
       
        if ($method !~ /GET|DELETE/) {
            my $content;
            eval {
                $content = JSON::XS->new->utf8->encode($options{body});
            };
            if ($@) {
                $self->{output}->add_option_msg(short_msg => "Cannot encode json: $@");
                $self->{output}->option_exit();
            }
            $self->{http}->add_header(key => 'Content-type', value => 'application/json');
            $self->{option_results}->{query_form_post} = $content;
        }

        $self->{http}->add_header(key => 'X-Ovh-Consumer', value => $self->{ovh_consumer_key});
        $self->{http}->add_header(key => 'X-Ovh-Timestamp', value => $now);
        $self->{http}->add_header(key => 'X-Ovh-Signature', value => '$1$' . sha1_hex(join('+', (
             # Full signature is '$1$' followed by the hex digest of the SHA1 of all these data joined by a + sign
             $self->{ovh_application_secret},   # Application secret
             $self->{ovh_consumer_key},         # Consumer key
             $method,                           # HTTP method (uppercased)
             $map_ovh_type{uc($self->{ovh_type})} . $options{path},  # Full URL
             $body,                                                 # Full body
             $now,                                                  # Curent OVH server time
        ))));
    }
    $self->{http}->set_options(%{$self->{option_results}});
}

sub time_delta {
    my ($self, %options) = @_;

    if (!defined($self->{time_delta})) {
        my $response = $self->get(path => '/auth/time', no_signature => 1, no_decode => 1);
        $self->{time_delta} = $response - time();
    }

    return $self->{time_delta};
}

sub get {
    my ($self, %options) = @_;

    $self->settings(%options);

    my $response = $self->{http}->request(
        full_url => $map_ovh_type{uc($self->{ovh_type})} . $options{path},
        hostname => '',
        critical_status => '',
        warning_status => ''
    );
    my ($client_warning) = $self->{http}->get_header(name => 'Client-Warning');
    if (defined($client_warning) && $client_warning eq 'Internal response') {
        $self->{output}->add_option_msg(short_msg => "Internal LWP::UserAgent error: $response");
        $self->{output}->option_exit();
    }

    if (defined($options{no_decode}) && $options{no_decode} == 1) {
        return $response;
    }

    my $content;
    eval {
        $content = JSON::XS->new->utf8->decode($response);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
        $self->{output}->option_exit();
    }

    return $content;
}

1;

__END__

=head1 NAME

OVH REST API

=head1 SYNOPSIS

OVH Rest API custom mode

=head1 REST API OPTIONS

=over 8

=item B<--ovh-type>

Can be: OVH_API_EU or OVH_API_CA (default: OVH_API_EU).

=item B<--ovh-application-key>

OVH API applicationKey

=item B<--ovh-application-secret>

OVH API applicationSecret

=item B<--ovh-consumer-key>

OVH API consumerKey

=item B<--timeout>

Set HTTP timeout

=back

=head1 DESCRIPTION

B<custom>.

=cut
