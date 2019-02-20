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

package apps::protocols::snmp::mode::responsetime;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Time::HiRes qw(gettimeofday tv_interval);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_output' },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'rt', set => {
                key_values => [ { name => 'rt' } ],
                output_template => 'rt %.3fs',
                perfdatas => [
                    { label => 'rt', value => 'rt_absolute', template => '%.3f', min => 0, unit => 's' },
                ],
            }
        },
        { label => 'pl', set => {
                key_values => [ { name => 'pl' } ],
                output_template => 'lost %s%%',
                perfdatas => [
                    { label => 'pl', value => 'pl_absolute', template => '%s', min => 0, max => 100, unit => '%' },
                ],
            }
        },
    ];
}

sub prefix_output {
    my ($self, %options) = @_;

    return "SNMP Agent ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments => {
        "timeout:s" => { name => 'timeout' },
        "packets:s" => { name => 'packets' },
    });
                                
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{option_timeout} = 5;
    $self->{option_packets} = 5;
    if (defined($self->{option_results}->{timeout}) && $self->{option_results}->{timeout} =~ /(\d+)/) {
        $self->{option_timeout} = $1;
    }
    if (defined($self->{option_results}->{packets}) && $self->{option_results}->{packets} =~ /(\d+)/) {
        $self->{option_packets} = $1;
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    $options{snmp}->set_snmp_connect_params(Timeout => $self->{option_timeout} * (10**6));
    $options{snmp}->set_snmp_connect_params(Retries => 0);
    $options{snmp}->connect();
    
    my $sysDescr = ".1.3.6.1.2.1.1.1.0";
    my $total_time_elapsed = 0;
    my $total_packet_lost = 0;
    for (my $i = 0; $i < $self->{option_packets}; $i++) {
        my $timing0 = [gettimeofday];
        my $return = $options{snmp}->get_leef(oids => [$sysDescr], nothing_quit => 0, dont_quit => 1);
        my $timeelapsed = tv_interval($timing0, [gettimeofday]);
        
        $total_time_elapsed += $timeelapsed;
        $total_packet_lost++ if (!defined($return));
    }

    $self->{global} = {
        rt => $total_time_elapsed / $self->{option_packets},
        pl => int($total_packet_lost * 100 / $self->{option_packets}),
    };
}
    
1;

__END__

=head1 MODE

Check SNMP agent response time.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example : --filter-counters='rt'

=item B<--timeout>

Set timeout in seconds (Default: 5).

=item B<--packets>

Number of packets to send (Default: 5).

=item B<--warning-rt>

Response time threshold warning in milliseconds

=item B<--critical-rt>

Response time threshold critical in milliseconds

=item B<--warning-pl>

Packets lost threshold warning in %

=item B<--critical-pl>

Packets lost threshold critical in %

=back

=cut
