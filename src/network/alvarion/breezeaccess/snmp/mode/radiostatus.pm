#
# Copyright 2018 Centreon (http://www.centreon.com/)
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

package network::alvarion::breezeaccess::snmp::mode::radiostatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub custom_badframes_calc {
    my ($self, %options) = @_;

    my $delta_value = $options{new_datas}->{$self->{instance} . '_bad_frames'} - $options{old_datas}->{$self->{instance} . '_bad_frames'};
    my $delta_total = $options{new_datas}->{$self->{instance} . '_total_frames'} - $options{old_datas}->{$self->{instance} . '_total_frames'};

    $self->{result_values}->{bad_prct} = 0;
    if ($delta_total > 0) {
        $self->{result_values}->{bad_prct} = $delta_value * 100 / $delta_total;
    }
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
    ];
    $self->{maps_counters}->{global} = [
        { label => 'rx-snr', nlabel => 'rx.signal.noise.ratio.dbm', set => {
                key_values => [ { name => 'rx_snr' } ],
                output_template => 'Average signal to noise ratio: %s Dbm',
                perfdatas => [
                    { label => 'rx_snr', value => 'rx_snr', template => '%s', min => 0 , unit => 'Dbm' },
                ],
            }
        },
        { label => 'rx-power', nlabel => 'rx.signal.strength.dbm', set => {
                key_values => [ { name => 'rx_power' } ],
                output_template => 'Received signal strength: %s Dbm',
                perfdatas => [
                    { label => 'rx_power', value => 'rx_power', template => '%s', min => 0 , unit => 'Dbm' },
                ],
            }
        },
        { label => 'bad-frames', nlabel => 'frames.bad.percentage', set => {
                key_values => [ { name => 'total_frames', diff => 1 }, { name => 'bad_frames', diff => 1 } ],
                closure_custom_calc => $self->can('custom_badframes_calc'),
                output_template => 'Bad frames: %.2f %%', output_use => 'bad_prct', threshold_use => 'bad_prct',
                perfdatas => [
                    { label => 'bad_frames', value => 'bad_prct', template => '%.2f', min => 0, max => 100,
                      unit => '%' },
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
    });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;
    
    my $oid_brzaccVLAverageReceiveSNR = '.1.3.6.1.4.1.12394.1.1.11.1.0';
    my $oid_brzaccVLAverageReceiveRSSI = '.1.3.6.1.4.1.12394.1.1.11.10.0';
    my $oid_brzaccVLRecievedBadFrames = '.1.3.6.1.4.1.12394.1.1.11.2.3.7.0';
    my $oid_brzaccVLTotalRecievedDataFrames = '.1.3.6.1.4.1.12394.1.1.11.2.3.6.0';
    my $result = $options{snmp}->get_leef(oids => [
        $oid_brzaccVLAverageReceiveSNR, $oid_brzaccVLAverageReceiveRSSI, $oid_brzaccVLRecievedBadFrames,
        $oid_brzaccVLTotalRecievedDataFrames
    ], nothing_quit => 1);

    $self->{cache_name} = "alvarion_breezeaccess_" . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
    
    $self->{global} = { 
        rx_snr => $result->{$oid_brzaccVLAverageReceiveSNR},
        rx_power => $result->{$oid_brzaccVLAverageReceiveRSSI},
        bad_frames => $result->{$oid_brzaccVLRecievedBadFrames},
        total_frames => $result->{$oid_brzaccVLTotalRecievedDataFrames},
    };
}

1;

__END__

=head1 MODE

Check radio signal

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='rx-power'

=item B<--warning-*>

Threshold warning.
Can be: 'rx-snr', 'rx-power', 'bad-frames'.

=item B<--critical-*>

Threshold critical.
Can be: 'rx-snr', 'rx-power', 'bad-frames'.

=back

=cut
