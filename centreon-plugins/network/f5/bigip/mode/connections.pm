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

package network::f5::bigip::mode::connections;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my $maps_counters = {
    global => [
        { set => {
                label => 'client',
                key_values => [ { name => 'client' } ],
                output_template => 'Current client connections : %s',
                perfdatas => [
                    { label => 'Client', value => 'client_absolute', template => '%s', 
                      min => 0, unit => 'con' },
                ],
            }
        },
        { set => {
                label => 'client-ssl',
                key_values => [ { name => 'client_ssl' } ],
                output_template => 'Current client SSL connections : %s',
                perfdatas => [
                    { label => 'ClientSSL', value => 'client_absolute', template => '%s', 
                      min => 0, unit => 'con' },
                ],
            }
        },
        { set => {
                label => 'server',
                key_values => [ { name => 'server' } ],
                output_template => 'Current server connections: %s',
                perfdatas => [
                    { label => 'Server', value => 'server_absolute', template => '%s', 
                      min => 0, unit => 'con' },
                ],
            }
        },
        { set => {
                label => 'server-ssl',
                key_values => [ { name => 'server_ssl' } ],
                output_template => 'Current server SSL connections : %s',
                perfdatas => [
                    { label => 'ServerSSL', value => 'server_ssl_absolute', template => '%s', 
                      min => 0, unit => 'con' },
                ],
            }
        },
    ]
};

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                "filter:s"           => { name => 'filter' },
                                });

    foreach my $key (('global')) {
        foreach (@{$maps_counters->{$key}}) {
            if (!defined($_->{threshold}) || $_->{threshold} != 0) {
                $options{options}->add_options(arguments => {
                                                            'warning-' . $_->{label} . ':s'    => { name => 'warning-' . $_->{label} },
                                                            'critical-' . $_->{label} . ':s'    => { name => 'critical-' . $_->{label} },
                                               });
            }
            $_->{obj} = centreon::plugins::values->new(output => $self->{output}, perfdata => $self->{perfdata},
                                                       label => $_->{label});
            $_->{obj}->set(%{$_->{set}});
        }
    }
                                
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
     foreach my $key (('global')) {
        foreach (@{$maps_counters->{$key}}) {
            $_->{obj}->init(option_results => $self->{option_results});
        }
    }
}

sub run_global {
    my ($self, %options) = @_;
    
    my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
    my @exits;
    foreach (@{$maps_counters->{global}}) {
        my $obj = $_->{obj};

        next if (defined($self->{option_results}->{filter}) && $self->{option_results}->{filter} ne '' &&
            $_->{name} !~ /$self->{option_results}->{filter}/);
        
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

    my $oid_sysStatClientCurConns = '.1.3.6.1.4.1.3375.2.1.1.2.1.8.0';
    my $oid_sysStatServerCurConns = '.1.3.6.1.4.1.3375.2.1.1.2.1.15.0';
    my $oid_sysClientsslStatCurConns = '.1.3.6.1.4.1.3375.2.1.1.2.9.2.0';
    my $oid_sysServersslStatCurConns = '.1.3.6.1.4.1.3375.2.1.1.2.10.2.0';
    
    if ($self->{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Need to use SNMP v2c or v3.");
        $self->{output}->option_exit();
    }
    
    $self->{global} = { };
    my $result = $self->{snmp}->get_leef(oids => [$oid_sysStatClientCurConns, $oid_sysStatServerCurConns, 
                                                  $oid_sysClientsslStatCurConns, $oid_sysServersslStatCurConns],
                                         nothing_quit => 1);
    $self->{global} = { 
        client => $result->{$oid_sysStatClientCurConns},
        client_ssl => $result->{$oid_sysClientsslStatCurConns},
        server => $result->{$oid_sysStatServerCurConns},
        server_ssl => $result->{$oid_sysServersslStatCurConns},
    };
}
    
1;

__END__

=head1 MODE

Check current connections on F5 BIG IP device.

=over 8

=item B<--filter>

Filter (can be a regexp) to filter output.
Example to check SSL connections only : --filter='^client-ssl|server-ssl$'

=item B<--warning-*>

Threshold warning.
Can be: 'client', 'server', 'client-ssl', 'server-ssl'.

=item B<--critical-*>

Threshold critical.
Can be: 'client', 'server', 'client-ssl', 'server-ssl'.

=back

=cut
    
