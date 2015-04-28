###############################################################################
# Copyright 2005-2015 CENTREON
# Centreon is developped by : Julien Mathis and Romain Le Merlus under
# GPL Licence 2.0.
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation ; either version 2 of the License.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, see <http://www.gnu.org/licenses>.
#
# Linking this program statically or dynamically with other modules is making a
# combined work based on this program. Thus, the terms and conditions of the GNU
# General Public License cover the whole combination.
#
# As a special exception, the copyright holders of this program give CENTREON
# permission to link this program with independent modules to produce an timeelapsedutable,
# regardless of the license terms of these independent modules, and to copy and
# distribute the resulting timeelapsedutable under terms of CENTREON choice, provided that
# CENTREON also meet, for each linked independent module, the terms  and conditions
# of the license of that module. An independent module is a module which is not
# derived from this program. If you modify this program, you may extend this
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
#
# For more information : contact@centreon.com
# Authors : Simon BOMM <sbomm@merethis.com>
#           Mathieu Cinquin <mcinquin@merethis.com>
#
# Based on De Bodt Lieven plugin
####################################################################################

package apps::protocols::http::mode::soapcontent;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use Time::HiRes qw(gettimeofday tv_interval);
use centreon::plugins::httplib;
use XML::XPath;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.1';
    $options{options}->add_options(arguments =>
            {
            "service-soap:s"        => { name => 'service_soap' },
            "data:s"                => { name => 'data' },
            "lookup:s@"             => { name => 'lookup' },
            "hostname:s"            => { name => 'hostname' },
            "port:s"                => { name => 'port', },
            "proto:s"               => { name => 'proto', default => "http" },
            "urlpath:s"             => { name => 'url_path', default => "/" },
            "credentials"           => { name => 'credentials' },
            "ntlm"                  => { name => 'ntlm' },
            "username:s"            => { name => 'username' },
            "password:s"            => { name => 'password' },
            "proxyurl:s"            => { name => 'proxyurl' },
            "header:s@"             => { name => 'header' },
            "timeout:s"             => { name => 'timeout', default => 10 },
            "ssl:s"					=> { name => 'ssl', },
            "cert-file:s"           => { name => 'cert_file' },
            "cert-pwd:s"            => { name => 'cert_pwd' },
            "cert-pkcs12"           => { name => 'cert_pkcs12' },

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
    if (!defined($self->{option_results}->{service_soap})) {
        $self->{output}->add_option_msg(short_msg => "You need to specify service-soap.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{data})) {
        $self->{output}->add_option_msg(short_msg => "You need to specify data.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{hostname})) {
        $self->{output}->add_option_msg(short_msg => "You need to specify hostname.");
        $self->{output}->option_exit();
    }
    if ((defined($self->{option_results}->{credentials})) && (!defined($self->{option_results}->{username}) || !defined($self->{option_results}->{password}))) {
        $self->{output}->add_option_msg(short_msg => "You need to set --username= and --password= options when --credentials is used");
        $self->{output}->option_exit();
    }
    if ((!defined($self->{option_results}->{credentials})) && (defined($self->{option_results}->{ntlm}))) {
        $self->{output}->add_option_msg(short_msg => "--ntlm option must be used with --credentials option");
        $self->{output}->option_exit();
    }
    if ((defined($self->{option_results}->{pkcs12})) && (!defined($self->{option_results}->{cert_file}) && !defined($self->{option_results}->{cert_pwd}))) {
        $self->{output}->add_option_msg(short_msg => "You need to set --cert-file= and --cert-pwd= options when --pkcs12 is used");
        $self->{output}->option_exit();
    }
    $self->{headers} = {};
    if (defined($self->{option_results}->{header})) {
        foreach (@{$self->{option_results}->{header}}) {
            if (/^(.*?):(.*)/) {
                $self->{headers}->{$1} = $2;
            }
        }
    }
    $self->{headers}->{SOAPAction} = $self->{option_results}->{service_soap};
}

sub load_request {
    my ($self, %options) = @_;

    local $/ = undef;
    if (!open(FILE, "<", $self->{option_results}->{data})) {
        $self->{output}->output_add(severity => 'UNKNOWN',
                                    short_msg => sprintf("Could not read file '%s': %s", $self->{option_results}->{data}, $!));
        $self->{output}->display();
        $self->{output}->exit();
    }
    $self->{soap_request} = <FILE>;
    close FILE;
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
    my ($xpath, $nodeset);

    eval {
        $xpath = XML::XPath->new(xml => $self->{soap_response});
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot load SOAP response");
        $self->{output}->option_exit();
    }

    foreach my $xpath_find (@{$self->{option_results}->{lookup}}) {
        eval {
            $nodeset = $xpath->find($xpath_find);
        };
        if ($@) {
            $self->{output}->add_option_msg(short_msg => "Cannot lookup: $@");
            $self->{output}->option_exit();
        }

        $self->{output}->output_add(long_msg => "Lookup XPath $xpath_find:");
        foreach my $node ($nodeset->get_nodelist()) {
            $self->{count}++;
            my $node_type = ref($node);
            $self->{output}->output_add(long_msg => "   Node type: $node_type");
            if ($node_type eq 'XML::XPath::Node::Text') {
                $self->{output}->output_add(long_msg => '   Node value: ' . $node->string_value);
                push @{$self->{values}}, $node->string_value;
            }
            if ($node_type eq 'XML::XPath::Node::Attribute') {
                $self->{output}->output_add(long_msg => '   Node value: ' . $node->toString);
                push @{$self->{values}}, $node->getNodeValue;
            }
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

    if (!defined($self->{option_results}->{port})) {
        $self->{option_results}->{port} = centreon::plugins::httplib::get_port($self);
    }
    $self->load_request();

    my $timing0 = [gettimeofday];
    $self->{soap_response} = centreon::plugins::httplib::connect($self, headers => $self->{headers}, method => 'POST', query_form_post => $self->{soap_request});
    my $timeelapsed = tv_interval ($timing0, [gettimeofday]);

    $self->{output}->output_add(long_msg => $self->{soap_response});
    if (!defined($self->{option_results}->{lookup}) || scalar(@{$self->{option_results}->{lookup}}) == 0) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => "SOAP request success");
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

Check SOAP content. Send the soap request with option '--data'. Example:
centreon_plugins.pl --plugin=apps::protocols::http::plugin --mode=soap-content --service-soap='http://www.mysite.com/mysoapaction'
--header='Content-Type: text/xml;charset=UTF-8' --data='/home/user/soap_request.xml' --hostname='myws.site.com' --urlpath='/get/payment'
--lookup='//numeric/text()'

SOAP OPTIONS:

=over 8

=item B<--service-soap>

Service Soap Action (Required)

=item B<--data>

Set file with SOAP request (Required)

=item B<--lookup>

What to lookup in XML response (XPath string) (can be multiple)

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

Threshold warning in ms of webservice response time

=item B<--critical-time>

Threshold critical in ms of webservice response time

=back

HTTP OPTIONS:

=over 8

=item B<--hostname>

IP Addr/FQDN of the Webserver host

=item B<--port>

Port used by Webserver

=item B<--proxyurl>

Proxy URL if any

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

=item B<--cert-pwd>

Specify certificate's password

=item B<--cert-pkcs12>

Specify type of certificate (PKCS1

=item B<--header>

Set HTTP headers (Multiple option)

=back

=cut
