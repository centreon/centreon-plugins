#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package hardware::ats::apc::mode::source;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %selected_source = (
    1 => 'sourceA',
    2 => 'sourceB',
);

my %redundancy_states = (
    1 => ['atsRedundancyLost', 'CRITICAL'],
    2 => ['atsFullyRedundant', 'OK'],
);

my %sourceA_states = (
    1 => ['fail', 'CRITICAL'],
    2 => ['ok', 'OK'],
);

my %sourceB_states = (
    1 => ['fail', 'CRITICAL'],
    2 => ['ok', 'OK'],
);

my %phaseSync_states = (
    1 => ['inSync', 'OK'],
    2 => ['outOfSync', 'CRITICAL'],
);


sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    my $oid_atsStatusSelectedSource = '.1.3.6.1.4.1.318.1.1.8.5.1.2.0';
    my $oid_atsStatusRedundancyStatus = '.1.3.6.1.4.1.318.1.1.8.5.1.3.0';
    my $oid_atsStatusSourceAStatus = '.1.3.6.1.4.1.318.1.1.8.5.1.12.0';
    my $oid_atsStatusSourceBStatus = '.1.3.6.1.4.1.318.1.1.8.5.1.13.0';
    my $oid_atsStatusPhaseSyncStatus = '.1.3.6.1.4.1.318.1.1.8.5.1.14.0';

    $self->{results} = $self->{snmp}->get_leef(oids => [$oid_atsStatusSelectedSource, $oid_atsStatusSelectedSource, $oid_atsStatusRedundancyStatus, $oid_atsStatusSourceAStatus, $oid_atsStatusSourceBStatus, $oid_atsStatusPhaseSyncStatus], nothing_quit => 1);

    my $exit1 = ${$redundancy_states{$self->{results}->{$oid_atsStatusRedundancyStatus}}}[1];
    my $exit2 = ${$sourceA_states{$self->{results}->{$oid_atsStatusSourceAStatus}}}[1];
    my $exit3 = ${$sourceB_states{$self->{results}->{$oid_atsStatusSourceBStatus}}}[1];
    my $exit4 = ${$phaseSync_states{$self->{results}->{$oid_atsStatusPhaseSyncStatus}}}[1];

    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'All sources are ok');

    $self->{output}->output_add(long_msg => sprintf("Selected source is '%s'", $selected_source{$self->{results}->{$oid_atsStatusSelectedSource}}));
    $self->{output}->output_add(long_msg => sprintf("Redundancy state is '%s'", ${$redundancy_states{$self->{results}->{$oid_atsStatusRedundancyStatus}}}[0]));
    $self->{output}->output_add(long_msg => sprintf("Source A state is '%s'", ${$sourceA_states{$self->{results}->{$oid_atsStatusSourceAStatus}}}[0]));
    $self->{output}->output_add(long_msg => sprintf("Source B state is '%s'", ${$sourceB_states{$self->{results}->{$oid_atsStatusSourceBStatus}}}[0]));
    $self->{output}->output_add(long_msg => sprintf("Phase sync is '%s'", ${$phaseSync_states{$self->{results}->{$oid_atsStatusPhaseSyncStatus}}}[0]));
    
    if (!$self->{output}->is_status(value => $exit1, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $exit1,
                                short_msg => sprintf("Redundancy state is '%s'", ${$redundancy_states{$self->{results}->{$oid_atsStatusRedundancyStatus}}}[0]));
    }
    if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $exit2,
                                short_msg => sprintf("Source A state is '%s'", ${$sourceA_states{$self->{results}->{$oid_atsStatusSourceAStatus}}}[0]));
    }
    if (!$self->{output}->is_status(value => $exit3, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $exit3,
                                short_msg => sprintf("Source B state is '%s'", ${$sourceB_states{$self->{results}->{$oid_atsStatusSourceBStatus}}}[0]));
    }
    if (!$self->{output}->is_status(value => $exit4, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $exit4,
                                short_msg => sprintf("Phase sync is '%s'", ${$phaseSync_states{$self->{results}->{$oid_atsStatusPhaseSyncStatus}}}[0]));
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check APC ATS sources.

=over 8

=back

=cut
    
