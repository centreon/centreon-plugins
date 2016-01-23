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

package apps::protocols::http::mode::jsoncontent;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use Time::HiRes qw(gettimeofday tv_interval);
use centreon::plugins::http;
use JSON::Path;
use JSON;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.2';
    $options{options}->add_options(arguments =>
            {
            "data:s"                => { name => 'data' },
            "lookup:s@"             => { name => 'lookup' },
            "hostname:s"            => { name => 'hostname' },
            "http-peer-addr:s"      => { name => 'http_peer_addr' },
            "vhost:s"               => { name => 'vhost' },
            "port:s"                => { name => 'port', },
            "proto:s"               => { name => 'proto' },
            "urlpath:s"             => { name => 'url_path' },
            "credentials"           => { name => 'credentials' },
            "ntlm"                  => { name => 'ntlm' },
            "username:s"            => { name => 'username' },
            "password:s"            => { name => 'password' },
            "proxyurl:s"            => { name => 'proxyurl' },
            "proxypac:s"            => { name => 'proxypac' },
            "header:s@"             => { name => 'header' },
            "get-param:s@"          => { name => 'get_param' },
            "timeout:s"             => { name => 'timeout', default => 10 },
            "ssl:s"                 => { name => 'ssl', },
            "cert-file:s"           => { name => 'cert_file' },
            "key-file:s"            => { name => 'key_file' },
            "cacert-file:s"         => { name => 'cacert_file' },
            "cert-pwd:s"            => { name => 'cert_pwd' },
            "cert-pkcs12"           => { name => 'cert_pkcs12' },
            "unknown-status:s"      => { name => 'unknown_status' },
            "warning-status:s"      => { name => 'warning_status' },
            "critical-status:s"     => { name => 'critical_status' },

            "warning-numeric:s"       => { name => 'warning_numeric' },
            "critical-numeric:s"      => { name => 'critical_numeric' },
            "warning-string:s"        => { name => 'warning_string' },
            "critical-string:s"       => { name => 'critical_string' },
            "warning-time:s"          => { name => 'warning_time' },
            "critical-time:s"         => { name => 'critical_time' },
            "threshold-value:s"       => { name => 'threshold_value', default => 'count' },
            "format-ok:s"             => { name => 'format_ok', default => '%{count} element(s) finded' },
            "format-warning:s"        => { name => 'format_warning', default => '%{count} element(s) finded' },
            "format-critical:s"       => { name => 'format_critical', default => '%{count} element(s) finded' },
            "values-separator:s"      => { name => 'values_separator', default => ', ' },
            });
    $self->{count} = 0;
    $self->{count_ok} = 0;
    $self->{count_warning} = 0;
    $self->{count_critical} = 0;
    $self->{values_ok} = [];
    $self->{values_warning} = [];
    $self->{values_critical} = [];
    $self->{values_string_ok} = [];
    $self->{values_string_warning} = [];
    $self->{values_string_critical} = [];
    $self->{http} = centreon::plugins::http->new(output => $self->{output});
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{threshold_value}) || $self->{option_results}->{threshold_value} !~ /^(count|values)$/) {
        $self->{option_results}->{threshold_value} = 'count';
    }
    if (($self->{perfdata}->threshold_validate(label => 'warning-numeric', value => $self->{option_results}->{warning_numeric})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning-numeric threshold '" . $self->{option_results}->{warning_numeric} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-numeric', value => $self->{option_results}->{critical_numeric})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical-numeric threshold '" . $self->{option_results}->{critical_numeric} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warning-time', value => $self->{option_results}->{warning_time})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning-time threshold '" . $self->{option_results}->{warning_time} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-time', value => $self->{option_results}->{critical_time})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical-time threshold '" . $self->{option_results}->{critical_time} . "'.");
       $self->{output}->option_exit();
    }

    $self->{http}->set_options(%{$self->{option_results}});
}

sub load_request {
    my ($self, %options) = @_;

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
}

sub display_output {
    my ($self, %options) = @_;

    foreach my $severity (('ok', 'warning', 'critical')) {
        next if (scalar(@{$self->{'values_' . $severity}}) == 0 && scalar(@{$self->{'values_string_' . $severity}}) == 0);
        my $format = $self->{option_results}->{'format_' . $severity};
        while ($format =~ /%{(.*?)}/g) {
            my $replace = '';
            if (ref($self->{$1}) eq 'ARRAY') {
                $replace = join($self->{option_results}->{values_separator}, @{$self->{$1}});
            } else {
                $replace = defined($self->{$1}) ? $self->{$1} : '';
            }
            $format =~ s/%{$1}/$replace/g;
        }
        $self->{output}->output_add(severity => $severity,
                                    short_msg => $format);
    }
}

sub lookup {
    my ($self, %options) = @_;
    my ($xpath, @values);

    my $json = JSON->new;
    my $content;
    eval {
        $content = $json->decode($self->{json_response});
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response");
        $self->{output}->option_exit();
    }

    foreach my $xpath_find (@{$self->{option_results}->{lookup}}) {
        eval {
            my $jpath = JSON::Path->new($xpath_find);
            @values = $jpath->values($content);
        };
        if ($@) {
            $self->{output}->add_option_msg(short_msg => "Cannot lookup: $@");
            $self->{output}->option_exit();
        }

        $self->{output}->output_add(long_msg => "Lookup XPath $xpath_find:");
        foreach my $value (@values) {
            $self->{count}++;
            $self->{output}->output_add(long_msg => '   Node value: ' . $value);
            push @{$self->{values}}, $value;
        }
    }

    if ($self->{option_results}->{threshold_value} eq 'count') {
        my $exit = lc($self->{perfdata}->threshold_check(value => $self->{count},
                                                         threshold => [ { label => 'critical-numeric', exit_litteral => 'critical' }, { label => 'warning-numeric', exit_litteral => 'warning' } ]));
        push @{$self->{'values_' . $exit}}, $self->{count};
        $self->{'count_' . $exit}++;
    }

    $self->{output}->perfdata_add(label => 'count',
                                  value => $self->{count},
                                  warning => $self->{option_results}->{threshold_value} eq 'count' ? $self->{perfdata}->get_perfdata_for_output(label => 'warning-numeric') : undef,
                                  critical => $self->{option_results}->{threshold_value} eq 'count' ? $self->{perfdata}->get_perfdata_for_output(label => 'critical-numeric') : undef,
                                  min => 0);

    my $count = 0;
    foreach my $value (@{$self->{values}}) {
        $count++;
        if ($value =~ /^[0-9.]+$/) {
            if ($self->{option_results}->{threshold_value} eq 'values') {
                my $exit = lc($self->{perfdata}->threshold_check(value => $value,
                                            threshold => [ { label => 'critical-numeric', exit_litteral => 'critical' }, { label => 'warning-numeric', exit_litteral => 'warning' } ]));
                push @{$self->{'values_' . $exit}}, $value;
                $self->{'count_' . $exit}++
            }
            $self->{output}->perfdata_add(label => 'element_' . $count,
                                          value => $value,
                                          warning => $self->{option_results}->{threshold_value} eq 'values' ? $self->{perfdata}->get_perfdata_for_output(label => 'warning-numeric') : undef,
                                          critical => $self->{option_results}->{threshold_value} eq 'values' ? $self->{perfdata}->get_perfdata_for_output(label => 'critical-numeric') : undef);
        } else {
            if (defined($self->{option_results}->{critical_string}) && $self->{option_results}->{critical_string} ne '' &&
                $value =~ /$self->{option_results}->{critical_string}/) {
                push @{$self->{values_string_critical}}, $value;
            } elsif (defined($self->{option_results}->{warning_string}) && $self->{option_results}->{warning_string} ne '' &&
                     $value =~ /$self->{option_results}->{warning_string}/) {
                push @{$self->{values_string_warning}}, $value;
            } else {
                push @{$self->{values_string_ok}}, $value;
            }
        }
    }

    $self->display_output();
}

sub run {
    my ($self, %options) = @_;

    $self->load_request();

    my $timing0 = [gettimeofday];
    $self->{json_response} = $self->{http}->request(method => $self->{method}, query_form_post => $self->{json_request});
    my $timeelapsed = tv_interval ($timing0, [gettimeofday]);

    $self->{output}->output_add(long_msg => $self->{json_response});
    if (!defined($self->{option_results}->{lookup}) || scalar(@{$self->{option_results}->{lookup}}) == 0) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => "JSON webservice request success");
    } else {
        $self->lookup();
    }

    my $exit = $self->{perfdata}->threshold_check(value => $timeelapsed,
                                                  threshold => [ { label => 'critical-time', exit_litteral => 'critical' }, { label => 'warning-time', exit_litteral => 'warning' } ]);
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("Response time %.3fs", $timeelapsed));
    } else {
        $self->{output}->output_add(long_msg => sprintf("Response time %.3fs", $timeelapsed));
    }
    $self->{output}->perfdata_add(label => "time", unit => 's',
                                  value => sprintf('%.3f', $timeelapsed),
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-time'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-time'),
                                  min => 0);

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check JSON webservice. Can send the json request with option '--data'. Example:
centreon_plugins.pl --plugin=apps::protocols::http::plugin --mode=json-content --data='/home/user/request.json' --hostname='myws.site.com' --urlpath='/get/payment'
--lookup='$..expiration'

JSON OPTIONS:

=over 8

=item B<--data>

Set file with JSON request

=item B<--lookup>

What to lookup in JSON response (JSON XPath string) (can be multiple)
See: http://goessner.net/articles/JsonPath/

=back

FORMAT OPTIONS:

=over 8

=item B<--format-ok>

Output format (Default: '%{count} element(s) finded')
Can used:
'%{values}' = display all values (also text string)
'%{values_ok}' = values from attributes and text node only (seperated by option values-separator)
'%{values_warning}' and '%{values_critical}'

=item B<--format-warning>

Output warning format (Default: %{count} element(s) finded')

=item B<--format-critical>

Output critical format (Default: %{count} element(s) finded')

=item B<--values-separator>

Separator used for values in format option (Default: ', ')

=back

THRESHOLD OPTIONS:

=over 8

=item B<--warning-numeric>

Threshold warning (Default: on total matching elements)

=item B<--critical-numeric>

Threshold critical (Default: on total matching elements)

=item B<--threshold-value>

Which value to use (Default: 'count')
Can be: 'values' (only check numeric values)

=item B<--warning-string>

Threshold warning if the string match

=item B<--critical-string>

Threshold critical if the string match

=item B<--warning-time>

Threshold warning in seconds of webservice response time

=item B<--critical-time>

Threshold critical in seconds of webservice response time

=back

HTTP OPTIONS:

=over 8

=item B<--hostname>

IP Addr/FQDN of the Webserver host

=item B<--http-peer-addr>

Set the address you want to connect (Useful if hostname is only a vhost. no ip resolve)

=item B<--port>

Port used by Webserver

=item B<--proxyurl>

Proxy URL

=item B<--proxypac>

Proxy pac file (can be an url or local file)

=item B<--proto>

Specify https if needed

=item B<--urlpath>

Set path to get Webpage (Default: '/')

=item B<--credentials>

Specify this option if you access webpage over basic authentification

=item B<--ntlm>

Specify this option if you access webpage over ntlm authentification (Use with --credentials option)

=item B<--username>

Specify username for basic authentification (Mandatory if --credentials is specidied)

=item B<--password>

Specify password for basic authentification (Mandatory if --credentials is specidied)

=item B<--timeout>

Threshold for HTTP timeout (Default: 10)

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

=item B<--get-param>

Set GET params (Multiple option. Example: --get-param='key=value')

=item B<--header>

Set HTTP headers (Multiple option. Example: --header='Content-Type: xxxxx')

=item B<--unknown-status>

Threshold warning for http response code (Default: '%{http_code} < 200 or %{http_code} >= 300')

=item B<--warning-status>

Threshold warning for http response code

=item B<--critical-status>

Threshold critical for http response code

=back

=cut
