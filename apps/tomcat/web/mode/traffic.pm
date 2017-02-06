#
# Copyright 2017 Centreon (http://www.centreon.com/)
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

package apps::tomcat::web::mode::traffic;

use base qw(centreon::plugins::mode);
use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use Digest::MD5 qw(md5_hex);
use XML::XPath;
use URI::Escape;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
            {
            "hostname:s"            => { name => 'hostname' },
            "port:s"                => { name => 'port', default => '8080' },
            "proto:s"               => { name => 'proto' },
            "credentials"           => { name => 'credentials' },
            "username:s"            => { name => 'username' },
            "password:s"            => { name => 'password' },
            "proxyurl:s"            => { name => 'proxyurl' },
            "timeout:s"             => { name => 'timeout' },
            "urlpath:s"             => { name => 'url_path', default => '/manager/status?XML=true' },
            "name:s"                => { name => 'name' },
            "regexp"                => { name => 'use_regexp' },
            "regexp-isensitive"     => { name => 'use_regexpi' },
            "speed:s"               => { name => 'speed' },
            "warning-in:s"          => { name => 'warning_in' },
            "critical-in:s"         => { name => 'critical_in' },
            "warning-out:s"         => { name => 'warning_out' },
            "critical-out:s"        => { name => 'critical_out' },
            });

    $self->{result} = {};
    $self->{hostname} = undef;
    $self->{statefile_value} = centreon::plugins::statefile->new(%options);
    $self->{http} = centreon::plugins::http->new(output => $self->{output});
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    if (($self->{perfdata}->threshold_validate(label => 'warning-in', value => $self->{option_results}->{warning_in})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning 'in' threshold '" . $self->{option_results}->{warning_in} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-in', value => $self->{option_results}->{critical_in})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical 'in' threshold '" . $self->{option_results}->{critical_in} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warning-out', value => $self->{option_results}->{warning_out})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning 'out' threshold '" . $self->{option_results}->{warning_out} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-out', value => $self->{option_results}->{critical_out})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical 'out' threshold '" . $self->{option_results}->{critical_out} . "'.");
        $self->{output}->option_exit();
    }
    if (defined($self->{option_results}->{speed}) && $self->{option_results}->{speed} ne '' && $self->{option_results}->{speed} !~ /^[0-9]+(\.[0-9]+){0,1}$/) {
        $self->{output}->add_option_msg(short_msg => "Speed must be a positive number '" . $self->{option_results}->{speed} . "' (can be a float also).");
        $self->{output}->option_exit();
    }
    if (defined($self->{option_results}->{units}) && $self->{option_results}->{units} eq '%' && 
        (!defined($self->{option_results}->{speed}) || $self->{option_results}->{speed} eq '')) {
        $self->{output}->add_option_msg(short_msg => "To use percent, you need to set --speed option.");
        $self->{output}->option_exit();
    }

    $self->{statefile_value}->check_options(%options);
    $self->{hostname} = $self->{option_results}->{hostname};
    if (!defined($self->{hostname})) {
        $self->{hostname} = 'me';
    }
    
    $self->{http}->set_options(%{$self->{option_results}});
}

my %xpath_to_check = (
    in        => '/status/connector/requestInfo/@bytesReceived',
    out       => '/status/connector/requestInfo/@bytesSent',
);

sub manage_selection {
    my ($self, %options) = @_;

    my $webcontent = $self->{http}->request();
    my $port = $self->{option_results}->{port};

    #EXAMPLE 1:
    #<status>
    #  <connector name="http-0">
    #    <threadInfo currentThreadCount="0" currentThreadsBusy="0" maxThreads="200"/>
    #    <requestInfo bytesReceived="0" bytesSent="0" errorCount="0" maxTime="0" processingTime="0" requestCount="0"/>
    #    <workers></workers>
    #  </connector>
    #  <connector name="http-8080">
    #    <threadInfo currentThreadCount="158" currentThreadsBusy="10" maxThreads="200"/>
    #    <requestInfo bytesReceived="297" bytesSent="19350704517" errorCount="192504" maxTime="249349" processingTime="2242513592" requestCount="983650"/>
    #    <workers>
    #    </workers>
    #  </connector>
    #</status>

    #EXAMPLE 2:
    #<status>
    #<jvm>
    #    <memory free='409303928' total='518979584' max='518979584'/>
    #    <memorypool name='Eden Space' type='Heap memory' usageInit='143130624' usageCommitted='143130624' usageMax='143130624' usageUsed='56881560'/>
    #    <memorypool name='Survivor Space' type='Heap memory' usageInit='17891328' usageCommitted='17891328' usageMax='17891328' usageUsed='17891328'/>
    #    <memorypool name='Tenured Gen' type='Heap memory' usageInit='357957632' usageCommitted='357957632' usageMax='357957632' usageUsed='34902768'/>
    #    <memorypool name='Code Cache' type='Non-heap memory' usageInit='2555904' usageCommitted='2555904' usageMax='50331648' usageUsed='1899840'/>
    #    <memorypool name='Perm Gen' type='Non-heap memory' usageInit='21757952' usageCommitted='21757952' usageMax='85983232' usageUsed='21372688'/>
    #</jvm>
    #<connector name='"http-bio-10.1.80.149-22002"'><threadInfo  maxThreads="5" currentThreadCount="2" currentThreadsBusy="1" />
    #    <requestInfo  maxTime="1216" processingTime="1216" requestCount="1" errorCount="1" bytesReceived="0" bytesSent="2474" />
    #    <workers>
    #        <worker  stage="S" requestProcessingTime="23" requestBytesSent="0" requestBytesReceived="0" remoteAddr="10.1.80.149" virtualHost="examplehost" method="GET" currentUri="/manager/status" currentQueryString="XML=true" protocol="HTTP/1.1" />
    #    </workers>
    #</connector>
    #<connector name='"ajp-bio-10.1.80.149-22001"'><threadInfo  maxThreads="150" currentThreadCount="0" currentThreadsBusy="0" />
    #    <requestInfo  maxTime="0" processingTime="0" requestCount="0" errorCount="0" bytesReceived="0" bytesSent="0" />
    #    <workers>
    #    </workers>
    #</connector>
    #</status>

    #GET XML DATA
    my $xpath = XML::XPath->new( xml => $webcontent );
    my %xpath_check_results;

    foreach my $xpath_check ( keys %xpath_to_check ) {
        my $singlepath = $xpath_to_check{$xpath_check};
        $singlepath =~ s{\$port}{$port};
        my $nodeset = $xpath->find($singlepath);

        foreach my $node ($nodeset->get_nodelist) {
            my $connector_name = $node->getParentNode()->getParentNode()->getAttribute("name");
            $connector_name =~ s/^["'\s]+//;
            $connector_name =~ s/["'\s]+$//;
            $connector_name = uri_unescape($connector_name);

            next if (defined($self->{option_results}->{name}) && defined($self->{option_results}->{use_regexp}) && defined($self->{option_results}->{use_regexpi}) 
                && $connector_name !~ /$self->{option_results}->{name}/i);
            next if (defined($self->{option_results}->{name}) && defined($self->{option_results}->{use_regexp}) && !defined($self->{option_results}->{use_regexpi}) 
                && $connector_name !~ /$self->{option_results}->{name}/);
            next if (defined($self->{option_results}->{name}) && !defined($self->{option_results}->{use_regexp}) && !defined($self->{option_results}->{use_regexpi})
                && $connector_name ne $self->{option_results}->{name});

            my $value = $node->string_value();
            if ( $value =~ /^"?([0-9.]+)"?$/ ) {
                $self->{result}->{$connector_name}{$xpath_check} = $1;
            } else {
                $self->{result}->{$connector_name}{$xpath_check} = "not_numeric";
            };
        };

        if (scalar(keys %{$self->{result}}) <= 0) {
                if (defined($self->{option_results}->{name})) {
                    $self->{output}->add_option_msg(short_msg => "No information found for name '" . $self->{option_results}->{name} . "'.");
                } else {
                    $self->{output}->add_option_msg(short_msg => "No information found.");
                }
                $self->{output}->option_exit();
        };
    };
};

sub run {
    my ($self, %options) = @_;
    
    $self->manage_selection();

    my $new_datas = {};
    $self->{statefile_value}->read(statefile => 'cache_apps_tomcat_web_' . $self->{option_results}->{hostname} . '_' . $self->{http}->get_port() . '_' . $self->{mode} . '_' . (defined($self->{option_results}->{name}) ? md5_hex($self->{option_results}->{name}) : md5_hex('all')));
    $new_datas->{last_timestamp} = time();
    my $old_timestamp = $self->{statefile_value}->get(name => 'last_timestamp');

    if (!defined($self->{option_results}->{name}) || defined($self->{option_results}->{use_regexp})) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'All traffic are ok.');
    }

    foreach my $name (sort(keys %{$self->{result}})) {
        $new_datas->{'in_' . $name} = $self->{result}->{$name}->{in} * 8;
        $new_datas->{'out_' . $name} = $self->{result}->{$name}->{out} * 8;
        
        my $old_in = $self->{statefile_value}->get(name => 'in_' . $name);
        my $old_out = $self->{statefile_value}->get(name => 'out_' . $name);
        if (!defined($old_timestamp) || !defined($old_in) || !defined($old_out)) {
            next;
        }
        if ($new_datas->{'in_' . $name} < $old_in) {
            # We set 0. Has reboot.
            $old_in = 0;
        }
        if ($new_datas->{'out_' . $name} < $old_out) {
            # We set 0. Has reboot.
            $old_out = 0;
        }

        my $time_delta = $new_datas->{last_timestamp} - $old_timestamp;
        if ($time_delta <= 0) {
            # At least one second. two fast calls ;)
            $time_delta = 1;
        }
        my $in_absolute_per_sec = ($new_datas->{'in_' . $name} - $old_in) / $time_delta;
        my $out_absolute_per_sec = ($new_datas->{'out_' . $name} - $old_out) / $time_delta;

        my ($exit, $interface_speed, $in_prct, $out_prct);
        if (defined($self->{option_results}->{speed}) && $self->{option_results}->{speed} ne '') {
            $interface_speed = $self->{option_results}->{speed} * 1000000;
            $in_prct = $in_absolute_per_sec * 100 / ($self->{option_results}->{speed} * 1000000);
            $out_prct = $out_absolute_per_sec * 100 / ($self->{option_results}->{speed} * 1000000);
            if ($self->{option_results}->{units} eq '%') {
                my $exit1 = $self->{perfdata}->threshold_check(value => $in_prct, threshold => [ { label => 'critical-in', 'exit_litteral' => 'critical' }, { label => 'warning-in', exit_litteral => 'warning' } ]);
                my $exit2 = $self->{perfdata}->threshold_check(value => $out_prct, threshold => [ { label => 'critical-out', 'exit_litteral' => 'critical' }, { label => 'warning-out', exit_litteral => 'warning' } ]);
                $exit = $self->{output}->get_most_critical(status => [ $exit1, $exit2 ]);
            }
            $in_prct = sprintf("%.2f", $in_prct);
            $out_prct = sprintf("%.2f", $out_prct);
        } else {
            my $exit1 = $self->{perfdata}->threshold_check(value => $in_absolute_per_sec, threshold => [ { label => 'critical-in', 'exit_litteral' => 'critical' }, { label => 'warning-in', exit_litteral => 'warning' } ]);
            my $exit2 = $self->{perfdata}->threshold_check(value => $out_absolute_per_sec, threshold => [ { label => 'critical-out', 'exit_litteral' => 'critical' }, { label => 'warning-out', exit_litteral => 'warning' } ]);
            $exit = $self->{output}->get_most_critical(status => [ $exit1, $exit2 ]);
            $in_prct = '-';
            $out_prct = '-';
        }
       
        ###########
        # Manage Output
        ###########
        
        my ($in_value, $in_unit) = $self->{perfdata}->change_bytes(value => $in_absolute_per_sec, network => 1);
        my ($out_value, $out_unit) = $self->{perfdata}->change_bytes(value => $out_absolute_per_sec, network => 1);
        $self->{output}->output_add(long_msg => sprintf("Connector '%s' Traffic In : %s/s (%s %%), Out : %s/s (%s %%) ", $name,
                                       $in_value . $in_unit, $in_prct,
                                       $out_value . $out_unit, $out_prct));
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1) || (defined($self->{option_results}->{name}) && !defined($self->{option_results}->{use_regexp}))) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Connector '%s' Traffic In : %s/s (%s %%), Out : %s/s (%s %%) ", $name,
                                            $in_value . $in_unit, $in_prct,
                                            $out_value . $out_unit, $out_prct));
        }

        my $extra_label = '';
        $extra_label = '_' . $name if (!defined($self->{option_results}->{name}) || defined($self->{option_results}->{use_regexp}));

        $self->{output}->perfdata_add(label => 'traffic_in' . $extra_label, unit => 'b/s',
                                      value => sprintf("%.2f", $in_absolute_per_sec),
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-in', total => $interface_speed),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-in', total => $interface_speed),
                                      min => 0, max => $interface_speed);
        $self->{output}->perfdata_add(label => 'traffic_out' . $extra_label, unit => 'b/s',
                                      value => sprintf("%.2f", $out_absolute_per_sec),
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-out', total => $interface_speed),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-out', total => $interface_speed),
                                      min => 0, max => $interface_speed);
    }
    
    $self->{statefile_value}->write(data => $new_datas);    
    if (!defined($old_timestamp)) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => "Buffer creation...");
    }

    $self->{output}->display();
    $self->{output}->exit();
};

1;

__END__

=head1 MODE

Check Tomcat Application Servers Traffic for each Connector

=over 8

=item B<--hostname>

IP Address or FQDN of the Tomcat Application Server

=item B<--port>

Port used by Tomcat

=item B<--proxyurl>

Proxy URL if any

=item B<--proto>

Protocol used http or https

=item B<--credentials>

Specify this option if you access server-status page over basic authentification

=item B<--username>

Specify username for basic authentification (Mandatory if --credentials is specidied)

=item B<--password>

Specify password for basic authentification (Mandatory if --credentials is specidied)

=item B<--timeout>

Threshold for HTTP timeout

=item B<--urlpath>

Path to the Tomcat Manager XML (Default: '/manager/status?XML=true')

=item B<--name>

Set the filter name (empty means 'check all contexts')

=item B<--regexp>

Allows to use regexp to filter (with option --name).

=item B<--regexp-isensitive>

Allows to use regexp non case-sensitive (with --regexp).

=item B<--warning-in>

Threshold warning in percent for 'in' traffic.

=item B<--critical-in>

Threshold critical in percent for 'in' traffic.

=item B<--warning-out>

Threshold warning in percent for 'out' traffic.

=item B<--critical-out>

Threshold critical in percent for 'out' traffic.

=item B<--speed>

Set Connector Interface speed (in Mb).

=back

=cut
