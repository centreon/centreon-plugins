#
# Copyright 2015 Centreon (http://www.centreon.com/)
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

package network::citrix::netscaler::common::mode::connections;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "warning-server:s"     => { name => 'warning_server' },
                                  "critical-server:s"    => { name => 'critical_server' },
                                  "warning-active:s"     => { name => 'warning_active' },
                                  "critical-active:s"    => { name => 'critical_active' },
                                  "warning-client:s"     => { name => 'warning_client' },
                                  "critical-client:s"    => { name => 'critical_client' },
                                });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    if (($self->{perfdata}->threshold_validate(label => 'warning-server', value => $self->{option_results}->{warning_server})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning-server threshold '" . $self->{option_results}->{warning_server} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-server', value => $self->{option_results}->{critical_server})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical-server threshold '" . $self->{option_results}->{critical_server} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warning-active', value => $self->{option_results}->{warning_active})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning-active threshold '" . $self->{option_results}->{warning_active} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-active', value => $self->{option_results}->{critical_active})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical-active threshold '" . $self->{option_results}->{critical_active} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warning-client', value => $self->{option_results}->{warning_client})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning-client threshold '" . $self->{option_results}->{warning_client} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-client', value => $self->{option_results}->{critical_client})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical-client threshold '" . $self->{option_results}->{critical_client} . "'.");
       $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    my $oid_tcpCurServerConn = '.1.3.6.1.4.1.5951.4.1.1.46.1.0';
    my $oid_tcpCurClientConn = '.1.3.6.1.4.1.5951.4.1.1.46.2.0'; 
    my $oid_tcpActiveServerConn = '.1.3.6.1.4.1.5951.4.1.1.46.8.0';
    my $result = $self->{snmp}->get_leef(oids => [$oid_tcpCurServerConn, $oid_tcpCurClientConn, $oid_tcpActiveServerConn ], nothing_quit => 1);
    
    my $exit_server = $self->{perfdata}->threshold_check(value => $result->{$oid_tcpCurServerConn},
                                                  threshold => [ { label => 'critical-server', exit_litteral => 'critical' }, { label => 'warning-server', exit_litteral => 'warning' } ]);
    my $exit_client = $self->{perfdata}->threshold_check(value => $result->{$oid_tcpCurClientConn},
                                                  threshold => [ { label => 'critical-client', exit_litteral => 'critical' }, { label => 'warning-client', exit_litteral => 'warning' } ]);
    my $exit_active = $self->{perfdata}->threshold_check(value => $result->{$oid_tcpActiveServerConn},
                                                  threshold => [ { label => 'critical-active', exit_litteral => 'critical' }, { label => 'warning-active', exit_litteral => 'warning' } ]);
    my $exit = $self->{output}->get_most_critical(status => [$exit_server, $exit_client, $exit_active]);

    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("Connections: Client=%s Server=%s (activeServer=%s)",
                                                     $result->{$oid_tcpCurClientConn}, $result->{$oid_tcpCurServerConn}, $result->{$oid_tcpActiveServerConn}));

    $self->{output}->perfdata_add(label => "client", unit => 'con',
                                  value => $result->{$oid_tcpCurClientConn},
                                  warning => $self->{option_results}->{warning_client},
                                  critical => $self->{option_results}->{critical_client},
                                  min => 0);
    $self->{output}->perfdata_add(label => "server", unit => 'con',
                                  value => $result->{$oid_tcpCurServerConn},
                                  warning => $self->{option_results}->{warning_server},
                                  critical => $self->{option_results}->{critical_server},
                                  min => 0);
    $self->{output}->perfdata_add(label => "activeServer", unit => 'con',
                                  value => $result->{$oid_tcpActiveServerConn},
                                  warning => $self->{option_results}->{warning_active},
                                  critical => $self->{option_results}->{critical_active},
                                  min => 0);
    $self->{output}->display();
    $self->{output}->exit();
}
    
1;

__END__

=head1 MODE

Check connections usage (Client, Server, ActiveServer) (NS-ROOT-MIBv2).

=over 8

=item B<--warning-server>

Warning on number of server TCP connections 

=item B<--critical-server>

Critical on number of server TCP connections

=item B<--warning-client>

Warning on number of client TCP connections

=item B<--critical-client>

Critical on number of client TCP connections

=item B<--warning-active>

Warning on number of server Active TCP connections

=item B<--critical-active>

Critical on number of server Active TCP connections

=back

=cut
