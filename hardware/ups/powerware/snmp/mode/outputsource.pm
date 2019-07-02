#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package hardware::ups::powerware::snmp::mode::outputsource;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my $oid_xupsOutputSource = '.1.3.6.1.4.1.534.1.4.5.0';

my $thresholds = {
    osource => [
        ['normal', 'OK'],
        ['.*', 'CRITICAL'],
    ],
};

my %map_osource_status = (
    1 => 'other',
    2 => 'none',
    3 => 'normal',
    4 => 'bypass',
    5 => 'battery',
    6 => 'booster', 
    7 => 'reducer', 
    8 => 'parallelCapacity', 
    9 => 'parallelRedundant', 
    10 => 'highEfficiencyMode', 
    11 => 'maintenanceBypass', 
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
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
        if ($val !~ /^(.*?),(.*)$/) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload option '" . $val . "'.");
            $self->{output}->option_exit();
        }
        my ($section, $status, $filter) = ('osource', $1, $2);
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
    
    my $result = $self->{snmp}->get_leef(oids => [$oid_xupsOutputSource], nothing_quit => 1);
    my $exit = $self->get_severity(section => 'osource', value => $map_osource_status{$result->{$oid_xupsOutputSource}});
    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("Output source status is %s",
                                                     $map_osource_status{$result->{$oid_xupsOutputSource}}));

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

Check output source status (XUPS-MIB).

=over 8

=item B<--threshold-overload>

Set to overload default threshold values (syntax: status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='WARNING,bypass|booster'

=back

=cut
