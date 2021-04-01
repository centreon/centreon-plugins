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

package centreon::common::ingrian::snmp::mode::connections;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, message_separator => ' - ' }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'total', set => {
                key_values => [ { name => 'naeTotalTotalConnections', diff => 1 } ],
                output_template => 'Total Connections : %s',
                perfdatas => [
                    { label => 'total', value => 'naeTotalTotalConnections', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'ssl', set => {
                key_values => [ { name => 'naeTotalSSLConnections', diff => 1 } ],
                output_template => 'Total SSL Connections : %s',
                perfdatas => [
                    { label => 'total_ssl', value => 'naeTotalSSLConnections', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'non-ssl', set => {
                key_values => [ { name => 'naeTotalNonSSLConnections', diff => 1 } ],
                output_template => 'Total non-SSL Connections : %s',
                perfdatas => [
                    { label => 'total_non_ssl', value => 'naeTotalNonSSLConnections', template => '%s', min => 0 },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                });
    
    return $self;
}

my $mapping = {
    naeTotalTotalConnections    => { oid => '.1.3.6.1.4.1.5595.3.5.1.4' },
    naeTotalNonSSLConnections   => { oid => '.1.3.6.1.4.1.5595.3.5.1.5.4' },
    naeTotalSSLConnections      => { oid => '.1.3.6.1.4.1.5595.3.5.1.6.4' },
};
my $oid_naeConnectionStats = '.1.3.6.1.4.1.5595.3.5';

sub manage_selection {
    my ($self, %options) = @_;

    
    my $snmp_result = $options{snmp}->get_table(oid => $oid_naeConnectionStats,
                                                nothing_quit => 1);
    my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => '0');
    $self->{global} = { %$result };
    
    $self->{cache_name} = "ingrian_" . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' . 
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check connections.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'total', 'ssl', 'non-ssl'.

=item B<--critical-*>

Threshold critical.
Can be: 'total', 'ssl', 'non-ssl'.

=back

=cut
