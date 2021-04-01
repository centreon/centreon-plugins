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

package network::oracle::otd::snmp::mode::vserverusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'vs', type => 1, cb_prefix_output => 'prefix_vs_output', message_multiple => 'All Virtual Servers are ok', skipped_code => { -10 => 1 } },
    ];
    
    $self->{maps_counters}->{vs} = [
        { label => 'in', set => {
                key_values => [ { name => 'vsInOctets', per_second => 1 }, { name => 'display' } ],
                output_template => 'Traffic In: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'traffic_in', template => '%.2f', min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'out', set => {
                key_values => [ { name => 'vsOutOctets', per_second => 1 }, { name => 'display' } ],
                output_template => 'Traffic Out: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'traffic_out', template => '%.2f', min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        }
    ];    
    my @map = (
        'count-request', 'Count Requests : %s', 'vsCountRequests', 'count_request',
        'count-2xx', 'Count 2xx Responses : %s', 'vsCount2xx', 'count_2xx',
        'count-3xx', 'Count 3xx Responses : %s', 'vsCount3xx', 'count_3xx',
        'count-4xx', 'Count 4xx Responses : %s', 'vsCount4xx', 'count_4xx',
        'count-5xx', 'Count 5xx Responses : %s', 'vsCount5xx', 'count_5xx',
    );
    for (my $i = 0; $i < scalar(@map); $i += 4) {
        push @{$self->{maps_counters}->{vs}}, { label => $map[$i], set => {
                key_values => [ { name => $map[$i + 2], diff => 1 }, { name => 'display' } ],
                output_template => $map[$i + 1],
                perfdatas => [
                    { label => $map[$i + 3], template => '%s', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        };
    }
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

sub prefix_vs_output {
    my ($self, %options) = @_;
    
    return "Virtual Server '" . $options{instance_value}->{display} . "' ";
}

my $mapping = {
    vsId            => { oid => '.1.3.6.1.4.1.111.19.190.1.30.1.2' },
    vsCountRequests => { oid => '.1.3.6.1.4.1.111.19.190.1.30.1.3' },
    vsInOctets      => { oid => '.1.3.6.1.4.1.111.19.190.1.30.1.4' },
    vsOutOctets     => { oid => '.1.3.6.1.4.1.111.19.190.1.30.1.5' },
    vsCount2xx      => { oid => '.1.3.6.1.4.1.111.19.190.1.30.1.6' },
    vsCount3xx      => { oid => '.1.3.6.1.4.1.111.19.190.1.30.1.7' },
    vsCount4xx      => { oid => '.1.3.6.1.4.1.111.19.190.1.30.1.8' },
    vsCount5xx      => { oid => '.1.3.6.1.4.1.111.19.190.1.30.1.9' },
};
my $oid_vsEntry = '.1.3.6.1.4.1.111.19.190.1.30.1';

sub manage_selection {
    my ($self, %options) = @_;
 
    if ($options{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Need to use SNMP v2c or v3.");
        $self->{output}->option_exit();
    }
    my $snmp_result = $options{snmp}->get_table(oid => $oid_vsEntry, end => $mapping->{vsCount5xx}->{oid}, nothing_quit => 1);
    $self->{vs} = {};
    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{vsId}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{vsId} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping Virtual Server '" . $result->{vsId} . "'.", debug => 1);
            next;
        }
        
        $result->{vsInOctets} *= 8;
        $result->{vsOutOctets} *= 8;
        $self->{vs}->{$instance} = {
            display => $result->{vsId},
            %$result
        };
    }
    
    if (scalar(keys %{$self->{vs}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No virtual server found.");
        $self->{output}->option_exit();
    }
    
    $self->{cache_name} = "oracle_otd_" . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check virtual server usage.

=over 8

=item B<--filter-name>

Filter by vserver name (can be a regexp).

=item B<--warning-*>

Threshold warning.
Can be: 'in', 'out', 'count-request',
'count-2xx', 'count-3xx', 'count-4xx', 'count-5xx'.

=item B<--critical-*>

Threshold critical.
Can be: 'in', 'out', 'count-request',
'count-2xx', 'count-3xx', 'count-4xx', 'count-5xx'.

=back

=cut
