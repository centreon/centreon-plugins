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

package cloud::ibm::softlayer::custom::xmlapi;

use strict;
use warnings;
use centreon::plugins::http;
use XML::Simple;

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
            'hostname:s'     => { name => 'hostname' },
            'url-path:s'     => { name => 'url_path' },
            'port:s'         => { name => 'port' },
            'proto:s'        => { name => 'proto' },
            'timeout:s'      => { name => 'timeout' },
            'api-username:s' => { name => 'api_username' },
            'api-key:s'      => { name => 'api_key' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'XMLAPI OPTIONS', once => 1);

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
    
    $self->{hostname} = (defined($self->{option_results}->{hostname})) ? $self->{option_results}->{hostname} : 'api.softlayer.com';
    $self->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 443;
    $self->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'https';
    $self->{url_path} = (defined($self->{option_results}->{url_path})) ? $self->{option_results}->{url_path} : '/soap/v3';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 10;
 
    if (!defined($self->{option_results}->{api_username}) || $self->{option_results}->{api_username} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --api-username option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{api_key}) || $self->{option_results}->{api_key} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --api-key option.");
        $self->{output}->option_exit();
    }

    return 0;
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{hostname} = $self->{hostname};
    $self->{option_results}->{timeout} = $self->{timeout};
    $self->{option_results}->{port} = $self->{port};
    $self->{option_results}->{proto} = $self->{proto};
    $self->{option_results}->{warning_status} = '';
    $self->{option_results}->{critical_status} = '';
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();

    $self->{http}->add_header(key => 'Accept', value => 'text/xml');
    $self->{http}->add_header(key => 'Accept', value => 'multipart/*');
    $self->{http}->add_header(key => 'Accept', value => 'text/xmlapplication/soap');
    $self->{http}->add_header(key => 'Content-Type', value => 'text/xml; charset=utf-8');
    $self->{http}->set_options(%{$self->{option_results}});
}

sub get_connection_info {
    my ($self, %options) = @_;
    
    return $self->{hostname} . ":" . $self->{port};
}

sub get_hostname {
    my ($self, %options) = @_;
    
    return $self->{hostname};
}

sub get_port {
    my ($self, %options) = @_;
    
    return $self->{port};
}

sub get_api_username {
    my ($self, %options) = @_;

    return $self->{option_results}->{api_username};
}

sub get_api_key {
    my ($self, %options) = @_;

    return $self->{option_results}->{api_key};
}

sub get_endpoint {
    my ($self, %options) = @_;

    $self->settings;
    
    $self->{http}->add_header(key => 'SOAPAction', value => 'http://api.service.softlayer.com/soap/v3/#' . $options{method});

    my $content = '<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:slapi="http://api.service.softlayer.com/soap/v3/" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"
  xmlns:soapenc="http://schemas.xmlsoap.org/soap/encoding/" xmlns:xsd="http://www.w3.org/2001/XMLSchema"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" soap:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
  <soap:Header>
    <slapi:authenticate>
      <apiKey>' . $self->get_api_key() . '</apiKey>
      <username>' . $self->get_api_username() . '</username>
    </slapi:authenticate>' .
    $options{extra_content}
  . '</soap:Header>
  <soap:Body>
    <slapi:' . $options{method} . ' xsi:nil="true"/>
  </soap:Body>
</soap:Envelope>';

    my $response = $self->{http}->request(url_path => $self->{url_path} . '/' . $options{service}, method => 'POST', query_form_post => $content);
    
    my $xml_hash = XMLin($response, ForceArray => ['item']);

    if (defined($xml_hash->{'SOAP-ENV:Body'}->{'SOAP-ENV:Fault'})) {
        $self->{output}->output_add(long_msg => "Returned message: " . $response, debug => 1);
        $self->{output}->add_option_msg(short_msg => "API returned error code '" . $xml_hash->{'SOAP-ENV:Body'}->{'SOAP-ENV:Fault'}->{faultcode} . 
            "' with message '" . $xml_hash->{'SOAP-ENV:Body'}->{'SOAP-ENV:Fault'}->{faultstring} . "'");
        $self->{output}->option_exit();
    }
    
    return $xml_hash->{'SOAP-ENV:Body'};
}

1;

__END__

=head1 NAME

IBM SoftLayer XML API

=head1 SYNOPSIS

IBM SoftLayer XML API

=head1 XMLAPI OPTIONS

=over 8

=item B<--hostname>

API hostname (Default: 'api.softlayer.com').

=item B<--url-path>

API url path (Default: '/soap/v3')

=item B<--port>

API port (Default: 443)

=item B<--proto>

Specify https if needed (Default: 'https')

=item B<--api-username>

Set API username

=item B<--api-key>

Set API Key

=item B<--timeout>

Set HTTP timeout

=back

=head1 DESCRIPTION

B<custom>.

=cut
