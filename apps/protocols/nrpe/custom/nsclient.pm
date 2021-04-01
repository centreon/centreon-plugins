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

package apps::protocols::nrpe::custom::nsclient;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::http;
use URI::Encode;
use JSON::XS;

my %errors_num = (0 => 'OK', 1 => 'WARNING', 2 => 'CRITICAL', 3 => 'UNKNOWN');

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
            'hostname:s'             => { name => 'hostname' },
            'port:s'                 => { name => 'port' },
            'proto:s'                => { name => 'proto' },
            'credentials'            => { name => 'credentials' },
            'basic'                  => { name => 'basic' },
            'username:s'             => { name => 'username' },
            'password:s'             => { name => 'password' },
            'legacy-password:s'      => { name => 'legacy_password' },
            'new-api'                => { name => 'new_api' },
            'timeout:s'              => { name => 'timeout' },
            'unknown-http-status:s'  => { name => 'unknown_http_status' },
            'warning-http-status:s'  => { name => 'warning_http_status' },
            'critical-http-status:s' => { name => 'critical_http_status' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'CUSTOM MODE OPTIONS', once => 1);

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

    $self->{hostname} = (defined($self->{option_results}->{hostname})) ? $self->{option_results}->{hostname} : '';
    $self->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 8443;
    $self->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'https';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 10;
    $self->{username} = (defined($self->{option_results}->{username})) ? $self->{option_results}->{username} : undef;
    $self->{password} = (defined($self->{option_results}->{password})) ? $self->{option_results}->{password} : undef;
    $self->{legacy_password} = (defined($self->{option_results}->{legacy_password})) ? $self->{option_results}->{legacy_password} : undef;
    $self->{unknown_http_status} = (defined($self->{option_results}->{unknown_http_status})) ? $self->{option_results}->{unknown_http_status} : '%{http_code} < 200 or %{http_code} >= 300' ;
    $self->{warning_http_status} = (defined($self->{option_results}->{warning_http_status})) ? $self->{option_results}->{warning_http_status} : '';
    $self->{critical_http_status} = (defined($self->{option_results}->{critical_http_status})) ? $self->{option_results}->{critical_http_status} : '';

    if ($self->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --hostname option.');
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

    if (defined($self->{username})) {
        $self->{option_results}->{username} = $self->{username};
        $self->{option_results}->{password} = $self->{password};
        $self->{option_results}->{credentials} = 1;
        $self->{option_results}->{basic} = 1;
    }
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    if (defined($self->{legacy_password}) &&  $self->{legacy_password} ne '') {
        $self->{http}->add_header(key => 'password', value => $self->{legacy_password});
    }
    $self->{http}->set_options(%{$self->{option_results}});
}

sub output_perf {
    my ($self, %options) = @_;

    my $result = 'UNKNOWN';
    $result = $errors_num{$options{result}} if ($options{result} =~ /[0-3]/);
    $result = $options{result} if ($options{result} =~ /[A-Z]+/);

    my %result = (
        code => $result,
        message => $options{data}->{message}
    );

    if (defined($self->{option_results}->{new_api})) {
        foreach (keys %{$options{data}->{perf}}) {
            my $printf_format = '%d';
            ($options{data}->{perf}->{$_}->{value} =~ /\.(\d\d\d)/);
            $printf_format = '%.3f' if ($options{data}->{perf}->{$_}->{value} =~ /\.(\d\d\d)/ && $1 !~ /000/);
            
            push @{$result{perf}}, {
                label => $_,
                unit => $options{data}->{perf}->{$_}->{unit},
                value => sprintf($printf_format, $options{data}->{perf}->{$_}->{value}),
                warning => defined($options{data}->{perf}->{$_}->{warning}) ? sprintf($printf_format, $options{data}->{perf}->{$_}->{warning}) : undef,
                critical => defined($options{data}->{perf}->{$_}->{critical}) ? sprintf($printf_format, $options{data}->{perf}->{$_}->{critical}) : undef,
                min => defined($options{data}->{perf}->{$_}->{minimum}) ? sprintf($printf_format, $options{data}->{perf}->{$_}->{minimum}) : undef,
                max => defined($options{data}->{perf}->{$_}->{maximum}) ? sprintf($printf_format, $options{data}->{perf}->{$_}->{maximum}) : undef,
            };
        }
    } else {
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
        $decoded = JSON::XS->new->decode($options{content});
    };
    if ($@) {
        $self->{output}->output_add(long_msg => $options{content}, debug => 1);
        $self->{output}->add_option_msg(short_msg => "Cannot decode response (add --debug option to display returned content)");
        $self->{output}->option_exit();
    }

    my $entry;
    if (defined($self->{option_results}->{new_api})) {
        $entry = $decoded;
    } else {
        $entry = $decoded->{payload}->[0];
    }
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
    
    my $url = '';
    my $uri = URI::Encode->new({encode_reserved => 1});
    my ($encoded_args, $append) = ('', '');
    if (defined($options{arg})) {
        foreach (@{$options{arg}}) {
            $encoded_args .= $append . $uri->encode($_);
            $append = '&';
        }
    }
    
    if (defined($self->{option_results}->{new_api})) {
        $url = '/api/v1/queries/' . $options{command} . '/commands/execute?' . $encoded_args
    } else {
        $url = '/query/' . $options{command} . '?' . $encoded_args
    }
    my ($content) = $self->{http}->request(
        url_path => $url,
        unknown_status => $self->{unknown_http_status},
        warning_status => $self->{warning_http_status},
        critical_status => $self->{critical_http_status}
    );
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

NSClient++ Rest API (New v1 & Legacy)

=head1 CUSTOM MODE OPTIONS

NSClient++ Rest API

=over 8

=item B<--hostname>

Remote hostname or IP address.

=item B<--port>

Port used (Default: 8443)

=item B<--proto>

Specify https if needed (Default: 'https')

=item B<--username>

Specify username for authentication (If basic authentication)

=item B<--password>

Specify password for authentication (If basic authentication)

=item B<--legacy-password>

Specify password for old authentication system.

=item B<--new-api>

Use new RestAPI (> 5.2.33).

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
