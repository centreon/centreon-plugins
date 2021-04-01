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

package apps::nsclient::restapi::mode::query;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::http;
use JSON;
use URI::Encode;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
         "hostname:s"           => { name => 'hostname' },
         "port:s"               => { name => 'port', default => 8443 },
         "proto:s"              => { name => 'proto', default => 'https' },
         "credentials"          => { name => 'credentials' },
         "basic"                => { name => 'basic' },
         "username:s"           => { name => 'username' },
         "password:s"           => { name => 'password' },
         "legacy-password:s"    => { name => 'legacy_password' },
         "timeout:s"            => { name => 'timeout' },
         "command:s"            => { name => 'command' },
         "arg:s@"               => { name => 'arg' },
         "unknown-status:s"     => { name => 'unknown_status', default => '%{http_code} < 200 or %{http_code} >= 300' },
         "warning-status:s"     => { name => 'warning_status' },
         "critical-status:s"    => { name => 'critical_status', default => '' },
    });
    
    $self->{http} = centreon::plugins::http->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{command}) || $self->{option_results}->{command} eq '') {
        $self->{output}->add_option_msg(short_msg => "Please set command option");
        $self->{output}->option_exit();
    }
    if (defined($self->{option_results}->{legacy_password}) &&  $self->{option_results}->{legacy_password} ne '') {
        $self->{http}->add_header(key => 'password', value => $self->{option_results}->{legacy_password});
    }
    $self->{http}->set_options(%{$self->{option_results}});
}

# Two kind of outputs.
# 1-
#    {"header":{"source_id":""},"payload":[{"command":"check_centreon_plugins","lines":[{"message":"OK: Reboot Pending : False | 'value1'=10;;;; 'value2'=10;;;;\r\nlong1\r\nlong2"}],"result":"OK"}]}
# 2- Can be also "int_value".
#    { "header":{"source_id":""},
#      "payload": [
#         {"command":"check_drivesize",
#          "lines": [
#              {"message":"OK All 1 drive(s) are ok",
#                "perf":[
#                  {"alias":"C:\\ used",
#                   "float_value": {
#                   "critical":44.690621566027403,
#                   "maximum":49.656246185302734,
#                   "minimum":0.00000000000000000,
#                   "unit":"GB",
#                   "value":21.684593200683594,
#                   "warning":39.724996947683394}
#                   },
#                   {"alias":"C:\\ used %","float_value":{"critical":90.000000000000000,"maximum":100.00000000000000,"minimum":0.00000000000000000,"unit":"%","value":44.000000000000000,"warning":80.000000000000000}}]}],
#       "result":"OK"}]}

sub nscp_output_perf {
    my ($self, %options) = @_;

    $self->{output}->output_add(severity => $options{result},
                                short_msg => $options{data}->{message});
    foreach (@{$options{data}->{perf}}) {
        my $perf = defined($_->{float_value}) ? $_->{float_value} : $_->{int_value};
        my $printf_format = '%d';
        $printf_format = '%.3f' if (defined($_->{float_value}));
        
        $self->{output}->perfdata_add(label => $_->{alias}, unit => $perf->{unit},
                                      value => sprintf($printf_format, $perf->{value}),
                                      warning => defined($perf->{warning}) ? sprintf($printf_format, $perf->{warning}) : undef,
                                      critical => defined($perf->{critical}) ? sprintf($printf_format, $perf->{critical}) : undef,
                                      min => defined($perf->{minimum}) ? sprintf($printf_format, $perf->{minimum}) : undef,
                                      max => defined($perf->{maximum}) ? sprintf($printf_format, $perf->{maximum}) : undef,
                                      );
    }
}

sub nscp_output_noperf {
    my ($self, %options) = @_;
    
    $self->{output}->output_add(severity => $options{result},
                                short_msg => $options{data}->{message});
}

sub check_nscp_result {
    my ($self, %options) = @_;
    
    my $decoded;
    eval {
        $decoded = decode_json($options{content});
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
        $self->{output}->option_exit();
    }

    my $entry = $decoded->{payload}->[0];
    $entry->{lines}->[0]->{message} =~ s/\r//msg;
    if (defined($entry->{lines}->[0]->{perf})) {
        $self->nscp_output_perf(result => $entry->{result}, data => $entry->{lines}->[0]);
        $self->{output}->display(nolabel => 1);
    } else {
        $self->nscp_output_noperf(result => $entry->{result}, data => $entry->{lines}->[0]);
        $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    }
}

sub run {
    my ($self, %options) = @_;

    my $uri = URI::Encode->new({encode_reserved => 1});
    my ($encoded_args, $append) = ('', '');
    if (defined($self->{option_results}->{arg})) {
        foreach (@{$self->{option_results}->{arg}}) {
            $encoded_args .= $append . $uri->encode($_);
            $append = '&';
        }
    }
    
    my ($content) = $self->{http}->request(url_path => '/query/' . $self->{option_results}->{command} . '?' . $encoded_args);
    $self->{output}->output_add(long_msg => "nsclient return = " . $content, debug => 1);
    $self->check_nscp_result(content => $content);
                                  
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Query NSClient Legacy API.

=over 8

=item B<--hostname>

IP Addr/FQDN of the host

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

Specify password for old authentification system.

=item B<--timeout>

Threshold for HTTP timeout (Default: 5)

=item B<--command>

Set command.

=item B<--arg>

Set arguments (Multiple option. Example: --arg='arg1')

=item B<--unknown-status>

Threshold warning for http response code.
(Default: '%{http_code} < 200 or %{http_code} >= 300')

=item B<--warning-status>

Threshold warning for http response code.

=item B<--critical-status>

Threshold critical for http response code.

=back

=cut
