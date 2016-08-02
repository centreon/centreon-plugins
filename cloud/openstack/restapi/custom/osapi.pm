#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package cloud::openstack::restapi::custom::osapi;

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::plugins::http;
use JSON;

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;
    # $options{options} = options object
    # $options{output} = output object
    # $options{exit_value} = integer
    # $options{noptions} = integer

    if (!defined($options{output})) {
        print "Class Custom: Need to specify 'output' argument.\n";
        exit 3;
    }
    if (!defined($options{options})) {
        $options{output}->add_option_msg(short_msg => "Class Custom: Need to specify 'options' argument.");
        $options{output}->option_exit();
    }

    if (!defined($options{noptions})) {
        $options{options}->add_options(arguments =>
                    {
                        "hostname:s"    => { name => 'hostname' },
                        "data:s"        => { name => 'data' },
                        "proto:s"       => { name => 'proto' },
         				"credentials"   => { name => 'credentials' },
         				"ntlm"          => { name => 'ntlm' },
         				"username:s"    => { name => 'username' },
         				"password:s"    => { name => 'password' },
         				"proxyurl:s"    => { name => 'proxyurl' },
         				"proxypac:s"    => { name => 'proxypac' },
         				"timeout:s"     => { name => 'timeout' },
         				"ssl:s"         => { name => 'ssl' },
         				"cert-file:s"   => { name => 'cert_file' },
         				"key-file:s"    => { name => 'key_file' },
         				"cacert-file:s" => { name => 'cacert_file' },
         				"cert-pwd:s"    => { name => 'cert_pwd' },
         				"cert-pkcs12"   => { name => 'cert_pkcs12' },
				    });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'TOKEN REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{mode} = $options{mode};
    $self->{http} = centreon::plugins::http->new(output => $self->{output});

    return $self;

}

# Method to manage multiples
sub set_options {
    my ($self, %options) = @_;
    # options{options_result}

    $self->{option_results} = $options{option_results};
}

# Method to manage multiples
sub set_defaults {
    my ($self, %options) = @_;
    # options{default}

    # Manage default value
    foreach (keys %{$options{default}}) {
        if ($_ eq $self->{mode}) {
            for (my $i = 0; $i < scalar(@{$options{default}->{$_}}); $i++) {
                foreach my $opt (keys %{$options{default}->{$_}[$i]}) {
                    if (!defined($self->{option_results}->{$opt}[$i])) {
                        $self->{option_results}->{$opt}[$i] = $options{default}->{$_}[$i]->{$opt};
                    }
                }
            }
        }
    }
}

sub check_options {
    my ($self, %options) = @_;

    if (!defined($self->{option_results}->{data}) || $self->{option_results}->{data} eq '') {
        $self->{output}->add_option_msg(short_msg => "You need to specify --data option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{hostname}) || $self->{option_results}->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => "You need to specify --hostname option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{proto}) || $self->{option_results}->{proto} eq '') {
        $self->{output}->add_option_msg(short_msg => "You need to specify --proto option.");
        $self->{output}->option_exit();
    }
}

sub token_request {
    my ($self, %options) = @_;

    $self->{option_results}->{url_path} = '/v3/auth/tokens';
	$self->{option_results}->{port} = '5000';
	@{$self->{option_results}->{header}} = 'Content-Type: application/json';
    $self->{http}->set_options(%{$self->{option_results}});

    $self->{method} = 'GET';
    if (defined($self->{option_results}->{data})) {
        local $/ = undef;
        if (!open(FILE, "<", $self->{option_results}->{data})) {
            $self->{output}->output_add(severity => 'UNKNOWN',
                                        short_msg => sprintf("Could not read file '%s': %s", $self->{option_results}->{data}, $!));
            $self->{output}->display();
            $self->{output}->exit();
        }
        $self->{json_request} = <FILE>;
        close FILE;
        $self->{method} = 'POST';
    }

    my $response = $self->{http}->request(method => $self->{method}, query_form_post => $self->{json_request});
    my $headers = $self->{http}->get_header();

    eval {
        $self->{header} = $headers->header('X-Subject-Token');
    };

    if ($@) {
		$self->{output}->add_option_msg(short_msg => "Cannot retrieve API Token");
        $self->{output}->option_exit();
    }
}

sub api_request {
    my ($self, %options) = @_;

    $self->token_request();

    $self->{option_results}->{url_path} = $options{urlpath};
    $self->{option_results}->{port} = $options{port};
    $self->{method} = 'GET';
    @{$self->{option_results}->{header}} = ('X-Auth-Token:' . $self->{header}, 'Accept:application/json');
    $self->{http}->set_options(%{$self->{option_results}});

    my $webcontent;
    my $jsoncontent = $self->{http}->request(method => $self->{method});

    my $json = JSON->new;

    eval {
        $webcontent = $json->decode($jsoncontent);
    };

    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot retrieve any information");
        $self->{output}->option_exit();
    }

	return $webcontent;
}


1;

__END__

=head1 NAME

OpenStack REST API

=head1 SYNOPSIS

OpenStack Rest API custom mode

=head1 REST API OPTIONS

=over 8

=item B<--data>

Set file with JSON request

=item B<--hostname>

IP Addr/FQDN of the webserver host

=item B<--port>

Port used by Webserver

=item B<--proto>

Specify https if needed (Default: 'http')

=item B<--credentials>

Specify this option if you access webpage over basic authentification

=item B<--ntlm>

Specify this option if you access webpage over ntlm authentification (Use with --credentials option)

=item B<--username>

Specify username for basic authentification (Mandatory if --credentials is specidied)

=item B<--password>

Specify password for basic authentification (Mandatory if --credentials is specidied)

=item B<--proxyurl>

Proxy URL

=item B<--proxypac>

Proxy pac file (can be an url or local file)

=item B<--timeout>

Threshold for HTTP timeout (Default: 5)

=item B<--ssl>

Specify SSL version (example : 'sslv3', 'tlsv1'...)

=item B<--cert-file>

Specify certificate to send to the webserver

=item B<--key-file>

Specify key to send to the webserver

=item B<--cacert-file>

Specify root certificate to send to the webserver

=item B<--cert-pwd>

Specify certificate's password

=item B<--cert-pkcs12>

Specify type of certificate (PKCS12)

=back

=head1 DESCRIPTION

B<custom>.

=cut
