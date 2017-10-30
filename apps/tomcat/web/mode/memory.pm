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

package apps::tomcat::web::mode::memory;

use base qw(centreon::plugins::mode);
use strict;
use warnings;
use centreon::plugins::http;
use XML::XPath;

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
            "warning:s"             => { name => 'warning' },
            "critical:s"            => { name => 'critical' },
            });

    $self->{result} = {};
    $self->{http} = centreon::plugins::http->new(output => $self->{output});
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
        $self->{output}->option_exit();
    }

    $self->{http}->set_options(%{$self->{option_results}});
}

my %xpath_to_check = (
    memMax => '/status/jvm/memory/@max',
    memFree => '/status/jvm/memory/@free',
    memTotal => '/status/jvm/memory/@total',
);

sub run {
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
            my $value = $node->string_value();
            if ( $value =~ /^"?([0-9.]+)"?$/ ) {
                $self->{result}->{$xpath_check} = $1;
            } else {
                $self->{result}->{$xpath_check} = "not_numeric";
            };
        };
    };

    my $memTotal = $self->{result}->{memTotal};
    my $memFree = $self->{result}->{memFree};
    my $memMax = $self->{result}->{memMax};
    my $memUsed = $memTotal - $memFree;
    my $memUsed_prct = $memUsed * 100 / $memTotal;

    if (!defined($memTotal) || !defined($memFree) || !defined($memUsed) || !defined($memUsed_prct)) {
        $self->{output}->add_option_msg(short_msg => "Some informations missing.");
        $self->{output}->option_exit();
    }

    my $exit = $self->{perfdata}->threshold_check(value => $memUsed_prct, threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

    my ($memTotal_value, $memTotal_unit) = $self->{perfdata}->change_bytes(value => $memTotal);
    my ($memFree_value, $memFree_unit) = $self->{perfdata}->change_bytes(value => $memFree);
    my ($memMax_value, $memMax_unit) = $self->{perfdata}->change_bytes(value => $memMax);
    my ($memUsed_value, $memUsed_unit) = $self->{perfdata}->change_bytes(value => $memUsed);


    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("Memory used %s (%.2f%%)",
                                            $memUsed_value . " " . $memUsed_unit, $memUsed_prct));

    $self->{output}->perfdata_add(label => "used", unit => 'B',
                                  value => $memUsed,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning', total => $memTotal),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical', total => $memTotal),
                                  min => 0, max => $memTotal);    
 
    $self->{output}->display();
    $self->{output}->exit();
};

1;

__END__

=head1 MODE

Check Tomcat Application Servers Memory Usage

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

=item B<--warning>

Threshold warning in percent.

=item B<--critical>

Threshold critical in percent.

=back

=cut
