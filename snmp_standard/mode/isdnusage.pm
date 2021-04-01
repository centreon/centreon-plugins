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

package snmp_standard::mode::isdnusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'bearer', type => 0 },
        { name => 'isdn', type => 1, cb_prefix_output => 'prefix_isdn_output', message_multiple => 'All isdn channels are ok' }
    ];
    
    $self->{maps_counters}->{isdn} = [
        { label => 'in-calls', set => {
                key_values => [ { name => 'in', diff => 1 }, { name => 'display' } ],
                output_template => 'Incoming calls : %s',
                perfdatas => [
                    { label => 'in_calls', value => 'in', template => '%s', 
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'out-calls', set => {
                key_values => [ { name => 'out', diff => 1 }, { name => 'display' } ],
                output_template => 'Outgoing calls : %s',
                perfdatas => [
                    { label => 'out_calls', value => 'out', template => '%s', 
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
    $self->{maps_counters}->{bearer} = [
        { label => 'current-calls', set => {
                key_values => [ { name => 'active' }, { name => 'total' } ],
                output_template => 'Current calls : %s',
                perfdatas => [
                    { label => 'current_calls', value => 'active', template => '%s', 
                      min => 0, max => 'total' },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-name:s' => { name => 'filter_name' },
    });

    return $self;
}

sub prefix_isdn_output {
    my ($self, %options) = @_;
    
    return "ISDN channel '" . $options{instance_value}->{display} . "' ";
}

my %map_bearer_state = (
    1 => 'idle',
    2 => 'connecting',
    3 => 'connected',
    4 => 'active',
);
my $mapping = {
    isdnSigStatsInCalls     => { oid => '.1.3.6.1.2.1.10.20.1.3.3.1.1' },
    isdnSigStatsOutCalls    => { oid => '.1.3.6.1.2.1.10.20.1.3.3.1.3' },
};

my $oid_isdnBearerOperStatus = '.1.3.6.1.2.1.10.20.1.2.1.1.2';
my $oid_isdnSignalingIfIndex = '.1.3.6.1.2.1.10.20.1.3.2.1.2';
my $oid_isdnSignalingStatsEntry = '.1.3.6.1.2.1.10.20.1.3.3.1';
my $oid_ifDescr = '.1.3.6.1.2.1.2.2.1.2';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{isdn} = {};
    $self->{bearer} = { active => 0, total => 0 };
    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [ 
            { oid => $oid_isdnBearerOperStatus },
            { oid => $oid_isdnSignalingIfIndex },
            { oid => $oid_isdnSignalingStatsEntry },
        ],
        nothing_quit => 1
    );

    # Get interface name
    foreach my $oid (keys %{$snmp_result->{$oid_isdnSignalingIfIndex}}) {
        $options{snmp}->load(oids => [$oid_ifDescr], instances => [$snmp_result->{$oid_isdnSignalingIfIndex}->{$oid}]);
    }
    my $result_ifdesc = $options{snmp}->get_leef(nothing_quit => 1);

    foreach my $oid (keys %{$snmp_result->{$oid_isdnSignalingIfIndex}}) {
        $oid =~ /^$oid_isdnSignalingIfIndex\.(.*)/;
        my $instance = $1;
        my $display = $result_ifdesc->{$oid_ifDescr . '.' . $snmp_result->{$oid_isdnSignalingIfIndex}->{$oid_isdnSignalingIfIndex . '.' . $instance}};
        
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $display !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $display . "': no matching filter name.", debug => 1);
            next;
        }
        
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result->{$oid_isdnSignalingStatsEntry}, instance => $instance);
        $self->{isdn}->{$instance} = {
            in => $result->{isdnSigStatsInCalls},
            out => $result->{isdnSigStatsOutCalls}, 
            display => $display
        };
    }
    
    foreach my $oid (keys %{$snmp_result->{$oid_isdnBearerOperStatus}}) {
        my $status = defined($map_bearer_state{$snmp_result->{$oid_isdnBearerOperStatus}->{$oid}}) ? 
             $map_bearer_state{$snmp_result->{$oid_isdnBearerOperStatus}->{$oid}} : 'unknown';
        $self->{bearer}->{total}++;
        $self->{bearer}->{active}++ if ($status =~ /active/);
    }

    $self->{cache_name} = "isdn_usage_" . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check ISDN usages (ISDN-MIB).

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^current-calls$'

=item B<--filter-name>

Filter by name (regexp can be used).

=item B<--warning-*>

Threshold warning.
Can be: 'in-calls', 'out-calls', 'current-calls'.

=item B<--critical-*>

Threshold critical.
Can be: 'in-calls', 'out-calls', 'current-calls'.

=back

=cut
