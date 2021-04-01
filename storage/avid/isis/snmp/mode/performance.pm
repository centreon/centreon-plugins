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

package storage::avid::isis::snmp::mode::performance;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_client_perfdata {
    my ($self, %options) = @_;
    
    $self->{output}->perfdata_add(label => 'active_clients',
                                  value => $self->{result_values}->{active},
                                  unit => 'clients',
                                  min => 0,
                                  max => $self->{result_values}->{maximum});
}

sub custom_client_threshold {
    my ($self, %options) = @_;

    my ($exit, $threshold_value);
    $threshold_value = defined($self->{instance_mode}->{option_results}->{percent}) ? $self->{result_values}->{prct_active} : $self->{result_values}->{active} ;
    $exit = $self->{perfdata}->threshold_check(value => $threshold_value,
                                               threshold => [ { label => 'critical-' . $self->{label}, exit_litteral => 'critical' },
                                                              { label => 'warning-' . $self->{label}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_client_output {
    my ($self, %options) = @_;

    my $msg = sprintf("Active clients: %d/%d (%.2f%%)", 
                    $self->{result_values}->{active}, $self->{result_values}->{maximum}, $self->{result_values}->{prct_active});
    return $msg;
}

sub custom_client_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{active} = $options{new_datas}->{$self->{instance} . '_ActiveClientCount'};
    $self->{result_values}->{maximum} = $options{new_datas}->{$self->{instance} . '_MaximumClientCount'};
    $self->{result_values}->{prct_active} = ($self->{result_values}->{maximum} != 0) ? $self->{result_values}->{active} * 100 / $self->{result_values}->{maximum} : 0;

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'active-clients', set => {
                key_values => [ { name => 'ActiveClientCount' }, { name => 'MaximumClientCount' } ],
                closure_custom_calc => $self->can('custom_client_calc'),
                closure_custom_output => $self->can('custom_client_output'),
                closure_custom_threshold_check => $self->can('custom_client_threshold'),
                closure_custom_perfdata => $self->can('custom_client_perfdata'),
            }
        },
        { label => 'open-files', set => {
                key_values => [ { name => 'OpenFiles' } ],
                output_template => 'Open files: %s files',
                perfdatas => [
                    { label => 'open_files', value => 'OpenFiles',
                      template => '%s', min => 0, unit => 'files' },
                ],
            }
        },
        { label => 'processing-speed', set => {
                key_values => [ { name => 'MessagesPerSecond' } ],
                output_template => 'Message processing speed: %s messages/s',
                perfdatas => [
                    { label => 'processing_speed', value => 'MessagesPerSecond',
                      template => '%s', min => 0, unit => 'messages/s' },
                ],
            }
        },
        { label => 'read-throughput', set => {
                key_values => [ { name => 'ReadMegabytesPerSecond' } ],
                output_template => 'Read throughput: %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'read_throughput', value => 'ReadMegabytesPerSecond',
                      template => '%s', min => 0, unit => 'B/s' },
                ],
            }
        },
        { label => 'write-throughput', set => {
                key_values => [ { name => 'WriteMegabytesPerSecond' } ],
                output_template => 'Write throughput: %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'write_throughput', value => 'WriteMegabytesPerSecond',
                      template => '%s', min => 0, unit => 'B/s' },
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
        "percent"   => { name => 'percent' },
    });

    return $self;
}

my $oid_ReadMegabytesPerSecond = '.1.3.6.1.4.1.526.20.3.2.0';
my $oid_WriteMegabytesPerSecond = '.1.3.6.1.4.1.526.20.3.3.0';
my $oid_MessagesPerSecond = '.1.3.6.1.4.1.526.20.3.4.0';
my $oid_OpenFiles = '.1.3.6.1.4.1.526.20.3.5.0';
my $oid_ActiveClientCount = '.1.3.6.1.4.1.526.20.3.6.0';
my $oid_MaximumClientCount = '.1.3.6.1.4.1.526.20.3.7.0';

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{snmp}->get_leef(oids => [ $oid_ReadMegabytesPerSecond, $oid_WriteMegabytesPerSecond,
                                                     $oid_MessagesPerSecond, $oid_OpenFiles,
                                                     $oid_ActiveClientCount, $oid_MaximumClientCount ], 
                                               nothing_quit => 1);
    
    $self->{global} = {};

    $self->{global} = { 
        ReadMegabytesPerSecond => $results->{$oid_ReadMegabytesPerSecond} * 1024 * 1024,
        WriteMegabytesPerSecond => $results->{$oid_WriteMegabytesPerSecond} * 1024 * 1024,
        MessagesPerSecond => $results->{$oid_MessagesPerSecond},
        OpenFiles => $results->{$oid_OpenFiles},
        ActiveClientCount => $results->{$oid_ActiveClientCount},
        MaximumClientCount => $results->{$oid_MaximumClientCount},
    };
}

1;

__END__

=head1 MODE

Check client performances.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'active-clients' (counter or %), 'open-files',
'processing-speed', 'read-throughput', 'write-throughput'.

=item B<--critical-*>

Threshold critical.
Can be: 'active-clients' (counter or %), 'open-files',
'processing-speed', 'read-throughput', 'write-throughput'.

=item B<--percent>

Set this option if you want to use percent on active clients thresholds.

=back

=cut
