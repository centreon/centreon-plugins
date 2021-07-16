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

package network::dell::nseries::snmp::mode::ntp;

use base qw(snmp_standard::mode::ntp);

use strict;
use warnings;
use Date::Parse;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'oid:s'  => { name => 'oid', default => '.1.3.6.1.4.1.674.10895.5000.2.6132.1.1.42.1.2.0,.1.3.6.1.4.1.674.10895.5000.2.6132.1.1.42.1.1.0' }
    });

    return $self;
}

sub get_target_time {
    my ($self, %options) = @_;

    my $oid_date = $self->{option_results}->{oid};
    my $result = $options{snmp}->get_leef(oids => [ split(/,/, $oid_date) ], nothing_quit => 1);

    my $result_concat;
    foreach (split(/,/, $oid_date)) {
        if (!defined($result_concat)) {
            $result_concat = $result->{$_};
        } else {
            $result_concat .= ' ' . $result->{$_};
        }
    }

    my $epoch = Date::Parse::str2time($result_concat);
    return $self->get_from_epoch(date => $epoch);
}

1;
