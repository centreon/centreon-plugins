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

package apps::saas::adobestatus::restapi::custom::public;

use strict;
use warnings;
use centreon::plugins::http;
use JSON::XS;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::misc qw/is_empty json_decode/;
use centreon::plugins::constants qw(:messages);

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
            'hostname:s'        => { name => 'hostname', default => 'data.status.adobe.com' },
            'port:s'            => { name => 'port', default => 443 },
            'proto:s'           => { name => 'proto', default => 'https' },
            'timeout:s'         => { name => 'timeout', default => 30 },
            'unknown-http-status:s'  => { name => 'unknown_http_status', default => '%{http_code} < 200 or %{http_code} >= 300' },
            'warning-http-status:s'  => { name => 'warning_http_status' },
            'critical-http-status:s' => { name => 'critical_http_status' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'PUBLIC API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options, default_backend => 'curl');

    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    if (is_empty($self->{option_results}->{hostname})) {
        $self->{output}->option_exit(short_msg => "Need to specify hostname option.");
    }

    return 0;
}

sub settings {
    my ($self, %options) = @_;

    return if (defined($self->{settings_done}));
    $self->{http}->set_options(%{$self->{option_results}});
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    $self->{settings_done} = 1;
}

sub request_api {
    my ($self, %options) = @_;

    $self->settings();
    my ($content) = $self->{http}->request(
        url_path => $options{endpoint},
        unknown_status => $self->{unknown_http_status},
        warning_status => $self->{warning_http_status},
        critical_status => $self->{critical_http_status}
    );

    if (!defined($content) || $content eq '') {
        $self->{output}->add_option_msg(short_msg => "API returns empty content [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']");
        $self->{output}->option_exit();
    }

    my $decoded = json_decode(
        $content,
        errstr => MSG_JSON_DECODE_ERROR,
        output => $self->{output}
    );

    return $decoded;
}

sub get_incidents {
    my ($self, %options) = @_;

    my $response = $self->request_api(endpoint => '/adobestatus/StatusEvents');
 
    my $current_incidents = {};
    foreach my $incident (values %{ $response->{incidentEvent}->{incidents}}) {
        foreach my $productinc (values %{$incident->{products}}) {
            next if (!defined($productinc->{endedOn}) || $productinc->{endedOn} == 0);

            $current_incidents->{ $productinc->{id} } = [] if (!defined($current_incidents->{ $productinc->{id} }));

            foreach ( sort { $b <=> $a } keys(%{$productinc->{history}}) ) {
                push @{$current_incidents->{ $productinc->{id} }}, {
                    status => $_->{status},
                    statusTime => $_->{statusTime},
                    severity => $_->{severity},
                    customerImpact => $_->{customerImpact},
                    messageEn => $response->{incidentEvent}->{messages}->{en}->{ $_->{messageToken} },
                };
                last;
            }
        }
    }

    return $current_incidents;
}

sub get_products {
    my ($self, %options) = @_;

    my $response = $self->request_api(endpoint => '/adobestatus/SnowServiceRegistry');
    
    my $products = {};
    foreach (values %{$response->{products}}) {
        $products->{ $_->{id} } = $_->{name};
    }

    return $products;
}

1;

__END__

=head1 NAME

Public JSON API

=head1 PUBLIC API OPTIONS

Public JSON API

=over 8

=item B<--hostname>

Define hostname (default: C<'data.status.adobe.com'>).

=item B<--port>

Port used (default: 443)

=item B<--proto>

Specify https if needed (default: 'https')

=item B<--timeout>

Set timeout in seconds (default: 30).

=back

=head1 DESCRIPTION

B<custom>.

=cut
