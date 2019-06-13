#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package apps::protocols::nrpe::custom::nsclient;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::http;
use URI::Encode;
use JSON::XS;

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
            "hostname:s"            => { name => 'hostname' },
            "port:s"                => { name => 'port' },
            "proto:s"               => { name => 'proto' },
            "credentials"           => { name => 'credentials' },
            "basic"                 => { name => 'basic' },
            "username:s"            => { name => 'username' },
            "password:s"            => { name => 'password' },
            "legacy-password:s"     => { name => 'legacy_password' },
            "timeout:s"             => { name => 'timeout' },
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'CUSTOM MODE OPTIONS', once => 1);

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

    $self->{hostname} = (defined($self->{option_results}->{hostname})) ? $self->{option_results}->{hostname} : '';
    $self->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 8443;
    $self->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'https';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 10;
    $self->{username} = (defined($self->{option_results}->{username})) ? $self->{option_results}->{username} : undef;
    $self->{password} = (defined($self->{option_results}->{password})) ? $self->{option_results}->{password} : undef;
    $self->{legacy_password} = (defined($self->{option_results}->{legacy_password})) ? $self->{option_results}->{legacy_password} : undef;
    $self->{credentials} = (defined($self->{option_results}->{credentials})) ? 1 : undef;
    $self->{basic} = (defined($self->{option_results}->{basic})) ? 1 : undef;

    if (!defined($self->{hostname}) || $self->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --hostname option.");
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
    $self->{option_results}->{timeout} = $self->{timeout};
    $self->{option_results}->{warning_status} = '';
    $self->{option_results}->{critical_status} = '';
    $self->{option_results}->{unknown_status} = '%{http_code} < 200 or %{http_code} >= 300';
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    if (defined($self->{legacy_password}) &&  $self->{legacy_password} ne '') {
        $self->{http}->add_header(key => 'password', value => $self->{legacy_password});
    }
    $self->{http}->set_options(%{$self->{option_results}});
}

# Two kind of outputs.
# 1-
# {
# 	"header": {
# 		"source_id": ""
# 	},
# 	"payload": [{
# 		"command": "check_centreon_plugins",
# 		"lines": [{
# 			"message": "OK: Reboot Pending : False | 'value1'=10;;;; 'value2'=10;;;;\r\nlong1\r\nlong2"
# 		}],
# 		"result": "OK"
# 	}]
# }
# 2- Can be also "int_value".
# {
#   "header": {
# 	    "source_id": ""
# 	},
# 	"payload": [{
# 		"command": "check_drivesize",
# 		"lines": [{
# 			"message": "OK All 1 drive(s) are ok",
# 			"perf": [{
# 					"alias": "C",
# 					"float_value": {
# 						"critical": 44.690621566027403,
# 						"maximum": 49.656246185302734,
# 						"minimum": 0.00000000000000000,
# 						"unit": "GB",
# 						"value": 21.684593200683594,
# 						"warning": 39.724996947683394
# 					}
# 				},
# 				{
# 					"alias": "C",
# 					"float_value": {
# 						"critical": 90.000000000000000,
# 						"maximum": 100.00000000000000,
# 						"minimum": 0.00000000000000000,
# 						"unit": "%",
# 						"value": 44.000000000000000,
# 						"warning": 80.000000000000000
# 					}
# 				}
# 			]
# 		}],
# 		"result": "OK"
# 	}]
# }

sub output_perf {
    my ($self, %options) = @_;

    my %result = (
        code => $options{result},
        message => $options{data}->{message}
    );

    foreach (@{$options{data}->{perf}}) {
        my $perf = defined($_->{float_value}) ? $_->{float_value} : $_->{int_value};
        my $printf_format = '%d';
        $printf_format = '%.3f' if (defined($_->{float_value}));
        
        push @{$result{perf}}, {
            label => $_->{alias},
            unit => $perf->{unit},
            value => sprintf($printf_format, $perf->{value}),
            warning => defined($perf->{warning}) ? sprintf($printf_format, $perf->{warning}) : undef,
            critical => defined($perf->{critical}) ? sprintf($printf_format, $perf->{critical}) : undef,
            min => defined($perf->{minimum}) ? sprintf($printf_format, $perf->{minimum}) : undef,
            max => defined($perf->{maximum}) ? sprintf($printf_format, $perf->{maximum}) : undef,
        };
    }
    return \%result;
}

sub output_noperf {
    my ($self, %options) = @_;
    
    my %result = (
        code => $options{result},
        message => $options{data}->{message},
        perf => []
    );
    return \%result;
}

sub format_result {
    my ($self, %options) = @_;
    
    my $decoded;
    eval {
        $decoded = decode_json($options{content});
    };
    if ($@) {
        $self->{output}->output_add(long_msg => $options{content}, debug => 1);
        $self->{output}->add_option_msg(short_msg => "Cannot decode response (add --debug option to display returned content)");
        $self->{output}->option_exit();
    }

    my $entry = $decoded->{payload}->[0];
    $entry->{lines}->[0]->{message} =~ s/\r//msg;
    if (defined($entry->{lines}->[0]->{perf})) {
        return $self->output_perf(result => $entry->{result}, data => $entry->{lines}->[0]);
    } else {
        return $self->output_noperf(result => $entry->{result}, data => $entry->{lines}->[0]);
    }
}

sub request {
    my ($self, %options) = @_;

    $self->settings();
    
    my $uri = URI::Encode->new({encode_reserved => 1});
    my ($encoded_args, $append) = ('', '');
    if (defined($options{arg})) {
        foreach (@{$options{arg}}) {
            $encoded_args .= $append . $uri->encode($_);
            $append = '&';
        }
    }
    
    my ($content) = $self->{http}->request(url_path => '/query/' . $options{command} . '?' . $encoded_args);
    if (!defined($content) || $content eq '') {
        $self->{output}->add_option_msg(short_msg => "API returns empty content [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']");
        $self->{output}->option_exit();
    }
    $self->{output}->output_add(long_msg => "nsclient return = " . $content, debug => 1);

    my $result = $self->format_result(content => $content);
    
    return $result;
}

1;

__END__

=head1 NAME

NSClient++ Rest API

=head1 CUSTOM MODE OPTIONS

NSClient++ Rest API

=over 8

=item B<--hostname>

Remote hostname or IP address.

=item B<--port>

Port used (Default: 8443)

=item B<--proto>

Specify https if needed (Default: 'https')

=item B<--credentials>

Specify this option if you access webpage with authentication

=item B<--username>

Specify username for authentication (Mandatory if --credentials is specified)

=item B<--password>

Specify password for authentication (Mandatory if --credentials is specified)

=item B<--basic>

Specify this option if you access webpage over basic authentication and don't want a '401 UNAUTHORIZED' error to be logged on your webserver.

Specify this option if you access webpage over hidden basic authentication or you'll get a '404 NOT FOUND' error.

(Use with --credentials)

=item B<--legacy-password>

Specify password for old authentication system.

=item B<--timeout>

Set timeout in seconds (Default: 10).

=item B<--unknown-status>

Threshold warning for http response code.
(Default: '%{http_code} < 200 or %{http_code} >= 300')

=item B<--warning-status>

Threshold warning for http response code.

=item B<--critical-status>

Threshold critical for http response code.

=back

=head1 DESCRIPTION

B<custom>.

=cut
