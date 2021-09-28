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

package centreon::common::cisco::standard::snmp::mode::ipsectunnel;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use Socket;

sub custom_traffic_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        label => 'traffic_' . lc($self->{result_values}->{label}), unit => 'b/s',
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
        value => sprintf("%.2f", $self->{result_values}->{traffic_per_seconds}),
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub custom_traffic_threshold {
    my ($self, %options) = @_;

    return $self->{perfdata}->threshold_check(value => $self->{result_values}->{traffic_per_seconds}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
}

sub custom_traffic_output {
    my ($self, %options) = @_;

    my ($traffic_value, $traffic_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{traffic_per_seconds}, network => 1);    
    return sprintf(
        'traffic %s: %s/s',
        lc($self->{result_values}->{label}),
        $traffic_value . $traffic_unit
    );
}

sub custom_traffic_calc {
    my ($self, %options) = @_;

    if (!defined($options{old_datas}->{$self->{instance} . '_display'})) {
        $self->{error_msg} = "Buffer creation";
        return -1;
    }

    my $total_bytes = 0;
    foreach (keys %{$options{new_datas}}) {
        if (/$self->{instance}_cipSecTunHc$options{extra_options}->{label_ref}Octets_(\d+)/) {
            my $new_bytes = $options{new_datas}->{$_};
            next if (!defined($options{old_datas}->{$_}));
            my $old_bytes = $options{old_datas}->{$_};

            my $diff_bytes = $new_bytes - $old_bytes;
            $total_bytes += (($diff_bytes < 0) ? $new_bytes : $diff_bytes);
        } elsif (/$self->{instance}_cipSecTun$options{extra_options}->{label_ref}Octets_(\d+)/) {
            my $new_bytes = $options{new_datas}->{$_};
            my $new_wraps = $options{new_datas}->{$self->{instance} . '_cipSecTun' . $options{extra_options}->{label_ref} . 'OctWraps_' . $1};
            next if (!defined($options{old_datas}->{$_}));
            my ($old_bytes, $old_wraps) = ($options{old_datas}->{$_}, $options{old_datas}->{$self->{instance} . '_cipSecTun' . $options{extra_options}->{label_ref} . 'OctWraps_' . $1});

            my $diff_bytes = $new_bytes - $old_bytes + (($new_wraps - $old_wraps) * (2**32));
            $total_bytes += (($diff_bytes < 0) ? $new_bytes : $diff_bytes);
        }
    }

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{traffic_per_seconds} = ($total_bytes * 8) / $options{delta_time};    
    $self->{result_values}->{label} = $options{extra_options}->{label_ref};

    return 0;
}

sub custom_drop_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        label => 'drop_' . lc($self->{result_values}->{label}), unit => 'pkts/s',
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
        value => sprintf("%.2f", $self->{result_values}->{pkts_per_seconds}),
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub custom_drop_threshold {
    my ($self, %options) = @_;

    return $self->{perfdata}->threshold_check(value => $self->{result_values}->{pkts_per_seconds}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
}

sub custom_drop_output {
    my ($self, %options) = @_;
    
    return sprintf(
        'drop %s: %s pkts/s',
        lc($self->{result_values}->{label}), $self->{result_values}->{pkts_per_seconds}
    );
}

sub custom_drop_calc {
    my ($self, %options) = @_;

    if (!defined($options{old_datas}->{$self->{instance} . '_display'})) {
        $self->{error_msg} = "Buffer creation";
        return -1;
    }

    my $total_pkts = 0;
    foreach (keys %{$options{new_datas}}) {
        if (/$self->{instance}_cipSecTun$options{extra_options}->{label_ref}DropPkts_(\d+)/) {
            next if (!defined($options{old_datas}->{$_}));

            my $diff_pkts = $options{new_datas}->{$_} - $options{old_datas}->{$_};
            $total_pkts += (($diff_pkts < 0) ? $options{new_datas}->{$_} : $diff_pkts);
        }
    }

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{pkts_per_seconds} = $total_pkts / $options{delta_time};    
    $self->{result_values}->{label} = $options{extra_options}->{label_ref};

    return 0;
}

sub prefix_tunnel_output {
    my ($self, %options) = @_;

    return "Tunnel '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'tunnel', type => 1, cb_prefix_output => 'prefix_tunnel_output', message_multiple => 'All tunnels are ok' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'tunnels-total', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'Total tunnels: %s',
                perfdatas => [
                    { label => 'total_tunnels', template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{tunnel} = [
        { label => 'traffic-in', set => {
                key_values => [],
                manual_keys => 1,
                closure_custom_calc => $self->can('custom_traffic_calc'), closure_custom_calc_extra_options => { label_ref => 'In' },
                closure_custom_output => $self->can('custom_traffic_output'),
                closure_custom_perfdata => $self->can('custom_traffic_perfdata'),
                closure_custom_threshold_check => $self->can('custom_traffic_threshold')
            }
        },
        { label => 'traffic-out', set => {
                key_values => [],
                manual_keys => 1,
                closure_custom_calc => $self->can('custom_traffic_calc'), closure_custom_calc_extra_options => { label_ref => 'Out' },
                closure_custom_output => $self->can('custom_traffic_output'),
                closure_custom_perfdata => $self->can('custom_traffic_perfdata'),
                closure_custom_threshold_check => $self->can('custom_traffic_threshold')
            }
        },
        { label => 'drop-in', set => {
                key_values => [],
                manual_keys => 1,
                closure_custom_calc => $self->can('custom_drop_calc'), closure_custom_calc_extra_options => { label_ref => 'In' },
                closure_custom_output => $self->can('custom_drop_output'),
                closure_custom_perfdata => $self->can('custom_drop_perfdata'),
                closure_custom_threshold_check => $self->can('custom_drop_threshold')
            }
        },
        { label => 'drop-out', set => {
                key_values => [],
                manual_keys => 1,
                closure_custom_calc => $self->can('custom_drop_calc'), closure_custom_calc_extra_options => { label_ref => 'Out' },
                closure_custom_output => $self->can('custom_drop_output'),
                closure_custom_perfdata => $self->can('custom_drop_perfdata'),
                closure_custom_threshold_check => $self->can('custom_drop_threshold')
            }
        },
        { label => 'sa-total', set => {
                key_values => [ { name => 'sa' }, { name => 'display' } ],
                output_template => 'total sa: %s',
                perfdatas => [
                    { label => 'total_sa', template => '%s', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-name:s' => { name => 'filter_name' },
        'filter-sa:s'   => { name => 'filter_sa' }
    });

    return $self;
}

my $mapping = {
    cikeTunLocalValue       => { oid => '.1.3.6.1.4.1.9.9.171.1.2.3.1.3' },
    cikeTunRemoteValue      => { oid => '.1.3.6.1.4.1.9.9.171.1.2.3.1.7' },
    cikeTunActiveTime       => { oid => '.1.3.6.1.4.1.9.9.171.1.2.3.1.16' },
};
my $mapping2 = {
    cipSecTunInOctets       => { oid => '.1.3.6.1.4.1.9.9.171.1.3.2.1.26' },
    cipSecTunHcInOctets     => { oid => '.1.3.6.1.4.1.9.9.171.1.3.2.1.27' },
    cipSecTunInOctWraps     => { oid => '.1.3.6.1.4.1.9.9.171.1.3.2.1.28' }, # seems buggy
    cipSecTunInDropPkts     => { oid => '.1.3.6.1.4.1.9.9.171.1.3.2.1.33' },
    cipSecTunOutOctets      => { oid => '.1.3.6.1.4.1.9.9.171.1.3.2.1.39' },
    cipSecTunHcOutOctets    => { oid => '.1.3.6.1.4.1.9.9.171.1.3.2.1.40' }, # seems buggy
    cipSecTunOutOctWraps    => { oid => '.1.3.6.1.4.1.9.9.171.1.3.2.1.41' },
    cipSecTunOutDropPkts    => { oid => '.1.3.6.1.4.1.9.9.171.1.3.2.1.46' }
};
my $mapping3 = {
    cipSecEndPtLocalAddr1   => { oid => '.1.3.6.1.4.1.9.9.171.1.3.3.1.4' },
    cipSecEndPtLocalAddr2   => { oid => '.1.3.6.1.4.1.9.9.171.1.3.3.1.5' },
    cipSecEndPtRemoteAddr1  => { oid => '.1.3.6.1.4.1.9.9.171.1.3.3.1.10' },
    cipSecEndPtRemoteAddr2  => { oid => '.1.3.6.1.4.1.9.9.171.1.3.3.1.11' }
};

my $oid_cikeTunnelEntry = '.1.3.6.1.4.1.9.9.171.1.2.3.1';
my $oid_cipSecTunnelEntry = '.1.3.6.1.4.1.9.9.171.1.3.2.1';
my $oid_cipSecEndPtEntry = '.1.3.6.1.4.1.9.9.171.1.3.3.1';
my $oid_cipSecTunIkeTunnelIndex = '.1.3.6.1.4.1.9.9.171.1.3.2.1.2';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{tunnel} = {};    
    my $request_oids = [
        { oid => $oid_cikeTunnelEntry, start => $mapping->{cikeTunLocalValue}->{oid}, end => $mapping->{cikeTunActiveTime}->{oid} },
        { oid => $oid_cipSecTunnelEntry, start => $mapping2->{cipSecTunInOctets}->{oid}, end => $mapping2->{cipSecTunOutDropPkts}->{oid} },
        { oid => $oid_cipSecEndPtEntry, start => $mapping3->{cipSecEndPtLocalAddr1}->{oid}, end => $mapping3->{cipSecEndPtRemoteAddr2}->{oid} },
        { oid => $oid_cipSecTunIkeTunnelIndex }
    ];
    my $results = $options{snmp}->get_multiple_table(oids => $request_oids);

    # The MIB doesn't give IPSec tunnel type (site-to-site or dynamic client)
    # You surely need to filter on SA. Dynamic client usually doesn't push local routes.
    foreach (keys %{$results->{$oid_cikeTunnelEntry}}) {
        next if (!/$mapping->{cikeTunRemoteValue}->{oid}\.(\d+)/);
        
        my $cike_tun_index = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $results->{$oid_cikeTunnelEntry}, instance => $cike_tun_index);
        
        my $name = $result->{cikeTunLocalValue} . '_' . $result->{cikeTunRemoteValue};
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $name . "': no matching filter name.", debug => 1);
            next;
        }

        foreach my $key (keys %{$results->{$oid_cipSecTunIkeTunnelIndex}}) {
            next if ($results->{$oid_cipSecTunIkeTunnelIndex}->{$key} != $cike_tun_index);
            $key =~ /^$oid_cipSecTunIkeTunnelIndex\.(\d+)/;
            my $cip_tun_index = $1;

            my $result2 = $options{snmp}->map_instance(mapping => $mapping2, results => $results->{$oid_cipSecTunnelEntry}, instance => $cip_tun_index);
            my $sa_name = '';
            foreach my $key2 (keys %{$results->{$oid_cipSecEndPtEntry}}) {
                if ($key2 =~ /^$mapping3->{cipSecEndPtLocalAddr1}->{oid}\.$cip_tun_index\.(\d+)/) {
                    my $result3 = $options{snmp}->map_instance(mapping => $mapping3, results => $results->{$oid_cipSecEndPtEntry}, instance => $cip_tun_index . '.' . $1);
                    $sa_name = inet_ntoa($result3->{cipSecEndPtLocalAddr1}) . ':' . inet_ntoa($result3->{cipSecEndPtLocalAddr2}) . '_' . inet_ntoa($result3->{cipSecEndPtRemoteAddr1}) . ':' . inet_ntoa($result3->{cipSecEndPtRemoteAddr2});
                    last;
                }
            }

            if (defined($self->{option_results}->{filter_sa}) && $self->{option_results}->{filter_sa} ne '' &&
                $sa_name !~ /$self->{option_results}->{filter_sa}/) {
                $self->{output}->output_add(long_msg => "skipping  '" . $sa_name . "': no matching filter sa.", debug => 1);
                next;
            }

            $self->{tunnel}->{$name} = { display => $name, sa => 0 } 
                if (!defined($self->{tunnel}->{$name}));
            if (defined($result2->{cipSecTunHcInOctets}) && defined($result2->{cipSecTunHcOutOctets})) {
                delete $result2->{cipSecTunInOctets};
                delete $result2->{cipSecTunInOctWraps};
                delete $result2->{cipSecTunOutOctets};
                delete $result2->{cipSecTunOutOctWraps};
            }
            foreach my $oid_name (keys %{$mapping2}) {
                $self->{tunnel}->{$name}->{$oid_name . '_' . $cip_tun_index} = $result2->{$oid_name} if (defined($result2->{$oid_name}));
            }
            $self->{tunnel}->{$name}->{cikeTunActiveTime} = $result->{cikeTunActiveTime};
            $self->{tunnel}->{$name}->{sa}++;
        }
    }

    $self->{cache_name} = 'cisco_ipsectunnel_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_sa}) ? md5_hex($self->{option_results}->{filter_sa}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));

    $self->{global} = { total => scalar(keys %{$self->{tunnel}}) };
}

1;

__END__

=head1 MODE

Check IPsec tunnels.

=over 8

=item B<--filter-name>

Filter name (can be a regexp).
Example (format localaddr_remoteaddr): 

=item B<--filter-sa>

Filter IPSec Security Associations (can be a regexp).
Example (format localaddr:localmask_remoteaddr:remotemask): 

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^(tunnels-total)$'

=item B<--warning-*>

Threshold warning.
Can be: 'tunnels-total', 'traffic-in', 
'traffic-out', 'drop-in', 'drop-out', 'sa-total'.

=item B<--critical-*>

Threshold critical.
Can be: 'tunnels-total', 'traffic-in', 
'traffic-out', 'drop-in', 'drop-out', 'sa-total'.

=back

=cut
