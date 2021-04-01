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

package network::fortinet::fortiauthenticator::snmp::mode::disklog;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'disk', type => 0, skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{disk} = [
        { label => 'space-usage-prct', nlabel => 'disk.log.space.usage.percentage', set => {
                key_values => [ { name => 'prct_used' } ],
                output_template => 'Log disk space used: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
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

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_facSysLogDiskUsage = '.1.3.6.1.4.1.12356.113.1.6.0';
    my $result = $options{snmp}->get_leef(oids => [$oid_facSysLogDiskUsage], nothing_quit => 1);

    $self->{disk} = {
        prct_used => $result->{$oid_facSysLogDiskUsage}
    }
}

1;

__END__

=head1 MODE

Check log disk usage.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'space-usage-prct' (%).

=back

=cut
