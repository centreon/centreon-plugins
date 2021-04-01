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

package hardware::telephony::avaya::cm::snmp::mode::calls;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'total-lasthour', nlabel => 'calls.total.lasthour.count', set => {
                key_values => [ { name => 'avCmListMeasCallRateTotalNumCallsCompLstHr' } ],
                output_template => 'total calls last hour: %s',
                perfdatas => [
                    { value => 'avCmListMeasCallRateTotalNumCallsCompLstHr', template => '%s', min => 0 },
                ],
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
    });
    
    return $self;
}

my $mapping = {
    avCmListMeasCallRateTotalNumCallsCompLstHr => { oid => '.1.3.6.1.4.1.6889.2.73.8.1.145.3' },
};

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{snmp}->get_leef(
        oids => [ map($_->{oid} . '.0', values(%$mapping)) ],
        nothing_quit => 1
    );
    my $result = $options{snmp}->map_instance(mapping => $mapping, results => $results, instance => 0);

    $self->{global} = { %$result };
}

1;

__END__

=head1 MODE

Check calls usage.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'total-lasthour'.

=back

=cut
