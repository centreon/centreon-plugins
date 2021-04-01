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

package blockchain::parity::restapi::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use JSON;

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
            "hostname:s"    => { name => 'hostname' },                     
            "port:s"        => { name => 'port' },
            "timeout:s"     => { name => 'timeout' },
            "api-path:s"    => { name => 'api_path' },
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{mode} = $options{mode};
    $self->{http} = centreon::plugins::http->new(%options);
    
    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {
    my ($self, %options) = @_;

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

    $self->{hostname}   = (defined($self->{option_results}->{hostname})) ? $self->{option_results}->{hostname} : undef;
    $self->{port}       = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 8545;
    $self->{timeout}    = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 10;
    $self->{api_path}   = (defined($self->{option_results}->{api_path})) ? $self->{option_results}->{api_path} : '/';
 
    if (!defined($self->{hostname})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify hostname option.");
        $self->{output}->option_exit();
    }
    return 0;
}

sub get_connection_infos {
    my ($self, %options) = @_;
    
    return $self->{hostname}  . '_' . $self->{http}->get_port();
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{hostname} = $self->{hostname};
    $self->{option_results}->{timeout} = $self->{timeout};
    $self->{option_results}->{port} = $self->{port};
    $self->{option_results}->{proto} = 'http';
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    $self->{http}->add_header(key => 'Content-Type', value => 'application/json');
    $self->{http}->set_options(%{$self->{option_results}});
}

sub request_api {
    my ($self, %options) = @_;


    $self->settings();

    my $encoded;
    eval {
        $encoded = encode_json($options{query_form_post});
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot encode json request");
        $self->{output}->option_exit();
    }
    
    my $content = $self->{http}->request(method => $options{method}, url_path => '/', query_form_post => $encoded,
        critical_status => '', warning_status => '', unknown_status => '');

    my $decoded;
    eval {
        $decoded = decode_json($content);
    };
    if ($@) {
        $self->{output}->output_add(long_msg => $content, debug => 1);
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response");
        $self->{output}->option_exit();
    }
    if ($self->{http}->get_code() != 200) {
        $self->{output}->add_option_msg(short_msg => "Connection issue: " . $decoded->{msg});
        $self->{output}->option_exit();
    }

    return $decoded;
}

1;

__END__

=head1 NAME

Parity node JSON WEBRPC

=head1 SYNOPSIS

Parity node JSON RPC API custom mode

=head1 REST API OPTIONS

=over 8

=item B<--hostname>

Parity node hostname or IP

=item B<--timeout>

Set HTTP timeout in seconds (Default: '10').

=item B<--api-path>

API base url path (Default: '/').

=back

=head1 DESCRIPTION

B<custom>.

=cut
