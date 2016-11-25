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

package centreon::common::cisco::standard::snmp::mode::qosusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'ps', type => 1, cb_prefix_output => 'prefix_ps_output', message_multiple => 'All power sources are ok' },
    ];

    $self->{maps_counters}->{ps} = [
        { label => 'power', set => {
                key_values => [ { name => 'PwrTotal' }, { name => 'display' } ],
                output_template => 'Total input power : %s W', output_error_template => "total input power : %s",
                perfdatas => [
                    { label => 'power', value => 'PwrTotal_absolute', template => '%s',
                      unit => 'W', min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'energy', set => {
                key_values => [ { name => 'EnergyAccum', diff => 1 }, { name => 'display' } ],
                output_template => 'Total energy : %.3f kWh', output_error_template => "Total energy : %s",
                perfdatas => [
                    { label => 'energy', value => 'EnergyAccum_absolute', template => '%.3f',
                      unit => 'kWh', min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'current-neutral', set => {
                key_values => [ { name => 'EcNeutral' }, { name => 'display' } ],
                output_template => 'Current neutral : %s Amp AC RMS', output_error_template => "Current neutral : %s",
                perfdatas => [
                    { label => 'current_neutral', value => 'EcNeutral_absolute', template => '%s',
                      unit => 'AmpAcRMS', min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
    ];
}

sub prefix_ps_output {
    my ($self, %options) = @_;
    
    return "Power source '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                "filter-source:s"       => { name => 'filter_source' },
                                "oid-filter:s"          => { name => 'oid_filter', default => 'ifname' },
                                "oid-display:s"         => { name => 'oid_display', default => 'ifname' },
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
    cbQosCMPrePolicyByteOverflow     => { oid => '.1.3.6.1.4.1.9.9.166.1.15.1.1.4' },
    cbQosCMPrePolicyByte             => { oid => '.1.3.6.1.4.1.9.9.166.1.15.1.1.5' },
    cbQosCMPrePolicyByte64           => { oid => '.1.3.6.1.4.1.9.9.166.1.15.1.1.6' },
    cbQosCMPostPolicyByteOverflow    => { oid => '.1.3.6.1.4.1.9.9.166.1.15.1.1.8' },
    cbQosCMPostPolicyByte            => { oid => '.1.3.6.1.4.1.9.9.166.1.15.1.1.9' },
    cbQosCMPostPolicyByte64          => { oid => '.1.3.6.1.4.1.9.9.166.1.15.1.1.10' },
    cbQosCMDropPktOverflow     => { oid => '.1.3.6.1.4.1.9.9.166.1.15.1.1.12' },
    cbQosCMDropPkt             => { oid => '.1.3.6.1.4.1.9.9.166.1.15.1.1.13' },
    cbQosCMDropPkt64           => { oid => '.1.3.6.1.4.1.9.9.166.1.15.1.1.14' },
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
my $oid_cbQosTSCfgRate = '.1.3.6.1.4.1.9.9.166.1.13.1.1.1';
# Linked to a classmap
my $oid_cbQosQueueingCfgBandwidth = '.1.3.6.1.4.1.9.9.166.1.9.1.1.1';
my $oid_cbQosQueueingCfgBandwidthUnits = '.1.3.6.1.4.1.9.9.166.1.9.1.1.2';

sub build_qos_information {
    my ($self, %options) = @_;
    
    $self->{complete_name} = $options{class_name};
    # Need to try and find the queueing (it's a child)
    # TODO
    
    while (($options{object_index} = $self->{results}->{$oid_cbQosParentObjectsIndex}->{$oid_cbQosParentObjectsIndex . '.' . $options{policy_index} . '.' . $options{object_index}}) != 0) {        
        my $config_index = $self->{results}->{$oid_cbQosConfigIndex}->{$oid_cbQosConfigIndex . '.' . $options{policy_index} . '.' . $options{object_index}};
        
        my $tmp_name = '';
        # try to find policy_map or class_map
        if (defined($self->{results}->{$oid_cbQosCMName}->{$oid_cbQosCMName . '.' . $config_index})) {
            $tmp_name = $self->{results}->{$oid_cbQosCMName}->{$oid_cbQosCMName . '.' . $config_index};
        } elsif (defined($self->{results}->{$oid_cbQosPolicyMapName}->{$oid_cbQosPolicyMapName . '.' . $config_index})) {
            $tmp_name = $self->{results}->{$oid_cbQosPolicyMapName}->{$oid_cbQosPolicyMapName . '.' . $config_index};
        }
        
        # Need to find a shaping (first)
        # TODO
        
        $self->{complete_name} = $tmp_name . ':' . $self->{complete_name};
    }
}

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{interface_classmap} = {};
    
    my $request_oids = [
        { oid => $self->{oids_label}->{$self->{option_results}->{oid_filter}} },
        { oid => $oid_cbQosPolicyMapName },
        { oid => $oid_cbQosIfIndex },
        { oid => $oid_cbQosConfigIndex },
        { oid => $oid_cbQosCMName },
        { oid => $oid_cbQosQueueingCfgBandwidth },
        { oid => $oid_cbQosQueueingCfgBandwidthUnits },
        { oid => $oid_cbQosCMStatsEntry },
        { oid => $oid_cbQosParentObjectsIndex },
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
    #$self->{parent_object} = {};
    #foreach (keys %{$self->{results}->{$oid_cbQosParentObjectsIndex}}) {
    #    /(\d+)\.(\d+)$/;
    #    $self->{parent_object}->{$1 . '.' . $self->{results}->{$oid_cbQosParentObjectsIndex}->{$_}} = $2; 
    #}

    foreach (keys %{$self->{results}->{$oid_cbQosCMStatsEntry}}) {
        next if (!/$mapping->{cbQosCMPrePolicyByte}->{oid}\.(\d+)\.(\d+)/);
        
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
        
        $self->build_qos_information(class_name => $class_name, policy_index => $policy_index, object_index => $qos_object_index);
        
        my $interface_filter = $self->{results}->{$self->{oids_label}->{$self->{option_results}->{oid_filter}}}->{$self->{oids_label}->{$self->{option_results}->{oid_filter}} . '.' . $if_index};
        my $name = $interface_filter . ':' . $self->{complete_name};
        
        if (defined($self->{option_results}->{filter_source}) && $self->{option_results}->{filter_source} ne '' &&
            $name !~ /$self->{option_results}->{filter_source}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $name . "': no matching filter source.", debug => 1);
            next;
        }
        
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_cbQosCMStatsEntry}, instance => $policy_index . '.' . $qos_object_index);
        print "======$name=======\n";
    }
    
    $self->{cache_name} = "cisco_qos_" . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_source}) ? md5_hex($self->{option_results}->{filter_source}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
    
    if (scalar(keys %{$self->{interface_classmap}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "Cannot found classmap.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check QoS.

=over 8

=item B<--filter-source>

Filter interface name and class-map (can be a regexp).
Example of a source (interfacename:classmap): FastEthernet1:Visioconference

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^(power|energy)$'

=item B<--warning-*>

Threshold warning.
Can be: 'power', 'energy', 'current-neutral',
'line-load', 'line-current'.

=item B<--critical-*>

Threshold critical.
Can be: 'power', 'energy', 'current-neutral',
'line-load', 'line-current'.

=item B<--oid-filter>

Choose OID used to filter interface (default: ifName) (values: ifDesc, ifAlias, ifName).

=item B<--oid-display>

Choose OID used to display interface (default: ifName) (values: ifDesc, ifAlias, ifName).

=back

=cut
