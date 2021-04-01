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

package centreon::common::airespace::snmp::mode::apchannelinterference;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub ap_long_output {
    my ($self, %options) = @_;

    return "checking access point '" . $options{instance_value}->{display} . "'";
}

sub prefix_ap_output {
    my ($self, %options) = @_;

    return "access point '" . $options{instance_value}->{display} . "' ";
}

sub prefix_channel_output {
    my ($self, %options) = @_;

    return "channel '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'ap', type => 3, cb_prefix_output => 'prefix_ap_output', cb_long_output => 'ap_long_output', indent_long_output => '    ', message_multiple => 'All access points are ok',
            group => [
                { name => 'channels', display_long => 1, cb_prefix_output => 'prefix_channel_output',  message_multiple => 'channels are ok', type => 1, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{channels} = [
        { label => 'interference-power', nlabel => 'accesspoint.interference.power.count', set => {
                key_values => [ { name => 'interference_power' }, { name => 'display' } ],
                output_template => 'interference power: %s',
                perfdatas => [
                    { label => 'interference_power', template => '%s',
                      label_extra_instance => 1  }
                ]
            }
        },
        { label => 'interference-util', nlabel => 'accesspoint.interference.utilization.percentage', set => {
                key_values => [ { name => 'interference_util' }, { name => 'display' } ],
                output_template => 'interference utilization: %s %%',
                perfdatas => [
                    { label => 'interference_util', template => '%s', 
                      unit => '%', min => 0, max => 100, label_extra_instance => 1  }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'filter-name:s'    => { name => 'filter_name' },
        'filter-channel:s' => { name => 'filter_channel' },
        'filter-group:s'   => { name => 'filter_group' }
    });

    return $self;
}

my $mapping = {
    ap_name    => { oid => '.1.3.6.1.4.1.14179.2.2.1.1.3' }, # bsnAPName
    group_name => { oid => '.1.3.6.1.4.1.14179.2.2.1.1.30' } # bsnAPGroupVlanName
};
my $mapping2 = {
    interference_power => { oid => '.1.3.6.1.4.1.14179.2.2.14.1.2' }, # bsnAPIfInterferencePower
    interference_util  => { oid => '.1.3.6.1.4.1.14179.2.2.14.1.22' } # bsnAPIfInterferenceUtilization
};

sub manage_selection {
    my ($self, %options) = @_;

    my $request = [
        { oid => $mapping->{ap_name}->{oid} },
        { oid => $mapping2->{interference_power}->{oid} },
        { oid => $mapping2->{interference_util}->{oid} }
    ];
    push @$request, { oid => $mapping->{group_name}->{oid} }
        if (defined($self->{option_results}->{filter_group}) && $self->{option_results}->{filter_group} ne '');
    
    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => $request,
        return_type => 1,
        nothing_quit => 1
    );

    foreach (keys %$snmp_result) {
        next if (! /^$mapping->{ap_name}->{oid}\.(.*)/);
        my $instance = $1;

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{ap_name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{ap_name} . "'.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_group}) && $self->{option_results}->{filter_group} ne '' &&
            $result->{group_name} !~ /$self->{option_results}->{filter_group}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{ap_name} . "'.", debug => 1);
            next;
        }

        $self->{ap}->{ $result->{ap_name} } = {
            display => $result->{ap_name},
            channels => {}
        };

        foreach my $oid (keys %$snmp_result) {
            next if ($oid !~ /^$mapping2->{interference_power}->{oid}\.$instance\.(\d+)\.(\d+)$/);
            my ($slot_id, $channel_id) = ($1, $2);

            my $result2 = $options{snmp}->map_instance(mapping => $mapping2, results => $snmp_result, instance => $instance . '.' . $slot_id . '.' . $channel_id);
            my $name = "slot$slot_id:channel$channel_id";
            if (defined($self->{option_results}->{filter_channel}) && $self->{option_results}->{filter_channel} ne '' &&
                $name !~ /$self->{option_results}->{filter_channel}/) {
                $self->{output}->output_add(long_msg => "skipping channel '" . $name . "': no matching filter.", debug => 1);
                next;
            }

            $self->{ap}->{ $result->{ap_name} }->{channels}->{$name} = {
                display => $name,
                %$result2
            };
        }
    }

    if (scalar(keys %{$self->{ap}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No entry found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check AP Channel Interference.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='interference-util'

=item B<--filter-name>

Filter access point name (can be a regexp).

=item B<--filter-group>

Filter access point group (can be a regexp).

=item B<--filter-channel>

Filter channel (can be a regexp). Example: --filter-channel='slot0:channel3'

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'interference-power', 'interference-util' (%).

=back

=cut
