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

package apps::inin::mediaserver::snmp::mode::audioengineusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'engine', type => 1, cb_prefix_output => 'prefix_engine_output', message_multiple => 'All audio engines are ok' }
    ];
    
    $self->{maps_counters}->{engine} = [
        { label => 'avg-load', set => {
                key_values => [ { name => 'i3MsAudioEngineAverageLoad' }, { name => 'display' } ],
                output_template => 'Average Load : %s',
                perfdatas => [
                    { label => 'load_avg', value => 'i3MsAudioEngineAverageLoad', template => '%s', 
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'elem-count', set => {
                key_values => [ { name => 'i3MsAudioEngineElementCount' }, { name => 'display' } ],
                output_template => 'Total active graph elements : %s',
                perfdatas => [
                    { label => 'elem_count', value => 'i3MsAudioEngineElementCount', template => '%s', 
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
                                  "filter-location:s"   => { name => 'filter_location' },
                                });
    
    return $self;
}

sub prefix_engine_output {
    my ($self, %options) = @_;
    
    return "Audio Engine '" . $options{instance_value}->{display} . "' ";
}

my $mapping = {
    i3MsAudioEngineLocation     => { oid => '.1.3.6.1.4.1.2793.8227.2.1.1.4' },
    i3MsAudioEngineAverageLoad  => { oid => '.1.3.6.1.4.1.2793.8227.2.1.1.6' },
    i3MsAudioEngineElementCount => { oid => '.1.3.6.1.4.1.2793.8227.2.1.1.8' },
};

my $oid_i3MsAudioEngineInfoTableEntry = '.1.3.6.1.4.1.2793.8227.2.1.1';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{engine} = {};
    my $snmp_result = $options{snmp}->get_table(oid => $oid_i3MsAudioEngineInfoTableEntry,
                                                nothing_quit => 1);


    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{i3MsAudioEngineLocation}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        if (defined($self->{option_results}->{filter_location}) && $self->{option_results}->{filter_location} ne '' &&
            $result->{i3MsAudioEngineLocation} !~ /$self->{option_results}->{filter_location}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{i3MsAudioEngineLocation} . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{engine}->{$instance} = { display => $result->{i3MsAudioEngineLocation}, 
            %$result
        };
    }
    
    if (scalar(keys %{$self->{engine}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No audio engine found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check audio engine usage.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^elem-count$'

=item B<--filter-location>

Filter location name (can be a regexp).

=item B<--warning-*>

Threshold warning.
Can be: 'elem-count', 'avg-load'.

=item B<--critical-*>

Threshold critical.
Can be: 'elem-count', 'avg-load'.

=back

=cut
