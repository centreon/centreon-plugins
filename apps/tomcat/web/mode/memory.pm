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

package apps::tomcat::web::mode::memory;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::http;
use XML::XPath;

sub custom_memory_output {
    my ($self, %options) = @_;

    my $msg = sprintf("Memory Total: %s %s Used: %s %s (%.2f%%) Free: %s %s (%.2f%%)",
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{total}),
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{used}),
        $self->{result_values}->{prct_used},
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{free}),
        $self->{result_values}->{prct_free});
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'usage', nlabel => 'memory.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_memory_output'),
                perfdatas => [
                    { value => 'used', template => '%d', min => 0, max => 'total',
                      unit => 'B', cast_int => 1 },
                ],
            }
        },
        { label => 'usage-free', display_ok => 0, nlabel => 'memory.free.bytes', set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_memory_output'),
                perfdatas => [
                    { value => 'free', template => '%d', min => 0, max => 'total',
                      unit => 'B', cast_int => 1 },
                ],
            }
        },
        { label => 'usage-prct', display_ok => 0, nlabel => 'memory.usage.percentage', set => {
                key_values => [ { name => 'prct_used' } ],
                output_template => 'Memory Used : %.2f %%',
                perfdatas => [
                    { value => 'prct_used', template => '%.2f', min => 0, max => 100, unit => '%' },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'hostname:s'    => { name => 'hostname' },
        'port:s'        => { name => 'port', default => '8080' },
        'proto:s'       => { name => 'proto' },
        'credentials'   => { name => 'credentials' },
        'basic'         => { name => 'basic' },
        'username:s'    => { name => 'username' },
        'password:s'    => { name => 'password' },
        'timeout:s'     => { name => 'timeout' },
        'urlpath:s'     => { name => 'url_path', default => '/manager/status?XML=true' },
    });

    $self->{http} = centreon::plugins::http->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{http}->set_options(%{$self->{option_results}});
}

my %xpath_to_check = (
    memMax => '/status/jvm/memory/@max',
    memFree => '/status/jvm/memory/@free',
    memTotal => '/status/jvm/memory/@total',
);

sub manage_selection {
    my ($self, %options) = @_;
    
    my $webcontent = $self->{http}->request();

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

    my $result = {};
    my $xpath = XML::XPath->new(xml => $webcontent);
    foreach my $xpath_check (keys %xpath_to_check) {
        my $nodeset = $xpath->find($xpath_to_check{$xpath_check});

        foreach my $node ($nodeset->get_nodelist()) {
            my $value = $node->string_value();
            if ($value =~ /^"?([0-9.]+)"?$/) {
                $result->{$xpath_check} = $1;
            }
        };
    };

    if (!defined($result->{memTotal}) || !defined($result->{memFree})) {
        $self->{output}->add_option_msg(short_msg => "some informations missing.");
        $self->{output}->option_exit();
    }

    my $total = $result->{memTotal};
    $self->{global} = {
        total => $total,
        free => $result->{memFree},
        used => $total - $result->{memFree},
        prct_free => $result->{memFree} * 100 / $total,
        prct_used => ($result->{memTotal} - $result->{memFree}) * 100 / $total,
    };
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

=item B<--urlpath>

Path to the Tomcat Manager XML (Default: '/manager/status?XML=true')

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'usage' (B), 'usage-free' (B), 'usage-prct' (%).

=back

=cut
