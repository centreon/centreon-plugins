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

package network::citrix::netscaler::snmp::mode::hastate;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my $oid_haPeerState = '.1.3.6.1.4.1.5951.4.1.1.23.3.0';
my $oid_haCurState = '.1.3.6.1.4.1.5951.4.1.1.23.24.0';

my $thresholds = {
    peerstate => [
        ['standalone', 'OK'],
        ['primary', 'OK'],
        ['secondary', 'OK'],
        ['unknown', 'UNKNOWN'],
    ],
    hastate => [
        ['unknown', 'UNKNOWN'],
        ['down|partialFail|monitorFail|completeFail|partialFailSsl|routemonitorFail', 'CRITICAL'],
        ['init|up|monitorOk|dump|disabled', 'OK'],
    ],
};

my %map_hastate_status = (
    0 => 'unknown', 
    1 => 'init', 
    2 => 'down', 
    3 => 'up', 
    4 => 'partialFail', 
    5 => 'monitorFail', 
    6 => 'monitorOk', 
    7 => 'completeFail', 
    8 => 'dumb', 
    9 => 'disabled', 
    10 => 'partialFailSsl', 
    11 => 'routemonitorFail',
);

my %map_peerstate_status = (
    0 => 'standalone', 
    1 => 'primary', 
    2 => 'secondary', 
    3 => 'unknown', 
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "threshold-overload:s@"   => { name => 'threshold_overload' },
                                });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
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

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};
    
    $self->{result} = $self->{snmp}->get_leef(oids => [$oid_haPeerState, $oid_haCurState], nothing_quit => 1);
    
    my $exit = $self->get_severity(section => 'peerstate', value => $map_peerstate_status{$self->{result}->{$oid_haPeerState}});
    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("Peer State is '%s'", 
                                                     $map_peerstate_status{$self->{result}->{$oid_haPeerState}}
                                                    )
                                );
    $exit = $self->get_severity(section => 'hastate', value => $map_hastate_status{$self->{result}->{$oid_haCurState}});
    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("High Availibility Status is '%s'", 
                                                     $map_hastate_status{$self->{result}->{$oid_haCurState}}
                                                    )
                                );

    $self->{output}->display();
    $self->{output}->exit();
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

1;

__END__

=head1 MODE

Check High Availability Status.

=over 8

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,status,regexp).
It used before default thresholds (order stays).
Example: --threshold-overload='hastate,CRITICAL,^(?!(up)$)'

=back

=cut
    
