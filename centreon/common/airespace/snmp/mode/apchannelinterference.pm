#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'ap', type => 1, cb_prefix_output => 'prefix_ap_output', message_multiple => 'All AP interference statistics are ok' },
    ];
    $self->{maps_counters}->{ap} = [
        { label => 'interference-power', set => {
                key_values => [ { name => 'interference_power' }, { name => 'label_perfdata' } ],
                output_template => 'Interference Power : %s',
                perfdatas => [
                    { label => 'interference_power', value => 'interference_power', template => '%s',
                      label_extra_instance => 1, instance_use => 'label_perfdata'  },
                ],
            }
        },
        { label => 'interference-util', set => {
                key_values => [ { name => 'interference_util' }, { name => 'label_perfdata' } ],
                output_template => 'Interference Utilization : %s %%',
                perfdatas => [
                    { label => 'interference_util', value => 'interference_util', template => '%s', 
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'label_perfdata'  },
                ],
            }
        },
    ];
}

sub prefix_ap_output {
    my ($self, %options) = @_;
    
    return $options{instance_value}->{display} . " ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'filter-name:s'     => { name => 'filter_name' },
        'filter-channel:s'  => { name => 'filter_channel' },
    });
    
    return $self;
}

my $oid_bsnAPName = '.1.3.6.1.4.1.14179.2.2.1.1.3';
my $oid_bsnAPIfInterferencePower = '.1.3.6.1.4.1.14179.2.2.14.1.2';
my $oid_bsnAPIfInterferenceUtilization = '.1.3.6.1.4.1.14179.2.2.14.1.22';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{ap} = {};
    $self->{results} = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_bsnAPName },
            { oid => $oid_bsnAPIfInterferencePower },
            { oid => $oid_bsnAPIfInterferenceUtilization },
        ],
        nothing_quit => 1
    );
    foreach my $oid (keys %{$self->{results}->{$oid_bsnAPName}}) {
        $oid =~ /^$oid_bsnAPName\.(.*)$/;
        my $instance_mac = $1;        
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $self->{results}->{$oid_bsnAPName}->{$oid} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "Skipping  '" . $self->{results}->{$oid_bsnAPName}->{$oid} . "': no matching filter.");
            next;
        }
        my $instance_end;
        foreach my $oid2 (keys %{$self->{results}->{$oid_bsnAPIfInterferencePower}}) {
            if ($oid2 =~ /^$oid_bsnAPIfInterferencePower\.$instance_mac\.(\d+)\.(\d+)$/) {
                $instance_end = $1 . '.' . $2;
                
                if (defined($self->{option_results}->{filter_channel}) && $self->{option_results}->{filter_channel} ne '' &&
                    $instance_end !~ /$self->{option_results}->{filter_channel}/) {
                    $self->{output}->output_add(long_msg => "Skipping channel '" . $instance_end . "': no matching filter.");
                    next;
                }
                
                $self->{ap}->{$instance_mac . '.' . $instance_end} = {
                    display => "AP '" . $self->{results}->{$oid_bsnAPName}->{$oid} . "' Slot $1 Channel $2",
                    label_perfdata => $self->{results}->{$oid_bsnAPName}->{$oid} . "_$1_$2",
                    interference_power => $self->{results}->{$oid_bsnAPIfInterferencePower}->{$oid_bsnAPIfInterferencePower . '.' . $instance_mac . '.' . $instance_end},
                    interference_util => $self->{results}->{$oid_bsnAPIfInterferenceUtilization}->{$oid_bsnAPIfInterferenceUtilization . '.' . $instance_mac . '.' . $instance_end}
                };
            }
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

=item B<--warning-*>

Threshold warning.
Can be: 'interference-power', 'interference-util' (%).

=item B<--critical-*>

Threshold critical.
Can be: 'interference-power', 'interference-util' (%).

=item B<--filter-name>

Filter AP name (can be a regexp).

=item B<--filter-channel>

Filter Channel (can be a regexp). Example: --filter-channel='0\.3'

=back

=cut
