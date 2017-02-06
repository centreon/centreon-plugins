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

package network::cyberoam::snmp::mode::components::service;

use strict;
use warnings;

my %map_status = (
    1 => 'untouched', 2 => 'stopped', 3 => 'initializing', 4 => 'running', 5 => 'exiting',
    6 => 'dead', 7 => 'unregistered',
);

my $mapping = {
    pop3Service         => { oid => '.1.3.6.1.4.1.21067.2.1.2.10.1', map => \%map_status, type => 'pop3' },
    imap4Service        => { oid => '.1.3.6.1.4.1.21067.2.1.2.10.2', map => \%map_status, type => 'imap4' },
    smtpService         => { oid => '.1.3.6.1.4.1.21067.2.1.2.10.3', map => \%map_status, type => 'smtp' },
    ftpService          => { oid => '.1.3.6.1.4.1.21067.2.1.2.10.4', map => \%map_status, type => 'ftp' },
    httpService         => { oid => '.1.3.6.1.4.1.21067.2.1.2.10.5', map => \%map_status, type => 'http' },
    avService           => { oid => '.1.3.6.1.4.1.21067.2.1.2.10.6', map => \%map_status, type => 'av' },
    asService           => { oid => '.1.3.6.1.4.1.21067.2.1.2.10.7', map => \%map_status, type => 'as' },
    dnsService          => { oid => '.1.3.6.1.4.1.21067.2.1.2.10.8', map => \%map_status, type => 'dns' },
    haService           => { oid => '.1.3.6.1.4.1.21067.2.1.2.10.9', map => \%map_status, type => 'ha' },
    idpService          => { oid => '.1.3.6.1.4.1.21067.2.1.2.10.10', map => \%map_status, type => 'idp' },
    apacheService       => { oid => '.1.3.6.1.4.1.21067.2.1.2.10.11', map => \%map_status, type => 'apache' },
    ntpService          => { oid => '.1.3.6.1.4.1.21067.2.1.2.10.12', map => \%map_status, type => 'ntp' },
    tomcatService       => { oid => '.1.3.6.1.4.1.21067.2.1.2.10.13', map => \%map_status, type => 'tomcat' },
    sslvpnService       => { oid => '.1.3.6.1.4.1.21067.2.1.2.10.14', map => \%map_status, type => 'sslvpn' },
    DataBaseService     => { oid => '.1.3.6.1.4.1.21067.2.1.2.10.15', map => \%map_status, type => 'database' },
    networkService      => { oid => '.1.3.6.1.4.1.21067.2.1.2.10.16', map => \%map_status, type => 'network' },
    garnerService       => { oid => '.1.3.6.1.4.1.21067.2.1.2.10.17', map => \%map_status, type => 'garner' },
    droutingService     => { oid => '.1.3.6.1.4.1.21067.2.1.2.10.18', map => \%map_status, type => 'drouting' },
    sshdService         => { oid => '.1.3.6.1.4.1.21067.2.1.2.10.19', map => \%map_status, type => 'sshd' },
    dgdService          => { oid => '.1.3.6.1.4.1.21067.2.1.2.10.20', map => \%map_status, type => 'dgd' },
};
my $oid_serviceStats = '.1.3.6.1.4.1.21067.2.1.2.10';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_serviceStats };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "checking services");
    $self->{components}->{service} = {name => 'services', total => 0, skip => 0};
    return if ($self->check_filter(section => 'service'));

    my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_serviceStats}, instance => '0');

    foreach (keys %{$mapping}) {
        next if ($self->check_filter(section => 'service', instance => $mapping->{$_}->{type}));
        
        $self->{components}->{service}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("service '%s' status is '%s' [instance: %s].",
                                    $mapping->{$_}->{type}, $result->{$_},
                                    $mapping->{$_}->{type}
                                    ));
        my $exit = $self->get_severity(label => 'default', section => 'service', instance => $mapping->{$_}->{type}, value => $result->{$_});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("service '%s' status is '%s'",
                                                             $mapping->{$_}->{type}, $result->{$_}));
        }
    }
}

1;