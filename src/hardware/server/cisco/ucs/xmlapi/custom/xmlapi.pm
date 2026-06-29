#
# Copyright 2026 Centreon (http://www.centreon.com/)
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

# Copyright 2024 Centreon (http://www.centreon.com/)
# Licensed under the Apache License, Version 2.0

package hardware::server::cisco::ucs::xmlapi::custom::xmlapi;

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use Digest::MD5 qw(md5_hex);
use XML::LibXML;

sub new {
    my ($class, %options) = @_;
    my $self = {};
    bless $self, $class;

    if (!defined($options{output})) {
        print "Class Custom: Need to specify 'output' argument.\n";
        exit 3;
    }
    if (!defined($options{options})) {
        print "Class Custom: Need to specify 'options' argument.\n";
        exit 3;
    }

    $self->{output}  = $options{output};
    $self->{options} = $options{options};
    $self->{http}    = centreon::plugins::http->new(%options);
    $self->{cache}   = centreon::plugins::statefile->new(%options);

    $options{options}->add_options(arguments => {
        'hostname:s'         => { name => 'hostname' },
        'port:s'             => { name => 'port' },
        'proto:s'            => { name => 'proto' },
        'username:s'         => { name => 'username' },
        'password:s'         => { name => 'password' },
        'timeout:s'          => { name => 'timeout' },
        'cache-expires-in:s' => { name => 'cache_expires_in', default => 10 },
    });

    return $self;
}

sub set_options {
    my ($self, %options) = @_;
    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    $self->{hostname} = $self->{option_results}->{hostname} // '';
    $self->{port}     = $self->{option_results}->{port}     // 443;
    $self->{proto}    = $self->{option_results}->{proto}    // 'https';
    $self->{username} = $self->{option_results}->{username} // '';
    $self->{password} = $self->{option_results}->{password} // '';
    $self->{timeout}  = $self->{option_results}->{timeout}  // 30;

    if ($self->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --hostname option.');
        $self->{output}->option_exit();
    }
    if ($self->{username} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --username option.');
        $self->{output}->option_exit();
    }

    $self->{cache}->check_options(option_results => $self->{option_results});
    return 0;
}

# POST XML to /nuova and return parsed XML::LibXML document
sub _post {
    my ($self, %options) = @_;

    my $content = $self->{http}->request(
        method          => 'POST',
        hostname        => $self->{hostname},
        port            => $self->{port},
        proto           => $self->{proto},
        url_path        => '/nuova',
        timeout         => $self->{timeout},
        header          => ['Content-Type: application/xml'],
        query_form_post => $options{xml},
        unknown_status  => '',
        warning_status  => '',
        critical_status => ''
    );

    if (!defined($content) || $content eq '') {
        $self->{output}->add_option_msg(short_msg => 'No response from UCSM API.');
        $self->{output}->option_exit();
    }

    my $doc;
    eval { $doc = XML::LibXML->new()->parse_string($content); };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot parse XML response: $@");
        $self->{output}->option_exit();
    }
    return $doc;
}

sub _authenticate {
    my ($self, %options) = @_;

    my $xml = sprintf('<aaaLogin inName="%s" inPassword="%s"/>', $self->{username}, $self->{password});
    my $doc  = $self->_post(xml => $xml);
    my $root = $doc->documentElement();

    if (($root->getAttribute('response') // '') ne 'yes') {
        my $err = $root->getAttribute('errorDescr') // 'Unknown error';
        $self->{output}->add_option_msg(short_msg => "UCSM authentication failed: $err");
        $self->{output}->option_exit();
    }

    my $cookie         = $root->getAttribute('outCookie') // '';
    my $refresh_period = $root->getAttribute('outRefreshPeriod') // 600;

    if ($cookie eq '') {
        $self->{output}->add_option_msg(short_msg => 'UCSM returned empty cookie.');
        $self->{output}->option_exit();
    }

    $self->{cache}->write(data => {
        cookie     => $cookie,
        expires_in => time() + $refresh_period - 60,
    });

    return $cookie;
}

sub _get_cookie {
    my ($self, %options) = @_;

    my $has_cache  = $self->{cache}->read(statefile => 'cisco_ucs_xmlapi_' . md5_hex($self->{hostname} . $self->{username}));
    my $cookie     = $self->{cache}->get(name => 'cookie');
    my $expires_in = $self->{cache}->get(name => 'expires_in');

    if ($has_cache == 0 || !defined($cookie) || $cookie eq '' || (defined($expires_in) && time() > $expires_in)) {
        $cookie = $self->_authenticate();
    }
    return $cookie;
}

# Resolve a UCSM managed object class and return arrayref of attribute hashrefs
sub request {
    my ($self, %options) = @_;
    # options: class_id => 'computeBlade'

    my $cookie = $self->_get_cookie();
    my $xml    = sprintf(
        '<configResolveClass cookie="%s" classId="%s" inHierarchical="false"/>',
        $cookie,
        $options{class_id}
    );

    my $doc  = $self->_post(xml => $xml);
    my $root = $doc->documentElement();

    # Expired cookie — re-authenticate once
    if (($root->getAttribute('response') // '') ne 'yes') {
        $cookie = $self->_authenticate();
        $xml    = sprintf(
            '<configResolveClass cookie="%s" classId="%s" inHierarchical="false"/>',
            $cookie, $options{class_id}
        );
        $doc  = $self->_post(xml => $xml);
        $root = $doc->documentElement();
    }

    if (($root->getAttribute('response') // '') ne 'yes') {
        my $err = $root->getAttribute('errorDescr') // 'Unknown error';
        $self->{output}->add_option_msg(short_msg => "API error for class '$options{class_id}': $err");
        $self->{output}->option_exit();
    }

    my @objects;
    my ($out_configs) = $root->findnodes('outConfigs');
    if (defined $out_configs) {
        for my $child ($out_configs->childNodes()) {
            next unless $child->nodeType == XML::LibXML::XML_ELEMENT_NODE;
            my %attrs;
            $attrs{ $_->nodeName() } = $_->getValue() for $child->attributes();
            push @objects, \%attrs;
        }
    }

    return \@objects;
}

sub logout {
    my ($self, %options) = @_;
    my $cookie = $self->{cache}->get(name => 'cookie') // '';
    return if $cookie eq '';

    $self->_post(xml => sprintf('<aaaLogout inCookie="%s"/>', $cookie));
    $self->{cache}->write(data => { cookie => '', expires_in => 0 });
}

1;

__END__

=head1 NAME

hardware::server::cisco::ucs::xmlapi::custom::xmlapi

=head1 SYNOPSIS

Handles UCSM XML API session (cookie-based auth, configResolveClass queries).

=head1 OPTIONS

=over 8

=item B<--hostname>

UCSM IP address or FQDN.

=item B<--port>

HTTPS port (default: 443).

=item B<--proto>

Protocol: http or https (default: https).

=item B<--username>

UCSM admin username.

=item B<--password>

UCSM admin password.

=item B<--timeout>

HTTP request timeout in seconds (default: 30).

=back

=cut
