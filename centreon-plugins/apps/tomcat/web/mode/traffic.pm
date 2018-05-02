#
# Copyright 2018 Centreon (http://www.centreon.com/)
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

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::http;
use Digest::MD5 qw(md5_hex);
use XML::XPath;
use URI::Escape;

my $instance_mode;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'connector', type => 1, cb_prefix_output => 'prefix_connector_output', message_multiple => 'All connector traffics are ok' },
    ];

    $self->{maps_counters}->{connector} = [
        { label => 'in', set => {
                key_values => [ { name => 'in', diff => 1 }, { name => 'display' } ],
                per_second => 1,
                closure_custom_calc => $self->can('custom_traffic_calc'), closure_custom_calc_extra_options => { label_ref => 'in' },
                closure_custom_output => $self->can('custom_traffic_output'),
                closure_custom_perfdata => $self->can('custom_traffic_perfdata'),
                closure_custom_threshold_check => $self->can('custom_traffic_threshold'),
            }
        },
        { label => 'out', set => {
                key_values => [ { name => 'out', diff => 1 }, { name => 'display' } ],
                per_second => 1,
                closure_custom_calc => $self->can('custom_traffic_calc'), closure_custom_calc_extra_options => { label_ref => 'out' },
                closure_custom_output => $self->can('custom_traffic_output'),
                closure_custom_perfdata => $self->can('custom_traffic_perfdata'),
                closure_custom_threshold_check => $self->can('custom_traffic_threshold'),
            }
        },
    ];
}

sub custom_traffic_perfdata {
    my ($self, %options) = @_;

    my $extra_label = '';
    if (!defined($options{extra_instance}) || $options{extra_instance} != 0) {
        $extra_label .= '_' . $self->{result_values}->{display};
    }

    my ($warning, $critical);
    if ($instance_mode->{option_results}->{units_traffic} eq '%' && defined($self->{result_values}->{speed})) {
        $warning = $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label}, total => $self->{result_values}->{speed}, cast_int => 1);
        $critical = $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label}, total => $self->{result_values}->{speed}, cast_int => 1);
    } elsif ($instance_mode->{option_results}->{units_traffic} eq 'b/s') {
        $warning = $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label});
        $critical = $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label});
    }

    $self->{output}->perfdata_add(label => 'traffic_' . $self->{result_values}->{label} . $extra_label, unit => 'b/s',
                                  value => sprintf("%.2f", $self->{result_values}->{traffic}),
                                  warning => $warning,
                                  critical => $critical,
                                  min => 0, max => $self->{result_values}->{speed});
}

sub custom_traffic_threshold {
    my ($self, %options) = @_;

    my $exit = 'ok';
    if ($instance_mode->{option_results}->{units_traffic} eq '%' && defined($self->{result_values}->{speed})) {
        $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{traffic_prct}, threshold => [ { label => 'critical-' . $self->{label}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{label}, exit_litteral => 'warning' } ]);
    } elsif ($instance_mode->{option_results}->{units_traffic} eq 'b/s') {
        $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{traffic}, threshold => [ { label => 'critical-' . $self->{label}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{label}, exit_litteral => 'warning' } ]);
    }
    return $exit;
}

sub custom_traffic_output {
    my ($self, %options) = @_;

    my ($traffic_value, $traffic_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{traffic}, network => 1);
    my ($total_value, $total_unit);
    if (defined($self->{result_values}->{speed}) && $self->{result_values}->{speed} =~ /[0-9]/) {
        ($total_value, $total_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{speed}, network => 1);
    }

    my $msg = sprintf("Traffic %s : %s/s (%s on %s)",
                      ucfirst($self->{result_values}->{label}), $traffic_value . $traffic_unit,
                      defined($self->{result_values}->{traffic_prct}) ? sprintf("%.2f%%", $self->{result_values}->{traffic_prct}) : '-',
                      defined($total_value) ? $total_value . $total_unit : '-');
    return $msg;
}

sub custom_traffic_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{label} = $options{extra_options}->{label_ref};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    my $diff_traffic = $options{new_datas}->{$self->{instance} . '_' . $self->{result_values}->{label}} - $options{old_datas}->{$self->{instance} . '_' . $self->{result_values}->{label}};
    $self->{result_values}->{traffic} = $diff_traffic / $options{delta_time};
    if (defined($instance_mode->{option_results}->{'speed_' . $self->{result_values}->{label}}) && $instance_mode->{option_results}->{'speed_' . $self->{result_values}->{label}} =~ /[0-9]/) {
        $self->{result_values}->{traffic_prct} = $self->{result_values}->{traffic} * 100 / ($instance_mode->{option_results}->{'speed_' . $self->{result_values}->{label}} * 1000 * 1000);
        $self->{result_values}->{speed} = $instance_mode->{option_results}->{'speed_' . $self->{result_values}->{label}} * 1000 * 1000;
    }
    return 0;
}

sub prefix_connector_output {
    my ($self, %options) = @_;

    return "Connector '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
            {
            "hostname:s"            => { name => 'hostname' },
            "port:s"                => { name => 'port', default => '8080' },
            "proto:s"               => { name => 'proto' },
            "credentials"           => { name => 'credentials' },
            "basic"                 => { name => 'basic' },
            "username:s"            => { name => 'username' },
            "password:s"            => { name => 'password' },
            "proxyurl:s"            => { name => 'proxyurl' },
            "timeout:s"             => { name => 'timeout' },
            "ssl-opt:s@"            => { name => 'ssl_opt' },
            "urlpath:s"             => { name => 'url_path', default => '/manager/status?XML=true' },
            "filter-name:s"         => { name => 'filter_name' },
            "speed-in:s"            => { name => 'speed_in' },
            "speed-out:s"           => { name => 'speed_out' },
            "units-traffic:s"       => { name => 'units_traffic', default => '%' },
            });

    $self->{http} = centreon::plugins::http->new(output => $self->{output});
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{hostname} = $self->{option_results}->{hostname};
    if (!defined($self->{hostname})) {
        $self->{hostname} = 'me';
    }
    
    $self->{http}->set_options(%{$self->{option_results}});
    $instance_mode = $self;
}

my %xpath_to_check = (
    in  => '/status/connector/requestInfo/@bytesReceived',
    out => '/status/connector/requestInfo/@bytesSent',
);

sub manage_selection {
    my ($self, %options) = @_;

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
    my $webcontent = $self->{http}->request();

    #GET XML DATA
    my $xpath = XML::XPath->new(xml => $webcontent);
    my %xpath_check_results;

    $self->{connector} = {};
    foreach my $label (keys %xpath_to_check) {
        my $singlepath = $xpath_to_check{$label};
        my $nodeset = $xpath->find($singlepath);

        foreach my $node ($nodeset->get_nodelist()) {
            my $connector_name = $node->getParentNode()->getParentNode()->getAttribute("name");
            $connector_name =~ s/^["'\s]+//;
            $connector_name =~ s/["'\s]+$//;
            $connector_name = uri_unescape($connector_name);

            if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
                $connector_name !~ /$self->{option_results}->{filter_name}/) {
                $self->{output}->output_add(long_msg => "skipping '" . $connector_name . "': no matching filter.", debug => 1);
                next;
            }

            next if (defined($self->{option_results}->{name}) && defined($self->{option_results}->{use_regexp}) && defined($self->{option_results}->{use_regexpi}) 
                && $connector_name !~ /$self->{option_results}->{name}/i);
            next if (defined($self->{option_results}->{name}) && defined($self->{option_results}->{use_regexp}) && !defined($self->{option_results}->{use_regexpi}) 
                && $connector_name !~ /$self->{option_results}->{name}/);
            next if (defined($self->{option_results}->{name}) && !defined($self->{option_results}->{use_regexp}) && !defined($self->{option_results}->{use_regexpi})
                && $connector_name ne $self->{option_results}->{name});

            $self->{connector}->{$connector_name} = { display => $connector_name } if (!defined($self->{connector}->{$connector_name}));
            my $value = $node->string_value();
            if ($value =~ /^"?([0-9.]+)"?$/) {
                $self->{connector}->{$connector_name}->{$label} = $1 * 8;
            }
        }
    }
    
    if (scalar(keys %{$self->{connector}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No information found.");
        $self->{output}->option_exit();
    }
    
    $self->{cache_name} = "tomcat_web_" . $self->{mode} . '_' . $self->{option_results}->{hostname}  . '_' . $self->{http}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));
}

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

Specify this option if you access server-status page with authentication

=item B<--username>

Specify username for authentication (Mandatory if --credentials is specified)

=item B<--password>

Specify password for authentication (Mandatory if --credentials is specified)

=item B<--basic>

Specify this option if you access server-status page over basic authentication and don't want a '401 UNAUTHORIZED' error to be logged on your webserver.

Specify this option if you access server-status page over hidden basic authentication or you'll get a '404 NOT FOUND' error.

(Use with --credentials)

=item B<--timeout>

Threshold for HTTP timeout

=item B<--ssl-opt>

Set SSL Options (--ssl-opt="SSL_version => TLSv1" --ssl-opt="SSL_verify_mode => SSL_VERIFY_NONE").

=item B<--urlpath>

Path to the Tomcat Manager XML (Default: '/manager/status?XML=true')

=item B<--filter-name>

Filter by context name (can be a regexp).

=item B<--warning-*>

Threshold warning.
Can be: 'in', 'out'.

=item B<--critical-*>

Threshold critical.
Can be: 'in', 'out'.

=item B<--units-traffic>

Units of thresholds for the traffic (Default: '%') ('%', 'b/s').

=item B<--speed-in>

Set interface speed for incoming traffic (in Mb).

=item B<--speed-out>

Set interface speed for outgoing traffic (in Mb).

=back

=cut
