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

package storage::panzura::snmp::mode::ratios;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'dedup', nlabel => 'system.deduplication.ratio.count', set => {
                key_values => [ { name => 'dedup' }, ],
                output_template => 'Deduplication ratio : %.2f',
                perfdatas => [
                    { value => 'dedup', template => '%.2f', min => 0 },
                ],
            }
        },
        { label => 'comp', nlabel => 'system.compression.ratio.count', set => {
                key_values => [ { name => 'comp' }, ],
                output_template => 'Compression ratio : %.2f',
                perfdatas => [
                    { value => 'comp', template => '%.2f', min => 0 },
                ],
            }
        },
        { label => 'save', nlabel => 'system.save.ratio.count', set => {
                key_values => [ { name => 'save' }, ],
                output_template => 'Save ratio : %.2f',
                perfdatas => [
                    { value => 'save', template => '%.2f', min => 0 },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_dedupRatio = '.1.3.6.1.4.1.32853.1.3.1.5.1.0';
    my $oid_compRatio = '.1.3.6.1.4.1.32853.1.3.1.6.1.0';
    my $oid_saveRatio = '.1.3.6.1.4.1.32853.1.3.1.7.1.0';

    my $snmp_result = $options{snmp}->get_leef(
        oids => [$oid_dedupRatio, $oid_compRatio, $oid_saveRatio], 
        nothing_quit => 1
    );
    
    $self->{global} = {
        dedup => defined($snmp_result->{$oid_dedupRatio}) ? $snmp_result->{$oid_dedupRatio} / 100 : undef,
        comp  => defined($snmp_result->{$oid_compRatio}) ? $snmp_result->{$oid_compRatio} / 100 : undef,
        save  => defined($snmp_result->{$oid_saveRatio}) ? $snmp_result->{$oid_saveRatio} / 100 : undef,
    };
}

1;

__END__

=head1 MODE

Check deduplication, compression and save ratios (panzura-systemext).

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'dedup', 'comp', 'save'.

=item B<--critical-*>

Threshold critical.
Can be: 'dedup', 'comp', 'save'.

=back

=cut
    
