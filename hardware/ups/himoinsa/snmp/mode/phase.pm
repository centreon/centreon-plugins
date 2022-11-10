#
# Copyright 2022 Centreon (http://www.centreon.com/)
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

package hardware::ups::himoinsa::snmp::mode::phase;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;


sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
    ];
        
    $self->{maps_counters}->{global} = [
        { label => 'phase1', nlabel => 'phase1.current.ampere', set => {
                key_values => [ { name => 'ph1AmpConm' } ],
                output_template => '1 phase current: %s A',
                perfdatas => [
                    { value => 'ph1AmpConm', template => '%s', unit => 'A', },
                ]
            }
        },
        { label => 'phase2', nlabel => 'phase2.current.ampere', set => {
                key_values => [ { name => 'ph2AmpConm' } ],
                output_template => '2 phase current: %s A',
                perfdatas => [
                    { value => 'ph2AmpConm', template => '%s', unit => 'A', },
                ]
            }
        },
        { label => 'phase3', nlabel => 'phase3.current.ampere', set => {
                key_values => [ { name => 'ph3AmpConm' } ],
                output_template => '3 phase current: %s A',
                perfdatas => [
                    { value => 'ph3AmpConm', template => '%s', unit => 'A', },
                ]
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

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    
}

my $mapping = {
    ph1AmpConm         => { oid => '.1.3.6.1.4.1.41809.1.49.1.15' },
    ph2AmpConm         => { oid => '.1.3.6.1.4.1.41809.1.49.1.15' },
    ph3AmpConm         => { oid => '.1.3.6.1.4.1.41809.1.49.1.16' }
};
my $oid_conmutationmeasuresEntry = '.1.3.6.1.4.1.41809.1.49.1';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_conmutationmeasuresEntry,
        start => $mapping->{ph1AmpConm}->{oid},
        end => $mapping->{ph3AmpConm}->{oid}
    );

    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{ph1AmpConm}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        $self->{global} = { %$result };

        if (scalar(keys %{$self->{global}}) <= 0) {
            $self->{output}->add_option_msg(short_msg => "No entry found.");
            $self->{output}->option_exit();
        }
    }
}

1;

__END__

=head1 MODE

Check phases current.

=over 8

=item B<--warning-*>

Warning threshold in amperes.

Where '*' can be: 'phase1', 'phase2", 'phase3'

=item B<--critical-*>

Critical threshold in amperes.

Where '*' can be: 'phase1', 'phase2', 'phase3'

=back

=cut
