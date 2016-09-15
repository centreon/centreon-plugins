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

package network::citrix::netscaler::common::mode::connections;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::values;

my $maps_counters = {
    global => {
        '000_active'   => { set => {
                key_values => [ { name => 'active' } ],
                output_template => 'Active Server TCP connections : %s',
                perfdatas => [
                    { label => 'active_server', value => 'active_absolute', template => '%s', 
                      unit => 'con', min => 0 },
                ],
            }
        },
        '001_server'   => { set => {
                key_values => [ { name => 'server' } ],
                output_template => 'Server TCP connections  : %s',
                perfdatas => [
                    { label => 'server', value => 'server_absolute', template => '%s', 
                      unit => 'con', min => 0 },
                ],
            }
        },
        '002_client'  => { set => {
                key_values => [ { name => 'client' } ],
                output_template => 'Client TCP connections : %s',
                perfdatas => [
                    { label => 'client', value => 'client_absolute', template => '%s', 
                      unit => 'con', min => 0 },
                ],
            }
        },
    },
};

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                });

    foreach my $key (('global')) {
        foreach (keys %{$maps_counters->{$key}}) {
            my ($id, $name) = split /_/;
            if (!defined($maps_counters->{$key}->{$_}->{threshold}) || $maps_counters->{$key}->{$_}->{threshold} != 0) {
                $options{options}->add_options(arguments => {
                                                    'warning-' . $name . ':s'    => { name => 'warning-' . $name },
                                                    'critical-' . $name . ':s'    => { name => 'critical-' . $name },
                                               });
            }
            $maps_counters->{$key}->{$_}->{obj} = centreon::plugins::values->new(output => $self->{output},
                                                      perfdata => $self->{perfdata},
                                                      label => $name);
            $maps_counters->{$key}->{$_}->{obj}->set(%{$maps_counters->{$key}->{$_}->{set}});
        }
    }
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    foreach my $key (('global')) {
        foreach (keys %{$maps_counters->{$key}}) {
            $maps_counters->{$key}->{$_}->{obj}->init(option_results => $self->{option_results});
        }
    }
}

sub run_global {
    my ($self, %options) = @_;

    my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
    my @exits;
    foreach (sort keys %{$maps_counters->{global}}) {
        my $obj = $maps_counters->{global}->{$_}->{obj};
                
        $obj->set(instance => 'global');
    
        my ($value_check) = $obj->execute(values => $self->{global});

        if ($value_check != 0) {
            $long_msg .= $long_msg_append . $obj->output_error();
            $long_msg_append = ', ';
            next;
        }
        my $exit2 = $obj->threshold_check();
        push @exits, $exit2;

        my $output = $obj->output();
        $long_msg .= $long_msg_append . $output;
        $long_msg_append = ', ';
        
        if (!$self->{output}->is_status(litteral => 1, value => $exit2, compare => 'ok')) {
            $short_msg .= $short_msg_append . $output;
            $short_msg_append = ', ';
        }
        
        $obj->perfdata();
    }

    my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
    if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => "$short_msg"
                                    );
    } else {
        $self->{output}->output_add(short_msg => "$long_msg");
    }
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};
    
    $self->manage_selection();
    $self->run_global();
     
    $self->{output}->display();
    $self->{output}->exit();
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = { client => 0, server => 0, active => 0 }; 
    my $oid_tcpCurServerConn = '.1.3.6.1.4.1.5951.4.1.1.46.1.0';
    my $oid_tcpCurClientConn = '.1.3.6.1.4.1.5951.4.1.1.46.2.0'; 
    my $oid_tcpActiveServerConn = '.1.3.6.1.4.1.5951.4.1.1.46.8.0';
    my $result = $self->{snmp}->get_leef(oids => [$oid_tcpCurServerConn, $oid_tcpCurClientConn, $oid_tcpActiveServerConn ], nothing_quit => 1);
    $self->{global}->{client} = $result->{$oid_tcpCurClientConn};
    $self->{global}->{server} = $result->{$oid_tcpCurServerConn};
    $self->{global}->{active} = $result->{$oid_tcpActiveServerConn};
}

1;

__END__

=head1 MODE

Check connections usage (Client, Server, ActiveServer) (NS-ROOT-MIBv2).

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'server', 'active', 'client'.

=item B<--critical-*>

Threshold critical.
Can be: 'server', 'active', 'client'.

=back

=cut