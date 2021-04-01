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

package apps::inin::ig::snmp::mode::stats;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, message_separator => ' - ' },
        { name => 'cg', type => 1, cb_prefix_output => 'prefix_cg_output', message_multiple => 'All channel groups are ok' }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'sip-active-calls', set => {
                key_values => [ { name => 'SipActiveCallsCount' } ],
                output_template => 'SIP Current Active Calls : %s',
                perfdatas => [
                    { label => 'sip_active_calls', value => 'SipActiveCallsCount', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'tdm-active-calls', set => {
                key_values => [ { name => 'TdmActiveCallsCount' } ],
                output_template => 'TDM Current Active Calls : %s',
                perfdatas => [
                    { label => 'tdm_active_calls', value => 'TdmActiveCallsCount', template => '%d',
                      min => 0 },
                ],
            }
        },
    ];
    $self->{maps_counters}->{cg} = [
        { label => 'channel-group-active-calls', set => {
                key_values => [ { name => 'i3IgChannelGroupActiveCallsCount' }, { name => 'display' } ],
                output_template => 'Current Active Calls : %s',
                perfdatas => [
                    { label => 'channel_group_active_calls', value => 'i3IgChannelGroupActiveCallsCount', template => '%d',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                  "filter-name:s"       => { name => 'filter_name' },
                                });
    
    return $self;
}

sub prefix_cg_output {
    my ($self, %options) = @_;
    
    return "Channel group '" . $options{instance_value}->{display} . "' ";
}

my $mapping = {
    i3IgChannelGroupName                => { oid => '.1.3.6.1.4.1.2793.4.2.13.1.2' },
    i3IgChannelGroupActiveCallsCount    => { oid => '.1.3.6.1.4.1.2793.4.2.13.1.3' },
};
my $oid_i3IgInfo = '.1.3.6.1.4.1.2793.4.2';
my $oid_i3IgSipActiveCallsCount = '.1.3.6.1.4.1.2793.4.2.4';
my $oid_i3IgTdmActiveCallsCount = '.1.3.6.1.4.1.2793.4.2.7';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cg} = {};
    my $snmp_result = $options{snmp}->get_table(oid => $oid_i3IgInfo, start => $oid_i3IgSipActiveCallsCount, 
                                                nothing_quit => 1);

    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{i3IgChannelGroupActiveCallsCount}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{i3IgChannelGroupName} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{i3IgSpanInfoSpanId} . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{cg}->{$instance} = { display => $result->{i3IgChannelGroupName}, %$result };
    }
    
    $self->{global} = { 
        SipActiveCallsCount => $snmp_result->{$oid_i3IgSipActiveCallsCount . '.0'},
        TdmActiveCallsCount => $snmp_result->{$oid_i3IgTdmActiveCallsCount . '.0'},
    };
}

1;

__END__

=head1 MODE

Check statistics.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^sip-active-calls$'

=item B<--filter-name>

Filter channel group name (can be a regexp).

=item B<--warning-*>

Threshold warning.
Can be: 'sip-active-calls', 'tdm-active-calls',
'channel-group-active-calls'.

=item B<--critical-*>

Threshold critical.
Can be: 'sip-active-calls', 'tdm-active-calls',
'channel-group-active-calls'.

=back

=cut
