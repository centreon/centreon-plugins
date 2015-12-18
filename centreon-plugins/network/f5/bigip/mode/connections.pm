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
use centreon::plugins::values;
use centreon::plugins::statefile;
use Digest::MD5 qw(md5_hex);

my $maps_counters = {
    global => [
        { label => 'client', set => {
                key_values => [ { name => 'client' } ],
                output_template => 'Current client connections : %s',
                perfdatas => [
                    { label => 'Client', value => 'client_absolute', template => '%s', 
                      min => 0, unit => 'con' },
                ],
            }
        },
        { label => 'client-ssl', set => {
                key_values => [ { name => 'client_ssl' } ],
                output_template => 'Current client SSL connections : %s',
                perfdatas => [
                    { label => 'ClientSSL', value => 'client_ssl_absolute', template => '%s', 
                      min => 0, unit => 'con' },
                ],
            }
        },
        { label => 'client-ssl-tps', set => {        
                key_values => [ { name => 'client_ssl_tot_native', diff => 1 }, { name => 'client_ssl_tot_compat', diff => 1 } ],
                output_template => 'TPS client SSL connections : %.2f', threshold_use => 'client_ssl_tps', output_use => 'client_ssl_tps',
                closure_custom_calc => \&custom_client_tps_calc,
                per_second => 1,
                perfdatas => [
                    { label => 'ClientSSL_Tps', value => 'client_ssl_tps', template => '%.2f',
                      unit => 'tps', min => 0 },
                ],
            }
        },
        { label => 'server', set => { 
                key_values => [ { name => 'server' } ],
                output_template => 'Current server connections: %s',
                perfdatas => [
                    { label => 'Server', value => 'server_absolute', template => '%s', 
                      min => 0, unit => 'con' },
                ],
            }
        },
        { label => 'server-ssl', set => {
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

sub custom_client_tps_calc {
    my ($self, %options) = @_;

    my $diff_native = $options{new_datas}->{$self->{instance} . '_client_ssl_tot_native'} - $options{old_datas}->{$self->{instance} . '_client_ssl_tot_native'};
    my $diff_compat = $options{new_datas}->{$self->{instance} . '_client_ssl_tot_compat'} - $options{old_datas}->{$self->{instance} . '_client_ssl_tot_compat'};
    $self->{result_values}->{client_ssl_tps} = ($diff_native + $diff_compat) / $options{delta_time};
    
    return 0;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                "filter-counters:s" => { name => 'filter_counters' },
                                });
    $self->{statefile_value} = centreon::plugins::statefile->new(%options);

    foreach my $key (('global')) {
        foreach (@{$maps_counters->{$key}}) {
            if (!defined($_->{threshold}) || $_->{threshold} != 0) {
                $options{options}->add_options(arguments => {
                                                            'warning-' . $_->{label} . ':s'    => { name => 'warning-' . $_->{label} },
                                                            'critical-' . $_->{label} . ':s'    => { name => 'critical-' . $_->{label} },
                                               });
            }
            $_->{obj} = centreon::plugins::values->new(statefile => $self->{statefile_value},
                                                       output => $self->{output}, perfdata => $self->{perfdata},
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
    
    $self->{statefile_value}->check_options(%options);
}

sub run_global {
    my ($self, %options) = @_;
    
    my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
    my @exits;
    foreach (@{$maps_counters->{global}}) {
        my $obj = $_->{obj};

        next if (defined($self->{option_results}->{filter_counters}) && $self->{option_results}->{filter_counters} ne '' &&
            $_->{name} !~ /$self->{option_results}->{filter_counters}/);
        
        $obj->set(instance => 'global');
    
        my ($value_check) = $obj->execute(new_datas => $self->{new_datas}, values => $self->{global});

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
    
    $self->manage_selection(%options);
    
    $self->{new_datas} = {};
    $self->{statefile_value}->read(statefile => $self->{cache_name});
    $self->{new_datas}->{last_timestamp} = time();
    
    $self->run_global();

    $self->{statefile_value}->write(data => $self->{new_datas});
    $self->{output}->display();
    $self->{output}->exit();
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cache_name} = "f5_bipgip_" . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' . 
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
    
    my $oid_sysStatClientCurConns = '.1.3.6.1.4.1.3375.2.1.1.2.1.8.0';
    my $oid_sysStatServerCurConns = '.1.3.6.1.4.1.3375.2.1.1.2.1.15.0';
    my $oid_sysClientsslStatCurConns = '.1.3.6.1.4.1.3375.2.1.1.2.9.2.0';
    my $oid_sysServersslStatCurConns = '.1.3.6.1.4.1.3375.2.1.1.2.10.2.0';
    my $oid_sysClientsslStatTotNativeConns = '.1.3.6.1.4.1.3375.2.1.1.2.9.6.0';
    my $oid_sysClientsslStatTotCompatConns = '.1.3.6.1.4.1.3375.2.1.1.2.9.9.0';
    
    if ($options{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Need to use SNMP v2c or v3.");
        $self->{output}->option_exit();
    }
    
    my $result = $options{snmp}->get_leef(oids => [$oid_sysStatClientCurConns, $oid_sysStatServerCurConns, 
                                                   $oid_sysClientsslStatCurConns, $oid_sysServersslStatCurConns,
                                                   $oid_sysClientsslStatTotNativeConns, $oid_sysClientsslStatTotCompatConns],
                                         nothing_quit => 1);
    $self->{global} = { 
        client => $result->{$oid_sysStatClientCurConns},
        client_ssl => $result->{$oid_sysClientsslStatCurConns},
        client_ssl_tot_native => $result->{$oid_sysClientsslStatTotNativeConns},
        client_ssl_tot_compat => $result->{$oid_sysClientsslStatTotCompatConns},
        server => $result->{$oid_sysStatServerCurConns},
        server_ssl => $result->{$oid_sysServersslStatCurConns},
    };
}
    
1;

__END__

=head1 MODE

Check current connections on F5 BIG IP device.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example to check SSL connections only : --filter-counters='^client-ssl|server-ssl$'

=item B<--warning-*>

Threshold warning.
Can be: 'client', 'server', 'client-ssl', 'server-ssl', 'client-ssl-tps'.

=item B<--critical-*>

Threshold critical.
Can be: 'client', 'server', 'client-ssl', 'server-ssl', 'client-ssl-tps'.

=back

=cut