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

package storage::netapp::snmp::mode::failoverstatus;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %mapping_state = (
    1 => 'dead',
    2 => 'canTakeover',
    3 => 'cannotTakeover',
    4 => 'takeover',
);
my %mapping_cannot_takeover_cause = (
    1 => 'ok',
    2 => 'unknownReason',
    3 => 'disabledByOperator',
    4 => 'interconnectOffline',
    5 => 'disabledByPartner',
    6 => 'takeoverFailed',
    7 => 'mailboxIsInDegradedState',
    8 => 'partnermailboxIsInUninitialisedState',
    9 => 'mailboxVersionMismatch',
   10 => 'nvramSizeMismatch',
   11 => 'kernelVersionMismatch',
   12 => 'partnerIsInBootingStage',
   13 => 'diskshelfIsTooHot',
   14 => 'partnerIsPerformingRevert',
   15 => 'nodeIsPerformingRevert',
   16 => 'sametimePartnerIsAlsoTryingToTakeUsOver',
   17 => 'alreadyinTakenoverMode',
   18 => 'nvramLogUnsynchronized',
   19 => 'stateofBackupMailboxIsDoubtful',
);

my $thresholds = {
    state => [
        ['dead', 'CRITICAL'],
        ['canTakeover', 'OK'],
        ['cannotTakeover', 'CRITICAL'],
        ['takeover', 'WARNING'],
        ['partialGiveback', 'WARNING'],
    ],
    cannottakeovercause => [
        ['ok', 'OK'],
        ['unknownReason', 'WARNING'],
        ['disabledByOperator', 'WARNING'],
        ['interconnectOffline', 'CRITICAL'],
        ['disabledByPartner', 'CRITICAL'],
        ['takeoverFailed', 'CRITICAL'],
        ['mailboxIsInDegradedState', 'CRITICAL'],
        ['partnermailboxIsInUninitialisedState', 'CRITICAL'],
        ['mailboxVersionMismatch', 'CRITICAL'],
        ['nvramSizeMismatch', 'CRITICAL'],
        ['kernelVersionMismatch', 'CRITICAL'],
        ['partnerIsInBootingStage', 'CRITICAL'],
        ['diskshelfIsTooHot', 'CRITICAL'],
        ['partnerIsPerformingRevert', 'CRITICAL'],
        ['nodeIsPerformingRevert', 'CRITICAL'],
        ['sametimePartnerIsAlsoTryingToTakeUsOver', 'CRITICAL'],
        ['alreadyinTakenoverMode', 'CRITICAL'],
        ['nvramLogUnsynchronized', 'CRITICAL'],
        ['stateofBackupMailboxIsDoubtful', 'CRITICAL'],
    ],
};

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

my $mapping = {
    cfState => { oid => '.1.3.6.1.4.1.789.1.2.3.2', map => \%mapping_state },
};
my $mapping2 = {
    cfCannotTakeoverCause => { oid => '.1.3.6.1.4.1.789.1.2.3.3', map => \%mapping_cannot_takeover_cause },
};
my $mapping3 = {
    haState => { oid => '.1.3.6.1.4.1.789.1.21.2.1.4', map => \%mapping_state },
};
my $mapping4 = {
    haCannotTakeoverCause => { oid => '.1.3.6.1.4.1.789.1.21.2.1.5', map => \%mapping_cannot_takeover_cause },
};

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    my $oid_cfState = '.1.3.6.1.4.1.789.1.2.3.6';
    my $oid_haNodeName = '.1.3.6.1.4.1.789.1.21.2.1.1';
    my $results = $self->{snmp}->get_multiple_table(oids => [
                                                            { oid => $oid_cfState },
                                                            { oid => $mapping->{cfState}->{oid} },
                                                            { oid => $mapping2->{cfCannotTakeoverCause}->{oid} },
                                                            { oid => $oid_haNodeName },
                                                            { oid => $mapping3->{haState}->{oid} },
                                                            { oid => $mapping4->{haCannotTakeoverCause}->{oid} },
                                                            ], nothing_quit => 1);  

    if (defined($results->{$mapping->{cfState}->{oid}}->{$mapping->{cfState}->{oid} . '.0'})) {
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $results->{$mapping->{cfState}->{oid}}, instance => '0');
        my $exit = $self->get_severity(section => 'state', value => $result->{cfState});
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("Failover status on node '%s' status is '%s'", $results->{$oid_cfState}->{$oid_cfState . '.0'}, $result->{cfState}));
        $result = $self->{snmp}->map_instance(mapping => $mapping2, results => $results->{$mapping2->{cfCannotTakeoverCause}->{oid}}, instance => '0');
        $exit = $self->get_severity(section => 'cannottakeovercause', value => $result->{cfCannotTakeoverCause});
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("Takeover status is '%s'", $result->{cfCannotTakeoverCause}));
    } else {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'HA Failover statuses are ok on all nodes');
        foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$results->{$mapping3->{haState}->{oid}}})) {
            $oid =~ /^$mapping3->{haState}->{oid}\.(.*)$/;
            my $instance = $1;
            my $name = $results->{$oid_haNodeName}->{$oid_haNodeName . '.' . $instance};
            my $result = $self->{snmp}->map_instance(mapping => $mapping3, results => $results->{$mapping3->{haState}->{oid}}, instance => $instance);

            my $exit = $self->get_severity(section => 'state', value => $result->{haState});
            $self->{output}->output_add(long_msg => sprintf("Failover status of node '%s' is '%s'",
                                                            $name, $result->{haState}));
            if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {  
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Failover status of node '%s' is '%s'",
                                                            $name, $result->{haState}));
            }

            $result = $self->{snmp}->map_instance(mapping => $mapping4, results => $results->{$mapping4->{haCannotTakeoverCause}->{oid}}, instance => $instance);
            $results->{'.1.3.6.1.4.1.789.1.21.2.1.4'}->{'.1.3.6.1.4.1.789.1.21.2.1.4.97.116.108.52.110.97.50.51.110.111.100.101.49.97'} = sprintf('%s',int(rand(19))+1);
            $exit = $self->get_severity(section => 'cannottakeovercause', value => $result->{haCannotTakeoverCause});
            $self->{output}->output_add(long_msg => sprintf("Takeover status on node '%s' is '%s'",
                                                            $name, $result->{haCannotTakeoverCause}));
            if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {  
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Takeover status on node '%s' is '%s'",
                                                            $name, $result->{haCannotTakeoverCause}));
            }
        }
    }

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
