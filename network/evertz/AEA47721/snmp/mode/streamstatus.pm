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

package network::evertz::AEA47721::snmp::mode::streamstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'video', type => 1, cb_prefix_output => 'prefix_video_output', message_multiple => 'All videos are ok' },
        { name => 'audio', type => 1, cb_prefix_output => 'prefix_audio_output', message_multiple => 'All audios are ok' },
    ];
    
    $self->{maps_counters}->{video} = [
        { label => 'video-status', threshold => 0, set => {
                key_values => [ { name => 'videoInputStatus' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'), 
                closure_custom_calc_extra_options => { output_label => 'Status', name_status => 'videoInputStatus' },
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
    $self->{maps_counters}->{audio} = [
        { label => 'audio-status', threshold => 0, set => {
                key_values => [ { name => 'videoInputGroupStatus' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'), 
                closure_custom_calc_extra_options => { output_label => 'Status', name_status => 'videoInputGroupStatus' },
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub custom_status_output {
    my ($self, %options) = @_;
    my $msg = $self->{result_values}->{output_label} . ' : ' . $self->{result_values}->{status};

    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{output_label} = $options{extra_options}->{output_label};
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{name_status}};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                  "warning-audio-status:s"  => { name => 'warning_audio_status', default => '' },
                                  "critical-audio-status:s" => { name => 'critical_audio_status', default => '%{status} =~ /loss/i' },
                                  "warning-video-status:s"  => { name => 'warning_video_status', default => '' },
                                  "critical-video-status:s" => { name => 'critical_video_status', default => '%{status} =~ /loss|unknown/i' },
                                });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    
    $self->change_macros(macros => ['warning_audio_status', 'critical_audio_status', 'warning_video_status', 'critical_video_status']);
}

sub prefix_video_output {
    my ($self, %options) = @_;
    
    return "Video '" . $options{instance_value}->{display} . "' ";
}

sub prefix_audio_output {
    my ($self, %options) = @_;
    
    return "Audio '" . $options{instance_value}->{display} . "' ";
}

my %map_video_input_status = (1 => 'loss', 2 => 'unknown', 3 => 'p270', 4 => 'n270', 5 => 'sdtiP270',
    6 => 'sdtiN270', 7 => 'std1080ix60', 8 => 'std1080ix5994', 9 => 'std1080ix50', 10 => 'std1035ix60',
    11 => 'std1035ix5994', 12 => 'std1080ix48', 13 => 'std1080ix4796', 14 => 'std1080px24',
    15 => 'std1080px2398', 16 => 'std1080px25', 17 => 'std1080px30', 18 => 'std1080px2997',
    19 => 'std720px60', 20 => 'std720px5994',
);
my %map_video_input_group_status = (1 => 'free', 2 => 'used', 3 => 'clean', 4 => 'loss');

my $mapping = {
    videoInputStatus        => { oid => '.1.3.6.1.4.1.6827.10.138.4.1.1.1', map => \%map_video_input_status },
};
my $mapping2 = {
    videoInputGroupStatus   => { oid => '.1.3.6.1.4.1.6827.10.138.4.2.1.2', map => \%map_video_input_group_status },
};

my $oid_monitorEntry = '.1.3.6.1.4.1.6827.10.138.4.1.1';
my $oid_audioMonitorEntry = '.1.3.6.1.4.1.6827.10.138.4.2.1';

sub manage_selection {
    my ($self, %options) = @_;
    
    my $snmp_result = $options{snmp}->get_multiple_table(oids => [ { oid => $oid_monitorEntry },
                                                                   { oid => $oid_audioMonitorEntry },
                                                                 ],
                                                         nothing_quit => 1);
    $self->{video} = {};
    foreach my $oid (keys %{$snmp_result->{ $oid_monitorEntry }}) {
        next if ($oid !~ /^$mapping->{videoInputStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result->{ $oid_monitorEntry }, instance => $instance);
        
        $self->{video}->{$instance} = { 
            display => $instance, %$result
        };
    }
    
    $self->{audio} = {};
    foreach my $oid (keys %{$snmp_result->{ $oid_audioMonitorEntry }}) {
        next if ($oid !~ /^$mapping2->{videoInputGroupStatus}->{oid}\.(.*?)\.(.*?)$/);
        my ($audio_group_id, $instance) = ($1, $2);
        my $result = $options{snmp}->map_instance(mapping => $mapping2, results => $snmp_result->{ $oid_audioMonitorEntry }, instance => $audio_group_id . '.' . $instance);
        
        $self->{audio}->{$audio_group_id . '.' . $instance} = { 
            display => $instance . '.' . $audio_group_id, %$result
        };
    }
}

1;

__END__

=head1 MODE

Check video/audio stream status.

=over 8

=item B<--warning-audio-status>

Set warning threshold for device status.
Can used special variables like: %{status}, %{display}

=item B<--critical-audio-status>

Set critical threshold for device status (Default: '%{status} =~ /loss/i').
Can used special variables like: %{status}, %{display}

=item B<--warning-video-status>

Set warning threshold for device connection status.
Can used special variables like: %{status}, %{display}

=item B<--critical-video-status>

Set critical threshold for device connection status (Default: '%{status} =~ /loss|unknown/i').
Can used special variables like: %{status}, %{display}

=back

=cut
