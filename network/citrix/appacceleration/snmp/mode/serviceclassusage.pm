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

package network::citrix::appacceleration::snmp::mode::serviceclassusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'sc', type => 1, cb_prefix_output => 'prefix_sc_output', message_multiple => 'All Service Class are ok' }
    ];
    
    $self->{maps_counters}->{sc} = [
        { label => 'current-acc-con', set => {
                key_values => [ { name => 'wsScsCurrentAcceleratedConnections' }, { name => 'display' } ],
                output_template => 'Current Accelerated Connections : %s',
                perfdatas => [
                    { label => 'current_accelerated_connections', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'total-acc-con', set => {
                key_values => [ { name => 'wsScsTotalAcceleratedConnections', diff => 1 }, { name => 'display' } ],
                output_template => 'Total Accelerated Connections : %s',
                perfdatas => [
                    { label => 'total_accelerated_connections', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'total-nonacc-con', set => {
                key_values => [ { name => 'wsScsTotalNonAcceleratedConnections', diff => 1 }, { name => 'display' } ],
                output_template => 'Total Non Accelerated Connections : %s',
                perfdatas => [
                    { label => 'total_nonaccelerated_connections', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'traffic-in', set => {
                key_values => [ { name => 'wsScsPreCompressReceivedOctets', per_second => 1 }, { name => 'display' } ],
                output_template => 'Traffic In : %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'traffic_in', template => '%.2f',
                      min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'traffic-in-compressed', set => {
                key_values => [ { name => 'wsScsCompressReceivedOctets', per_second => 1 }, { name => 'display' } ],
                output_template => 'Traffic In Compressed : %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'traffic_in_compressed', template => '%.2f',
                      min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'traffic-out', set => {
                key_values => [ { name => 'wsScsPreCompressSentOctets', per_second => 1 }, { name => 'display' } ],
                output_template => 'Traffic Out : %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'traffic_out', template => '%.2f',
                      min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'traffic-out-compressed', set => {
                key_values => [ { name => 'wsScsCompressSentOctets', per_second => 1 }, { name => 'display' } ],
                output_template => 'Traffic Out Compressed : %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'traffic_out_compressed', template => '%.2f',
                      min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub prefix_sc_output {
    my ($self, %options) = @_;
    
    return "Service Class '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-name:s' => { name => 'filter_name' }
    });

    return $self;
}

my $oid_wsServiceClassName = '.1.3.6.1.4.1.3845.30.4.1.1.2.2.1.2';
my $mapping = {
    wsScsCurrentAcceleratedConnections  => { oid => '.1.3.6.1.4.1.3845.30.4.1.1.2.2.1.3' },
    wsScsTotalAcceleratedConnections    => { oid => '.1.3.6.1.4.1.3845.30.4.1.1.2.2.1.4' },
    wsScsTotalNonAcceleratedConnections => { oid => '.1.3.6.1.4.1.3845.30.4.1.1.2.2.1.6' },
    wsScsCompressSentOctets             => { oid => '.1.3.6.1.4.1.3845.30.4.1.1.2.2.1.9' },
    wsScsCompressReceivedOctets         => { oid => '.1.3.6.1.4.1.3845.30.4.1.1.2.2.1.10' },
    wsScsPreCompressSentOctets          => { oid => '.1.3.6.1.4.1.3845.30.4.1.1.2.2.1.11' },
    wsScsPreCompressReceivedOctets      => { oid => '.1.3.6.1.4.1.3845.30.4.1.1.2.2.1.12' },
};

sub manage_selection {
    my ($self, %options) = @_;

    if ($options{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Need to use SNMP v2c or v3.");
        $self->{output}->option_exit();
    }

    my $snmp_result = $options{snmp}->get_table(oid => $oid_wsServiceClassName, nothing_quit => 1);
    $self->{sc} = {};
    foreach my $oid (keys %{$snmp_result}) {
        $oid =~ /\.(\d+)$/;
        my $instance = $1;      
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $snmp_result->{$oid} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping service class '" . $snmp_result->{$oid} . "'.", debug => 1);
            next;
        }
        
        $self->{sc}->{$instance} = { display => $snmp_result->{$oid} };
    }
    
    $options{snmp}->load(oids => [$mapping->{wsScsCurrentAcceleratedConnections}->{oid}, $mapping->{wsScsTotalAcceleratedConnections}->{oid},
        $mapping->{wsScsTotalNonAcceleratedConnections}->{oid}, $mapping->{wsScsCompressSentOctets}->{oid},
        $mapping->{wsScsCompressReceivedOctets}->{oid}, $mapping->{wsScsPreCompressSentOctets}->{oid},
        $mapping->{wsScsPreCompressReceivedOctets}->{oid}
        ], 
        instances => [keys %{$self->{sc}}], instance_regexp => '^(.*)$');
    $snmp_result = $options{snmp}->get_leef(nothing_quit => 1);
    
    foreach (keys %{$self->{sc}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $_);        
        
        foreach my $name (('wsScsCompressSentOctets', 'wsScsCompressReceivedOctets', 'wsScsPreCompressSentOctets', 'wsScsPreCompressReceivedOctets')) {
            $result->{$name} *= 8;
        }
        
        foreach my $name (keys %$mapping) {
            $self->{sc}->{$_}->{$name} = $result->{$name};
        }
    }
    
    if (scalar(keys %{$self->{sc}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No service class found.");
        $self->{output}->option_exit();
    }
    
    $self->{cache_name} = "citrix_appacceleration_" . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check service class usage.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'current-acc-con', 'total-acc-con', 'total-nonacc-con',
'traffic-in-compressed', 'traffic-out-compressed',
'traffic-in', 'traffic-out'.

=item B<--critical-*>

Threshold critical.
Can be: 'current-acc-con', 'total-acc-con', 'total-nonacc-con',
'traffic-in-compressed', 'traffic-out-compressed',
'traffic-in', 'traffic-out'.

=item B<--filter-name>

Filter by service class name (can be a regexp).

=back

=cut
