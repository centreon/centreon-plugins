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

package network::juniper::common::screenos::snmp::mode::sessions;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, message_separator => ' - ' },
    ];
    $self->{maps_counters}->{global} = [
        { label => 'usage', set => {
                key_values => [ { name => 'prct_used' }, { name => 'total' }, { name => 'used' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { label => 'sessions', value => 'used', template => '%s', 
                      min => 0, max => 'total', threshold_total => 'total', cast_int => 1 },
                ],
            }
        },
        { label => 'failed', set => {
                key_values => [ { name => 'failed', per_second => 1 } ],
                output_template => 'Failed sessions : %.2f/s', output_error_template => "Failed sessions : %s",
                perfdatas => [
                    { label => 'sessions_failed', template => '%.2f', unit => '/s', min => 0 },
                ],
            }
        }
    ];
}

sub custom_usage_output {
    my ($self, %options) = @_;
 
    return sprintf(
        "%.2f%% of the sessions limit reached (%d of max. %d)", 
        $self->{result_values}->{prct_used}, 
        $self->{result_values}->{used}, 
        $self->{result_values}->{total}
    );
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_nsResSessAllocate = '.1.3.6.1.4.1.3224.16.3.2.0';
    my $oid_nsResSessMaxium = '.1.3.6.1.4.1.3224.16.3.3.0';
    my $oid_nsResSessFailed = '.1.3.6.1.4.1.3224.16.3.4.0';
    
    my $result = $options{snmp}->get_leef(oids => [$oid_nsResSessAllocate, $oid_nsResSessMaxium, $oid_nsResSessFailed], nothing_quit => 1);
    $self->{global} = {
        total => $result->{$oid_nsResSessMaxium}, 
        used => $result->{$oid_nsResSessAllocate}, 
        failed => $result->{$oid_nsResSessFailed},
        prct_used => $result->{$oid_nsResSessAllocate} * 100 / $result->{$oid_nsResSessMaxium},
    };

    $self->{cache_name} = "juniper_" . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check Juniper sessions usage and failed sessions (NETSCREEN-RESOURCE-MIB).

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^usage$'

=item B<--warning-*>

Threshold warning.
Can be: 'usage' (%), 'failed'.

=item B<--critical-*>

Threshold critical.
Can be: 'usage' (%), 'failed'.

=back

=cut
