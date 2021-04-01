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

package network::paloalto::snmp::mode::clusterstatus;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my $oid_panSysHAState = '.1.3.6.1.4.1.25461.2.1.2.1.11.0'; # '.0' to have the mode
my $oid_panSysHAPeerState = '.1.3.6.1.4.1.25461.2.1.2.1.12.0';
my $oid_panSysHAMode = '.1.3.6.1.4.1.25461.2.1.2.1.13.0';

my $thresholds = {
    peer => [
    ],
    current => [
    ],
};

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                "threshold-overload:s@"  => { name => 'threshold_overload' },
                                });

    return $self;
}

sub check_threshold_overload {
    my ($self, %options) = @_;
    
    $self->{overload_th} = {};
    foreach my $val (@{$self->{option_results}->{threshold_overload}}) {
        if ($val !~ /^(.*?),(.*?),(.*)$/) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload option '" . $val . "'.");
            $self->{output}->option_exit();
        }
        my ($section, $status, $filter) = ($1, $2, $3);
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

sub get_severity {
    my ($self, %options) = @_;
    my $status = 'OK'; # default 
    
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
    
    $self->{result} = $self->{snmp}->get_leef(oids => [ $oid_panSysHAState, $oid_panSysHAPeerState, $oid_panSysHAMode ], 
                                              nothing_quit => 1);
    
    # Check if mode cluster
    my $ha_mode = $self->{result}->{$oid_panSysHAMode};
    $self->{output}->output_add(long_msg => 'High availabily mode is ' . $ha_mode . '.');
    if ($ha_mode =~ /disabled/i) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => sprintf("No cluster configuration (standalone mode)."));
    } else {
        if ($ha_mode =~ /active-active/i) {
            $thresholds = {
                peer => [
                    ['^active$', 'OK'],
                    ['^passive$', 'CRITICAL'],
                ],
                current => [
                    ['^active$', 'OK'],
                    ['^passive$', 'CRITICAL'],
                ],
            };
        }
        
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => sprintf("Cluster status is ok [member: %s] [peer: %s]",
                                        $self->{result}->{$oid_panSysHAState},
                                        $self->{result}->{$oid_panSysHAPeerState}));
        
        $self->{output}->output_add(long_msg => sprintf("current high-availability state is %s",
                                                         $self->{result}->{$oid_panSysHAState}));
        my $exit = $self->get_severity(section => 'current', value => $self->{result}->{$oid_panSysHAState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("current high-availability state is %s",
                                                         $self->{result}->{$oid_panSysHAState}));
        }
        
        $self->{output}->output_add(long_msg => sprintf("peer high-availability state is %s",
                                                         $self->{result}->{$oid_panSysHAPeerState}));
        $exit = $self->get_severity(section => 'peer', value => $self->{result}->{$oid_panSysHAPeerState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("peer high-availability state is %s",
                                                         $self->{result}->{$oid_panSysHAPeerState}));
        }
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check cluster status.

=over 8

=item B<--threshold-overload>

Set to overload default threshold value.
Example: --threshold-overload='peer,critical,active' --threshold-overload='current,critical,passive' 

=back

=cut
