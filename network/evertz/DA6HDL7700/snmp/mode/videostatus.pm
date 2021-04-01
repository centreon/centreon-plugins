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

package network::evertz::DA6HDL7700::snmp::mode::videostatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'video', type => 1, cb_prefix_output => 'prefix_video_output', message_multiple => 'All videos are ok' },
    ];
    
    $self->{maps_counters}->{video} = [
        { label => 'video-status', threshold => 0, set => {
                key_values => [ { name => 'videoLocked' }, { name => 'detectedVideoStandard' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'), 
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub custom_status_output {
    my ($self, %options) = @_;
    my $msg = 'is : ' . $self->{result_values}->{video_locked};

    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{video_locked} = $options{new_datas}->{$self->{instance} . '_videoLocked'};
    $self->{result_values}->{detected_video_standard} = $options{new_datas}->{$self->{instance} . '_detectedVideoStandard'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                  "warning-video-status:s"  => { name => 'warning_video_status', default => '' },
                                  "critical-video-status:s" => { name => 'critical_video_status', default => '%{video_locked} =~ /notLocked/i' },
                                });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    
    $self->change_macros(macros => ['warning_video_status', 'critical_video_status']);
}

sub prefix_video_output {
    my ($self, %options) = @_;
    
    return "Video '" . $options{instance_value}->{display} . "' ";
}

my %map_video_standard = (1 => 'vs15G', 2 => 'vs540M', 3 => 'vs360M',
    4 => 'vs270M', 5 => 'vs177M', 6 => 'vs143', 7 => 'none'
);
my %map_video_locked = (1 => 'locked', 2 => 'notlocked');

my $mapping = {
    videoLocked             => { oid => '.1.3.6.1.4.1.6827.10.131.4.1.1.1', map => \%map_video_locked },
    detectedVideoStandard   => { oid => '.1.3.6.1.4.1.6827.10.131.4.1.1.2', map => \%map_video_standard },
};

my $oid_videoMonitorEntry = '.1.3.6.1.4.1.6827.10.131.4.1.1';

sub manage_selection {
    my ($self, %options) = @_;
    
    my $snmp_result = $options{snmp}->get_table(oid => $oid_videoMonitorEntry,
                                                nothing_quit => 1);
    $self->{video} = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{videoLocked}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        
        $self->{video}->{$instance} = { 
            display => $instance, %$result
        };
    }
}

1;

__END__

=head1 MODE

Check video stream status.

=over 8

=item B<--warning-video-status>

Set warning threshold for device connection status.
Can used special variables like: %{video_locked}, %{display}

=item B<--critical-video-status>

Set critical threshold for device connection status (Default: '%{video_locked} =~ /notLocked/i').
Can used special variables like: %{video_locked}, %{display}

=back

=cut
