#
# Copyright 2017 Centreon (http://www.centreon.com/)
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

package network::paloalto::snmp::mode::panorama;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my $thresholds = {
    panorama => [
        ['^connected$', 'OK'],
        ['^not-connected$', 'CRITICAL'],
    ],
};

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                "threshold-overload:s@"  => { name => 'threshold_overload' },
                                "exclude:s"              => { name => 'exclude' },
                                });

    return $self;
}

sub check_threshold_overload {
    my ($self, %options) = @_;
    
    $self->{overload_th} = {};
    foreach my $val (@{$self->{option_results}->{threshold_overload}}) {
        if ($val !~ /^(.*?),(.*)$/) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload option '" . $val . "'.");
            $self->{output}->option_exit();
        }
        my ($section, $status, $filter) = ('panorama', $1, $2);
        if ($self->{output}->is_litteral_status(status => $status) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload status '" . $val . "'.");
            $self->{output}->option_exit();
        }
        $self->{overload_th}->{$section} = [] if (!defined($self->{overload_th}->{$section}));
        push @{$self->{overload_th}->{$section}}, {filter => $filter, status => $status};
    }
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    $self->check_threshold_overload();
}

sub check_exclude {
    my ($self, %options) = @_;

    if (defined($self->{option_results}->{exclude}) && $self->{option_results}->{exclude} =~ /(^|\s|,)${options{section}}[^,]*#\Q$options{instance}\E#/) {
        $self->{output}->output_add(long_msg => sprintf("Skipping $options{instance} instance."));
        return 1;
    }
    return 0;
}

sub get_severity {
    my ($self, %options) = @_;
    my $status = 'UNKNOWN'; # default 
    
    if (defined($self->{overload_th}->{$options{section}})) {
        foreach (@{$self->{overload_th}->{$options{section}}}) {            
            if ($options{value} =~ /$_->{filter}/i) {
                $status = $_->{status};
                return $status;
            }
        }
    }
    foreach (@{$thresholds->{$options{section}}}) {           
        if ($options{value} =~ /$$_[0]/i) {
            $status = $$_[1];
            return $status;
        }
    }
    
    return $status;
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    my $oid_panMgmtPanoramaConnected = '.1.3.6.1.4.1.25461.2.1.2.4.1.0';
    my $oid_panMgmtPanorama2Connected = '.1.3.6.1.4.1.25461.2.1.2.4.2.0';
    my $result = $self->{snmp}->get_leef(oids => [$oid_panMgmtPanoramaConnected, $oid_panMgmtPanorama2Connected], nothing_quit => 1);
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'Panorama connection statuses are ok.');
    if (!$self->check_exclude(section => 'panorama', instance => 1)) {
        my $exit = $self->get_severity(section => 'panorama', value => $result->{$oid_panMgmtPanoramaConnected});
        $self->{output}->output_add(long_msg => sprintf("panorama '1' connection status is %s",
                                                         $result->{$oid_panMgmtPanoramaConnected}));
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("panorama '1' connection status is %s",
                                                             $result->{$oid_panMgmtPanoramaConnected}));
        }
    }
    if (!$self->check_exclude(section => 'panorama', instance => 2)) {
        my $exit = $self->get_severity(section => 'panorama', value => $result->{$oid_panMgmtPanorama2Connected});
        $self->{output}->output_add(long_msg => sprintf("panorama '2' connection status is %s",
                                                         $result->{$oid_panMgmtPanorama2Connected}));
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("panorama '2' connection status is %s",
                                                             $result->{$oid_panMgmtPanorama2Connected}));
        }
    }
    

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check panorama connection status.

=over 8

=item B<--threshold-overload>

Set to overload default threshold value.
Example: --threshold-overload='warning,(not-connected)'

=item B<--exclude>

Exclude some parts (comma seperated list)
Can also exclude specific instance: --exclude=panorama#2#

=back

=cut
    
