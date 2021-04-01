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

package centreon::common::cisco::standard::snmp::mode::qosusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use bigint;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'total', type => 0 },
        { name => 'interface_classmap', type => 1, cb_prefix_output => 'prefix_intcmap_output', message_multiple => 'All interface classmaps are ok' },
        { name => 'classmap', type => 1, cb_prefix_output => 'prefix_cmap_output', message_multiple => 'All classmaps are ok' }
    ];

    $self->{maps_counters}->{interface_classmap} = [
         { label => 'int-cmap-traffic', set => {
                key_values => [ { name => 'traffic_usage', diff => 1 }, { name => 'total' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_traffic_calc'),
                closure_custom_output => $self->can('custom_traffic_output'),
                closure_custom_perfdata => $self->can('custom_traffic_perfdata'),
                closure_custom_threshold_check => $self->can('custom_traffic_threshold')
            }
        },
        { label => 'int-cmap-drop', set => {
                key_values => [ { name => 'drop_usage', per_second => 1 }, { name => 'display' } ],
                output_change_bytes => 2,
                output_template => 'Drop : %s %s/s',
                perfdatas => [
                    { label => 'icmap_drop', template => '%d',
                      unit => 'b/s', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];
    $self->{maps_counters}->{classmap} = [
         { label => 'cmap-traffic', set => {
                key_values => [ { name => 'traffic_usage', per_second => 1 }, { name => 'display' } ],
                output_change_bytes => 2,
                output_template => 'Traffic : %s %s/s',
                perfdatas => [
                    { label => 'cmap_traffic', template => '%d',
                      unit => 'b/s', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'cmap-drop', set => {
                key_values => [ { name => 'drop_usage', per_second => 1 }, { name => 'display' } ],
                output_change_bytes => 2,
                output_template => 'Drop : %s %s/s',
                perfdatas => [
                    { label => 'cmap_drop', template => '%d',
                      unit => 'b/s', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{total} = [
         { label => 'total-traffic', set => {
                key_values => [ { name => 'traffic_usage', per_second => 1 } ],
                output_change_bytes => 2,
                output_template => 'Total Traffic : %s %s/s',
                perfdatas => [
                    { label => 'total_traffic', template => '%d', unit => 'b/s', min => 0 }
                ]
            }
        },
        { label => 'total-drop', set => {
                key_values => [ { name => 'drop_usage', per_second => 1 } ],
                output_change_bytes => 2,
                output_template => 'Total Drop : %s %s/s',
                perfdatas => [
                    { label => 'total_drop', template => '%d', unit => 'b/s', min => 0 }
                ]
            }
        }
    ];
}

sub custom_traffic_perfdata {
    my ($self, %options) = @_;

    my ($warning, $critical);
    if ($self->{instance_mode}->{option_results}->{units_traffic} eq '%' &&
        (defined($self->{result_values}->{total}) && $self->{result_values}->{total} =~ /[0-9]/)) {
        $warning = $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, total => $self->{result_values}->{total}, cast_int => 1);
        $critical = $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, total => $self->{result_values}->{total}, cast_int => 1);
    } elsif ($self->{instance_mode}->{option_results}->{units_traffic} eq 'b/s') {
        $warning = $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel});
        $critical = $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel});
    }

    $self->{output}->perfdata_add(
        label => 'icmap_traffic', unit => 'b/s',
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
        value => sprintf("%.2f", $self->{result_values}->{traffic_per_seconds}),
        warning => $warning,
        critical => $critical,
        min => 0, max => ($self->{result_values}->{total} =~ /[0-9]/ ? $self->{result_values}->{total} : undef)
    );
}

sub custom_traffic_threshold {
    my ($self, %options) = @_;

    my $exit = 'ok';
    if ($self->{instance_mode}->{option_results}->{units_traffic} eq '%' && 
        (defined($self->{result_values}->{total}) && $self->{result_values}->{total} =~ /[0-9]/)) {
        $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{traffic_prct}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    } elsif ($self->{instance_mode}->{option_results}->{units_traffic} eq 'b/s') {
        $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{traffic_per_seconds}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    }
    return $exit;
}

sub custom_traffic_output {
    my ($self, %options) = @_;
    
    my ($traffic_value, $traffic_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{traffic_per_seconds}, network => 1);    
    return sprintf(
        'Traffic : %s/s (%s)',
        $traffic_value . $traffic_unit,
        defined($self->{result_values}->{traffic_prct}) ? sprintf("%.2f%%", $self->{result_values}->{traffic_prct}) : '-'
    );
}

sub custom_traffic_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};    
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_total'};
    $self->{result_values}->{traffic_usage} = $options{new_datas}->{$self->{instance} . '_traffic_usage'};

    my $diff_traffic = ($options{new_datas}->{$self->{instance} . '_traffic_usage'} - $options{old_datas}->{$self->{instance} . '_traffic_usage'});
    $self->{result_values}->{traffic_per_seconds} = $diff_traffic / $options{delta_time};
    if ($options{new_datas}->{$self->{instance} . '_total'} =~ /[1-9]/) {
        $self->{result_values}->{traffic_prct} = $self->{result_values}->{traffic_per_seconds} * 100 / $options{new_datas}->{$self->{instance} . '_total'};
    }
    
    return 0;
}

sub prefix_intcmap_output {
    my ($self, %options) = @_;
    
    return "Interface classmap '" . $options{instance_value}->{display} . "' ";
}

sub prefix_cmap_output {
    my ($self, %options) = @_;
    
    return "Classmap '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-source:s' => { name => 'filter_source' },
        'oid-filter:s'    => { name => 'oid_filter', default => 'ifname' },
        'oid-display:s'   => { name => 'oid_display', default => 'ifname' },
        'units-traffic:s' => { name => 'units_traffic', default => '%' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{oids_label} = {
        'ifdesc' => '.1.3.6.1.2.1.2.2.1.2',
        'ifalias' => '.1.3.6.1.2.1.31.1.1.1.18',
        'ifname' => '.1.3.6.1.2.1.31.1.1.1.1',
    };
    $self->check_oids_label();
}

sub check_oids_label {
    my ($self, %options) = @_;

    foreach (('oid_filter', 'oid_display')) {
        $self->{option_results}->{$_} = lc($self->{option_results}->{$_}) if (defined($self->{option_results}->{$_}));
        if (!defined($self->{oids_label}->{$self->{option_results}->{$_}})) {
            my $label = $_;
            $label =~ s/_/-/g;
            $self->{output}->add_option_msg(short_msg => "Unsupported oid in --" . $label . " option.");
            $self->{output}->option_exit();
        }
    }
}

my $mapping = {
    cbQosCMPostPolicyByteOverflow   => { oid => '.1.3.6.1.4.1.9.9.166.1.15.1.1.8' },
    cbQosCMPostPolicyByte           => { oid => '.1.3.6.1.4.1.9.9.166.1.15.1.1.9' },
    cbQosCMPostPolicyByte64         => { oid => '.1.3.6.1.4.1.9.9.166.1.15.1.1.10' },
    cbQosCMDropByteOverflow         => { oid => '.1.3.6.1.4.1.9.9.166.1.15.1.1.15' },
    cbQosCMDropByte                 => { oid => '.1.3.6.1.4.1.9.9.166.1.15.1.1.16' },
    cbQosCMDropByte64               => { oid => '.1.3.6.1.4.1.9.9.166.1.15.1.1.17' }
};
my $mapping2 = {
    cbQosTSCfgRate      => { oid => '.1.3.6.1.4.1.9.9.166.1.13.1.1.1' }, # bps
    cbQosTSCfgRate64    => { oid => '.1.3.6.1.4.1.9.9.166.1.13.1.1.11' } # bps
};
my $mapping3 = {
    cbQosQueueingCfgBandwidth      => { oid => '.1.3.6.1.4.1.9.9.166.1.9.1.1.1' },
    cbQosQueueingCfgBandwidthUnits => { oid => '.1.3.6.1.4.1.9.9.166.1.9.1.1.2' }
};

my $oid_cbQosIfIndex = '.1.3.6.1.4.1.9.9.166.1.1.1.1.4';
my $oid_cbQosConfigIndex = '.1.3.6.1.4.1.9.9.166.1.5.1.1.2';
my $oid_cbQosParentObjectsIndex = '.1.3.6.1.4.1.9.9.166.1.5.1.1.4';    
# Classmap information
my $oid_cbQosCMName = '.1.3.6.1.4.1.9.9.166.1.7.1.1.1';
my $oid_cbQosCMStatsEntry = '.1.3.6.1.4.1.9.9.166.1.15.1.1';
# Can be linked to a classmap also
my $oid_cbQosPolicyMapName = '.1.3.6.1.4.1.9.9.166.1.6.1.1.1';
# Shaping : Linked to a classmap
my $oid_cbQosTSCfgEntry = '.1.3.6.1.4.1.9.9.166.1.13.1.1';
# Linked to a classmap
my $oid_cbQosQueueingCfgEntry = '.1.3.6.1.4.1.9.9.166.1.9.1.1';

sub build_qos_information {
    my ($self, %options) = @_;

    my $qos_data = { complete_name => $options{class_name} };
    # Need to try and find the queueing (it's a child)
    $qos_data->{queueing} = $options{link_queueing}->{$options{policy_index} . '.' . $options{object_index}}
        if (defined($options{link_queueing}->{$options{policy_index} . '.' . $options{object_index}}));
    $qos_data->{shaping} = $options{link_shaping}->{$options{policy_index} . '.' . $options{object_index}}
        if (!defined($qos_data->{shaping}) && defined($options{link_shaping}->{$options{policy_index} . '.' . $options{object_index}}));

    while (($options{object_index} = $self->{results}->{$oid_cbQosParentObjectsIndex}->{$oid_cbQosParentObjectsIndex . '.' . $options{policy_index} . '.' . $options{object_index}}) != 0) {        
        my $config_index = $self->{results}->{$oid_cbQosConfigIndex}->{$oid_cbQosConfigIndex . '.' . $options{policy_index} . '.' . $options{object_index}};

        my $tmp_name = '';
        # try to find policy_map or class_map
        if (defined($self->{results}->{$oid_cbQosCMName}->{$oid_cbQosCMName . '.' . $config_index})) {
            $tmp_name = $self->{results}->{$oid_cbQosCMName}->{$oid_cbQosCMName . '.' . $config_index};
        } elsif (defined($self->{results}->{$oid_cbQosPolicyMapName}->{$oid_cbQosPolicyMapName . '.' . $config_index})) {
            $tmp_name = $self->{results}->{$oid_cbQosPolicyMapName}->{$oid_cbQosPolicyMapName . '.' . $config_index};
        }

        $qos_data->{shaping} = $options{link_shaping}->{$options{policy_index} . '.' . $options{object_index}}
            if (!defined($qos_data->{shaping}) && defined($options{link_shaping}->{$options{policy_index} . '.' . $options{object_index}}));

        $qos_data->{complete_name} = $tmp_name . ':' . $qos_data->{complete_name};
    }

    return $qos_data;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{interface_classmap} = {};
    $self->{classmap} = {};
    $self->{total} = { drop_usage => 0, total_usage => 0 };

    my $request_oids = [
        { oid => $self->{oids_label}->{$self->{option_results}->{oid_filter}} },
        { oid => $oid_cbQosPolicyMapName },
        { oid => $oid_cbQosIfIndex },
        { oid => $oid_cbQosConfigIndex },
        { oid => $oid_cbQosCMName },
        { oid => $oid_cbQosQueueingCfgEntry, end => $mapping3->{cbQosQueueingCfgBandwidthUnits}->{oid} },
        { oid => $oid_cbQosCMStatsEntry, start => $mapping->{cbQosCMPostPolicyByteOverflow}->{oid}, end => $mapping->{cbQosCMDropByte64}->{oid} },
        { oid => $oid_cbQosParentObjectsIndex },
        { oid => $oid_cbQosTSCfgEntry, end => $mapping2->{cbQosTSCfgRate64}->{oid} }
    ];
    push @$request_oids, { oid => $self->{oids_label}->{$self->{option_results}->{oid_display}} } 
        if ($self->{option_results}->{oid_filter} ne $self->{option_results}->{oid_display});
    $self->{results} = $options{snmp}->get_multiple_table(oids => $request_oids);

    my %classmap_name = ();
    foreach (keys %{$self->{results}->{$oid_cbQosConfigIndex}}) {
        if (defined($self->{results}->{$oid_cbQosCMName}->{$oid_cbQosCMName . '.' . $self->{results}->{$oid_cbQosConfigIndex}->{$_}})) {
            /(\d+\.\d+)$/;
            $classmap_name{$1} = $self->{results}->{$oid_cbQosCMName}->{$oid_cbQosCMName . '.' . $self->{results}->{$oid_cbQosConfigIndex}->{$_}};
        }
    }
    my ($link_queueing, $link_shaping) = ({}, {});
    foreach (keys %{$self->{results}->{$oid_cbQosParentObjectsIndex}}) {
        /(\d+)\.(\d+)$/;
        my $config_index = $self->{results}->{$oid_cbQosConfigIndex}->{$oid_cbQosConfigIndex . '.' . $1 . '.' . $2};
        if (defined($self->{results}->{$oid_cbQosQueueingCfgEntry}->{$mapping3->{cbQosQueueingCfgBandwidth}->{oid} . '.' . $config_index})) {
            $link_queueing->{$1 . '.' . $self->{results}->{$oid_cbQosParentObjectsIndex}->{$_}} = $config_index;
        } elsif (defined($self->{results}->{$oid_cbQosTSCfgEntry}->{$mapping2->{cbQosTSCfgRate}->{oid} . '.' . $config_index})) {
            $link_shaping->{$1 . '.' . $self->{results}->{$oid_cbQosParentObjectsIndex}->{$_}} = $config_index;
        }
    }

    foreach (keys %{$self->{results}->{$oid_cbQosCMStatsEntry}}) {
        next if (!/$mapping->{cbQosCMPostPolicyByteOverflow}->{oid}\.(\d+)\.(\d+)/);

        my ($policy_index, $qos_object_index) = ($1, $2);

        my $class_name = $classmap_name{$policy_index . '.' . $qos_object_index};
        my $if_index = $self->{results}->{$oid_cbQosIfIndex}->{$oid_cbQosIfIndex . '.' . $policy_index};
        if (!defined($self->{results}->{$self->{oids_label}->{$self->{option_results}->{oid_display}}}->{$self->{oids_label}->{$self->{option_results}->{oid_display}} . '.' . $if_index})) {
            $self->{output}->output_add(long_msg => "skipping interface index '" . $if_index . "': no display name.", debug => 1);
            next;
        }
        my $interface_display = $self->{results}->{$self->{oids_label}->{$self->{option_results}->{oid_display}}}->{$self->{oids_label}->{$self->{option_results}->{oid_display}} . '.' . $if_index};
        
        if (!defined($self->{results}->{$self->{oids_label}->{$self->{option_results}->{oid_filter}}}->{$self->{oids_label}->{$self->{option_results}->{oid_filter}} . '.' . $if_index})) {
            $self->{output}->output_add(long_msg => "skipping interface index '" . $if_index . "': no filter name.", debug => 1);
            next;
        }

        my $qos_data = $self->build_qos_information(
            class_name => $class_name,
            policy_index => $policy_index,
            object_index => $qos_object_index,
            link_queueing => $link_queueing,
            link_shaping => $link_shaping
        );

        my $interface_filter = $self->{results}->{$self->{oids_label}->{$self->{option_results}->{oid_filter}}}->{$self->{oids_label}->{$self->{option_results}->{oid_filter}} . '.' . $if_index};
        my $name = $interface_filter . ':' . $qos_data->{complete_name};

        if (defined($self->{option_results}->{filter_source}) && $self->{option_results}->{filter_source} ne '' &&
            $name !~ /$self->{option_results}->{filter_source}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $name . "': no matching filter source.", debug => 1);
            next;
        }

        # Same hash key but only for disco context
        if (defined($options{disco})) {
            $self->{interface_classmap}->{$policy_index . '.' . $qos_object_index} = $name;
            next;
        }

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_cbQosCMStatsEntry}, instance => $policy_index . '.' . $qos_object_index);
        my $traffic_usage = (defined($result->{cbQosCMPostPolicyByte64}) && $result->{cbQosCMPostPolicyByte64} =~ /[1-9]/) ?
            $result->{cbQosCMPostPolicyByte64} :
            (
                ($result->{cbQosCMPostPolicyByteOverflow} == 4294967295) ?
                undef :
                ($result->{cbQosCMPostPolicyByteOverflow} * 4294967295 + $result->{cbQosCMPostPolicyByte})
            );
        my $drop_usage = 
            (defined($result->{cbQosCMDropByte64}) && $result->{cbQosCMDropByte64} =~ /[1-9]/) ?
            $result->{cbQosCMDropByte64} :
            (
                ($result->{cbQosCMDropByteOverflow} == 4294967295) ?
                undef :
                ($result->{cbQosCMDropByteOverflow} * 4294967295 + $result->{cbQosCMDropByte})
            );

        my $total = 'unknown';
        if (defined($qos_data->{shaping})) {
            my $result_shaping = $options{snmp}->map_instance(mapping => $mapping2, results => $self->{results}->{$oid_cbQosTSCfgEntry}, instance => $qos_data->{shaping});
            $total = defined($result_shaping->{cbQosTSCfgRate64}) ? $result_shaping->{cbQosTSCfgRate64} : $result_shaping->{cbQosTSCfgRate};
        }

        $self->{interface_classmap}->{$policy_index . '.' . $qos_object_index} = {
            display => $name,
            traffic_usage => defined($traffic_usage) ? $traffic_usage * 8 : undef,
            drop_usage => defined($drop_usage) ? $drop_usage * 8 : undef,
            total => $total
        };

        my @tabname = split /:/, $name;
        if (defined($tabname[3])){
            $class_name = $tabname[3] . '-' . $class_name;
        }

        $self->{classmap}->{$name} = { display => $class_name, drop_usage => 0, traffic_usage => 0} if (!defined($self->{classmap}->{$name}));
        $self->{classmap}->{$name}->{traffic_usage} += defined($traffic_usage) ? $traffic_usage * 8 : 0;
        $self->{classmap}->{$name}->{drop_usage} += defined($drop_usage) ? $drop_usage * 8 : 0;

        if (!defined($tabname[3])){
            $self->{total}->{traffic_usage} += defined($traffic_usage) ? $traffic_usage * 8 : 0;
            $self->{total}->{drop_usage} += defined($drop_usage) ? $drop_usage * 8 : 0;
        }
    }

    $self->{cache_name} = 'cisco_qos_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_source}) ? md5_hex($self->{option_results}->{filter_source}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));

    if (scalar(keys %{$self->{interface_classmap}}) <= 0 && !defined($options{disco})) {
        $self->{output}->add_option_msg(short_msg => 'Cannot found classmap.');
        $self->{output}->option_exit();
    }
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['name']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(disco => 1, %options);
    foreach (keys %{$self->{interface_classmap}}) {
        $self->{output}->add_disco_entry(name => $self->{interface_classmap}->{$_});
    }
}

1;

__END__

=head1 MODE

Check QoS.

=over 8

=item B<--filter-source>

Filter interface name and class-map (can be a regexp).
Example of a source (interfacename:servicepolicy:classmap:...): FastEthernet1:Visioconference

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^(total-traffic)$'

=item B<--warning-*>

Threshold warning.
Can be: 'int-cmap-traffic', 'int-cmap-drop', 
'cmap-traffic', 'cmap-drop', 'total-traffic', 'total-drop'.

=item B<--critical-*>

Threshold critical.
Can be: 'int-cmap-traffic', 'int-cmap-drop', 
'cmap-traffic', 'cmap-drop', 'total-traffic', 'total-drop'.

=item B<--units-traffic>

Units of thresholds for the traffic (Default: '%') ('%', 'b/s').
Only for --warning-int-traffic and --critical-int-traffic options.

=item B<--oid-filter>

Choose OID used to filter interface (default: ifName) (values: ifDesc, ifAlias, ifName).

=item B<--oid-display>

Choose OID used to display interface (default: ifName) (values: ifDesc, ifAlias, ifName).

=back

=cut
