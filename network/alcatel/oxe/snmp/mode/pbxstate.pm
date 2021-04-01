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

package network::alcatel::oxe::snmp::mode::pbxstate;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my $thresholds = {
    state => [
        ['indeterminate', 'UNKNOWN'],
        ['critical', 'CRITICAL'],
        ['major', 'CRITICAL'],
        ['minor', 'WARNING'],
        ['warning', 'WARNING'],
        ['normal', 'OK'],
    ],
};
my %map_state = (
    0 => 'indeterminate',
    1 => 'critical',
    2 => 'major',
    3 => 'minor',
    4 => 'warning',
    5 => 'normal',
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

    # Seems to have a bug to get '.0'
    my $oid_pbxState = '.1.3.6.1.4.1.637.64.4400.1.2.0';
    my $oid_pbxState_buggy = '.1.3.6.1.4.1.637.64.4400.1.2';
    my $result = $self->{snmp}->get_leef(oids => [$oid_pbxState, $oid_pbxState_buggy], nothing_quit => 1);
    
    my $pbx_state = defined($result->{$oid_pbxState}) ? $map_state{$result->{$oid_pbxState}} : $map_state{$result->{$oid_pbxState_buggy}};
    my $exit = $self->get_severity(section => 'state', value => $pbx_state);
    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("PBX State is '%s'", $pbx_state));
 
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

Check PBX State.

=over 8

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='state,CRITICAL,^(?!(normal)$)'

=back

=cut
