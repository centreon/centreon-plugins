#
# Copyright 2025-Present Centreon (http://www.centreon.com/)
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

package centreon::plugins::snmplogger;

use strict;
use warnings;

# Generate an snmpwalk/snmpget command

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    $self->start($options{cmd} || 'snmpwalk');

    $self->parse_params($options{params});

    $self
}

sub start {
    my ($self, $command) = @_;

    $self->{command} = $command;
    $self->{command_parameters} = [ ];
}

# Conversion of SNMP v3 parameters
our %_snmp_v3_convert = ( "Context" => "-n",
                          "ContextEngineId" => "-E",
                          "SecEngineId" => "-e",
                          "SecName" => "-u",
                          "OurIdentity" => "-T localCert=",
                          "TheirIdentity" => "-T peerCert=",
                          "TheirHostname" => "-T their_hostname=",
                          "TrustCert" => "-T trust_cert=",
                          "SecLevel" => "-l",
                          "AuthProto" => "-a",
                          "AuthPass" => "-A",
                          "PrivPass" => "-X",
                          "PrivProto" => "-x",
                     );

sub parse_params {
    my ($self, $params) = @_;

    $self->{global_parameters} = [];
    push @{$self->{global_parameters}}, "-v".$params->{Version} =~ s/^2.*/2c/r;
    push @{$self->{global_parameters}}, "-c".$params->{Community}
        unless $params->{Version} =~ /3/;
    push @{$self->{global_parameters}}, "-r".$params->{Retries};
    push @{$self->{global_parameters}}, "-t".$params->{Timeout} / 1_000_000;
    push @{$self->{global_parameters}}, $params->{DestHost}.
                ($params->{RemotePort} ne '161' ? ":$params->{RemotePort}" : '');

    if ($params->{Version} =~ /3/) {
        while (my ($key, $value) = each %_snmp_v3_convert) {
            next unless $params->{$key};

            push @{$self->{global_parameters}}, $value.($key !~ /Pass/ ? $params->{$key} : 'XXX');
        }
    }
}

sub add {
    my ($self, $param) = @_;

    push @{$self->{command_parameters}}, $param;
}

sub get_log {
    my ($self) = @_;

    return $self->{command}.' '.join ' ', @{$self->{global_parameters}}, @{$self->{command_parameters}};
}

1;

__END__
