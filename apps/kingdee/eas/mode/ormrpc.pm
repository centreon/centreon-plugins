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
# Author : CHEN JUN , aladdin.china@gmail.com

package apps::kingdee::eas::mode::ormrpc;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ( $class, %options ) = @_;
    my $self = $class->SUPER::new( package => __PACKAGE__, %options );
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(
        arguments => {
            "urlpath:s"          => { name => 'url_path', default => "/easportal/tools/nagios/checkrpc.jsp" },
            "warning:s"          => { name => 'warning' , default => ",,,,,,"},
            "critical:s"         => { name => 'critical' , default => ",,,,,,"},
        }
    );

    return $self;
}

sub check_options {
    my ( $self, %options ) = @_;
    $self->SUPER::init(%options);

    ($self->{warn_activethreadcount}, $self->{warn_stubcount}, $self->{warn_proxycount}, $self->{warn_clientsessioncount} ,$self->{warn_serversessioncount} ,$self->{warn_invokecountpermin} ,$self->{warn_servicecountpermin}) 
        = split /,/, $self->{option_results}->{"warning"};
    ($self->{crit_activethreadcount}, $self->{crit_stubcount}, $self->{crit_proxycount}, $self->{crit_clientsessioncount} ,$self->{crit_serversessioncount} ,$self->{crit_invokecountpermin} ,$self->{crit_servicecountpermin}) 
        = split /,/, $self->{option_results}->{"critical"};

    # warning
    if (($self->{perfdata}->threshold_validate(label => 'warn_activethreadcount', value => $self->{warn_activethreadcount})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning activethreadcount threshold '" . $self->{warn_activethreadcount} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warn_stubcount', value => $self->{warn_stubcount})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning stubcount threshold '" . $self->{warn_stubcount} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warn_proxycount', value => $self->{warn_proxycount})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning proxycount threshold '" . $self->{warn_proxycount} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warn_clientsessioncount', value => $self->{warn_clientsessioncount})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning clientsessioncount threshold '" . $self->{warn_clientsessioncount} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warn_serversessioncount', value => $self->{warn_serversessioncount})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning serversessioncount threshold '" . $self->{warn_serversessioncount} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warn_invokecountpermin', value => $self->{warn_invokecountpermin})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning invokecountpermin threshold '" . $self->{warn_invokecountpermin} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warn_servicecountpermin', value => $self->{warn_servicecountpermin})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning servicecountpermin threshold '" . $self->{warn_servicecountpermin} . "'.");
       $self->{output}->option_exit();
    }

    # critical
    if (($self->{perfdata}->threshold_validate(label => 'crit_activethreadcount', value => $self->{crit_activethreadcount})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical activethreadcount threshold '" . $self->{crit_activethreadcount} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'crit_stubcount', value => $self->{crit_stubcount})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical stubcount threshold '" . $self->{crit_stubcount} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'crit_proxycount', value => $self->{crit_proxycount})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical proxycount threshold '" . $self->{crit_proxycount} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'crit_clientsessioncount', value => $self->{crit_clientsessioncount})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical clientsessioncount threshold '" . $self->{crit_clientsessioncount} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'crit_serversessioncount', value => $self->{crit_serversessioncount})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical serversessioncount threshold '" . $self->{crit_serversessioncount} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'crit_invokecountpermin', value => $self->{crit_invokecountpermin})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical invokecountpermin threshold '" . $self->{crit_invokecountpermin} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'crit_servicecountpermin', value => $self->{crit_servicecountpermin})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical servicecountpermin threshold '" . $self->{crit_servicecountpermin} . "'.");
       $self->{output}->option_exit();
    }
}

sub run {
    my ( $self, %options ) = @_;

    my $webcontent = $options{custom}->request(path => $self->{option_results}->{url_path});
    if ($webcontent !~ /ActiveThreadCount=\d+/i) {
        $self->{output}->output_add(
            severity  => 'UNKNOWN',
            short_msg => "Cannot find ormrpc status in response: \'" . $webcontent . "\'"
        );
        $self->{output}->option_exit();
    }

    my ($activethreadcount, $stubcount, $proxycount, $clientsessioncount, $serversessioncount, $invokecountpermin, $servicecountpermin, $invokecount, $servicecount) = (0, 0, 0, 0, 0, 0, 0, 0, 0);

    $activethreadcount = $1 if $webcontent =~ /ActiveThreadCount=(\d+)/mi ;
    $stubcount = $1 if $webcontent =~ /StubCount=(\d+)/mi ;
    $proxycount = $1 if $webcontent =~ /ProxyCount=(\d+)/mi ;
    $clientsessioncount = $1 if $webcontent =~ /ClientSessionCount=(\d+)/mi ;
    $serversessioncount = $1 if $webcontent =~ /ServerSessionCount=(\d+)/mi ;
    $invokecountpermin = $1 if $webcontent =~ /ClientInvokeCountPerMinute=(\d+)/mi ;
    $servicecountpermin = $1 if $webcontent =~ /ProcessedServiceCountPerMinute=(\d+)/mi ;
    $invokecount = $1 if $webcontent =~ /ClientInvokeCount=(\d+)/mi ;
    $servicecount = $1 if $webcontent =~ /ProcessedServiceCount=(\d+)/mi ;
    
    my $exit = $self->{perfdata}->threshold_check(value => $activethreadcount, 
        threshold => [ { label => 'crit_activethreadcount', 'exit_litteral' => 'critical' }, 
                       { label => 'warn_activethreadcount', 'exit_litteral' => 'warning' } ]);
    $self->{output}->output_add(
        severity  => $exit,
        short_msg => sprintf("ActiveTrheadCount: %d", $activethreadcount)
    );
    $exit = $self->{perfdata}->threshold_check(value => $stubcount, 
        threshold => [ { label => 'crit_stubcount', 'exit_litteral' => 'critical' }, 
                       { label => 'warn_stubcount', 'exit_litteral' => 'warning' } ]);
    $self->{output}->output_add(
        severity  => $exit,
        short_msg => sprintf("StubCount: %d", $stubcount)
    );
    $exit = $self->{perfdata}->threshold_check(value => $proxycount, 
        threshold => [ { label => 'crit_proxycount', 'exit_litteral' => 'critical' }, 
                       { label => 'warn_proxycount', 'exit_litteral' => 'warning' } ]);
    $self->{output}->output_add(
        severity  => $exit,
        short_msg => sprintf("ProxyCount: %d", $proxycount)
    );
    $exit = $self->{perfdata}->threshold_check(value => $clientsessioncount, 
        threshold => [ { label => 'crit_clientsessioncount', 'exit_litteral' => 'critical' }, 
                       { label => 'warn_clientsessioncount', 'exit_litteral' => 'warning' } ]);
    $self->{output}->output_add(
        severity  => $exit,
        short_msg => sprintf("ClientSessionCount: %d", $clientsessioncount)
    );
    $exit = $self->{perfdata}->threshold_check(value => $serversessioncount, 
        threshold => [ { label => 'crit_serversessioncount', 'exit_litteral' => 'critical' }, 
                       { label => 'warn_serversessioncount', 'exit_litteral' => 'warning' } ]);
    $self->{output}->output_add(
        severity  => $exit,
        short_msg => sprintf("ServerSessionCount: %d", $serversessioncount)
    );    
    $exit = $self->{perfdata}->threshold_check(value => $invokecountpermin, 
        threshold => [ { label => 'crit_invokecountpermin', 'exit_litteral' => 'critical' }, 
                       { label => 'warn_invokecountpermin', 'exit_litteral' => 'warning' } ]);
    $self->{output}->output_add(
        severity  => $exit,
        short_msg => sprintf("InvokeCountPerMinute: %d", $invokecountpermin)
    );    
    $exit = $self->{perfdata}->threshold_check(value => $servicecountpermin, 
        threshold => [ { label => 'crit_servicecountpermin', 'exit_litteral' => 'critical' }, 
                       { label => 'warn_servicecountpermin', 'exit_litteral' => 'warning' } ]);
    $self->{output}->output_add(
        severity  => $exit,
        short_msg => sprintf("ServiceCountPerMinute: %d", $servicecountpermin)
    );    

    $self->{output}->perfdata_add(
        label => "ActiveTrheadCount",
        value => $activethreadcount,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn_activethreadcount'),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit_activethreadcount'),
    );
    $self->{output}->perfdata_add(
        label => "StubCount",
        value => $stubcount,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn_stubcount'),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit_stubcount'),
    );
    $self->{output}->perfdata_add(
        label => "ProxyCount",
        value => $proxycount,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn_proxycount'),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit_proxycount'),
    );
    $self->{output}->perfdata_add(
        label => "ClientSessionCount",
        value => $clientsessioncount,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn_clientsessioncount'),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit_clientsessioncount'),
    );
    $self->{output}->perfdata_add(
        label => "ServerSessionCount",
        value => $serversessioncount,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn_serversessioncount'),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit_serversessioncount'),
    );    
    $self->{output}->perfdata_add(
        label => "InvokeCount /min",
        value => $invokecountpermin,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn_invokecountpermin'),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit_invokecountpermin'),
    );    
    $self->{output}->perfdata_add(
        label => "ServiceCount /min",
        value => $servicecountpermin,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn_servicecountpermin'),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit_servicecountpermin'),
    );    
    $self->{output}->perfdata_add(
        label => "c[InvokeCount]",
        value => $invokecount,
     );    
    $self->{output}->perfdata_add(
        label => "c[ServiceCount]",
        value => $servicecount,
     );    
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check EAS instance orm rpc status.

=over 8

=item B<--urlpath>

Set path to get status page. (Default: '/easportal/tools/nagios/checkrpc.jsp')

=item B<--warning>

Warning Threshold (activethreadcount,stubcount,proxycount,clientsessioncount,serversessioncount,invokecountpermin,servicecountpermin).

=item B<--critical>

Critical Threshold (activethreadcount,stubcount,proxycount,clientsessioncount,serversessioncount,invokecountpermin,servicecountpermin).

=back

=cut
