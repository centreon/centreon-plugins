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

package hardware::server::fujitsu::snmp::mode::components::fan;

use strict;
use warnings;

my $map_sc_fan_status = {
    1 => 'unknown', 2 => 'disabled', 3 => 'ok', 4 => 'fail',
    5 => 'prefailure-predicted', 6 => 'redundant-fan-failed',
    7 => 'not-manageable', 8 => 'not-present',
};
my $map_sc2_fan_status = {
    1 => 'unknown', 2 => 'disabled', 3 => 'ok', 4 => 'failed',
    5 => 'prefailure-predicted', 6 => 'redundant-fan-failed',
    7 => 'not-manageable', 8 => 'not-present',
};

my $mapping = {
    sc => {
        fanStatus          => { oid => '.1.3.6.1.4.1.231.2.10.2.2.5.2.2.1.3', map => $map_sc_fan_status },
        fanCurrentSpeed    => { oid => '.1.3.6.1.4.1.231.2.10.2.2.5.2.2.1.8' },
        fanDesignation     => { oid => '.1.3.6.1.4.1.231.2.10.2.2.5.2.2.1.16' },
    },
    sc2 => {
        sc2fanDesignation   => { oid => '.1.3.6.1.4.1.231.2.10.2.2.10.5.2.1.3' },
        sc2fanStatus        => { oid => '.1.3.6.1.4.1.231.2.10.2.2.10.5.2.1.5', map => $map_sc2_fan_status },
        sc2fanCurrentSpeed  => { oid => '.1.3.6.1.4.1.231.2.10.2.2.10.5.2.1.6' },
    },
};
my $oid_sc2Fans = '.1.3.6.1.4.1.231.2.10.2.2.10.5.2.1';
my $oid_fans = '.1.3.6.1.4.1.231.2.10.2.2.5.2.2.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_sc2Fans, end => $mapping->{sc2}->{sc2fanCurrentSpeed} }, { oid => $oid_fans };
}

sub check_fan {
    my ($self, %options) = @_;

    my ($exit, $warn, $crit, $checked);
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$options{entry}}})) {
        next if ($oid !~ /^$options{mapping}->{$options{status}}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $options{mapping}, results => $self->{results}->{$options{entry}}, instance => $instance);
        
        next if ($self->check_filter(section => 'fan', instance => $instance));
        next if ($result->{$options{status}} =~ /not-present|not-available/i &&
                 $self->absent_problem(section => 'fan', instance => $instance));
        
        $self->{components}->{fan}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("fan '%s' status is '%s' [instance = %s] [speed = %s]",
                                    $result->{$options{name}}, $result->{$options{status}}, $instance, $result->{$options{speed}}
                                    ));

        $exit = $self->get_severity(section => 'fan', value => $result->{$options{status}});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Fan '%s' status is '%s'", $result->{$options{name}}, $result->{$options{status}}));
        }
     
        next if (!defined($result->{$options{speed}}) || $result->{$options{speed}} == -1);
     
        ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'fan', instance => $instance, value => $result->{$options{speed}});
        
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Fan '%s' speed is %s rpm", $result->{$options{name}}, $result->{$options{speed}}));
        }
        $self->{output}->perfdata_add(
            label => 'fan', unit => 'rpm',
            nlabel => 'hardware.fan.speed.rpm',
            instances => $result->{$options{name}},
            value => $result->{$options{speed}},
            warning => $warn,
            critical => $crit,
            min => 0
        );
    }
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking fans");
    $self->{components}->{fan} = {name => 'fans', total => 0, skip => 0};
    return if ($self->check_filter(section => 'fan'));

    if (defined($self->{results}->{$oid_sc2Fans}) && scalar(keys %{$self->{results}->{$oid_sc2Fans}}) > 0) {
        check_fan($self, entry => $oid_sc2Fans, mapping => $mapping->{sc2}, name => 'sc2fanDesignation',
            speed => 'sc2fanCurrentSpeed', status => 'sc2fanStatus');
    } else {
        check_fan($self, entry => $oid_fans, mapping => $mapping->{sc}, name => 'fanDesignation', 
            speed => 'fanCurrentSpeed', status => 'fanStatus');
    }
}

1;
