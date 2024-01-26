#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package storage::fujitsu::eternus::dx::ssh::mode::portstats;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'port', type => 1, cb_prefix_output => 'prefix_port_output', message_multiple => 'All ports are ok' }
    ];

    $self->{maps_counters}->{port} = [
        { label => 'read-iops', nlabel => 'port.io.read.usage.iops', set => {
                key_values => [ { name => 'read_iops' }, { name => 'display' } ],
                output_template => 'Read IOPS : %d',
                perfdatas => [
                    { label => 'read_iops', template => '%d',
                      unit => 'iops', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'write-iops', nlabel => 'port.io.write.usage.iops', set => {
                key_values => [ { name => 'write_iops' }, { name => 'display' } ],
                output_template => 'Write IOPS : %d',
                perfdatas => [
                    { label => 'write_iops', template => '%d',
                      unit => 'iops', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'read-traffic', nlabel => 'port.traffic.read.usage.bitspersecond', set => {
                key_values => [ { name => 'read_traffic' }, { name => 'display' } ],
                output_template => 'Read Traffic : %s %s/s', output_change_bytes => 2,
                perfdatas => [
                    { label => 'read_traffic', template => '%d',
                      unit => 'b/s', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'write-traffic', nlabel => 'port.traffic.write.usage.bitspersecond', set => {
                key_values => [ { name => 'write_traffic' }, { name => 'display' } ],
                output_template => 'Write Traffic : %s %s/s', output_change_bytes => 2,
                perfdatas => [
                    { label => 'write_traffic', template => '%d',
                      unit => 'b/s', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];
}

sub prefix_port_output {
    my ($self, %options) = @_;
    
    return "Port '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-name:s' => { name => 'filter_name' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($stdout) = $options{custom}->execute_command(
        command => 'show',
        command_options => "performance -type port\n",
        ssh_pipe => 1
    );
    
    #Location            IOPS(IOPS)               Throughput(MB/s)
    #                    Read      / Write        Read      / Write
    #------------------- ----------- ------------ ----------- -----------
    #CM#0 CA#0 Port#0           6621         5192         589         379
    #CM#1 CA#1 Port#1           7791         6608         613         292
    
    $self->{port} = {};
    foreach (split /\n/, $stdout) {
        next if ($_ !~ /^(.*?)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)$/);
        my ($port_name, $port_read_iops, $port_write_iops, $port_read_traffic, $port_write_traffic) = ($1, $2, $3, $4, $5);

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $port_name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "Skipping  '" . $port_name . "': no matching filter name.");
            next;
        }

        $self->{port}->{$port_name} = {
            display => $port_name,
            read_iops => $port_read_iops, write_iops => $port_write_iops,
            read_traffic => $port_read_traffic * 1000 * 1000 * 8,
            write_traffic => $port_write_traffic * 1000 * 1000 * 8 
        };
    }

    if (scalar(keys %{$self->{port}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No port found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check Port statistics.

Command used: show performance -type port

=over 8

=item B<--filter-name>

Filter by name (regexp can be used).

=item B<--warning-*>

Warning threshold.
Can be: 'read-iops', 'write-iops', 'read-traffic', 'write-traffic'.

=item B<--critical-*>

Critical threshold.
Can be: 'read-iops', 'write-iops', 'read-traffic', 'write-traffic'.

=back

=cut
