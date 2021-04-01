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
                    { label => 'read_iops', value => 'read_iops', template => '%d',
                      unit => 'iops', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'write-iops', nlabel => 'port.io.write.usage.iops', set => {
                key_values => [ { name => 'write_iops' }, { name => 'display' } ],
                output_template => 'Write IOPS : %d',
                perfdatas => [
                    { label => 'write_iops', value => 'write_iops', template => '%d',
                      unit => 'iops', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'read-traffic', nlabel => 'port.traffic.read.usage.bitspersecond', set => {
                key_values => [ { name => 'read_traffic' }, { name => 'display' } ],
                output_template => 'Read Traffic : %s %s/s', output_change_bytes => 2,
                perfdatas => [
                    { label => 'read_traffic', value => 'read_traffic', template => '%d',
                      unit => 'b/s', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'write-traffic', nlabel => 'port.traffic.write.usage.bitspersecond', set => {
                key_values => [ { name => 'write_traffic' }, { name => 'display' } ],
                output_template => 'Write Traffic : %s %s/s', output_change_bytes => 2,
                perfdatas => [
                    { label => 'write_traffic', value => 'write_traffic', template => '%d',
                      unit => 'b/s', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
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
        "hostname:s"              => { name => 'hostname' },
        "ssh-option:s@"           => { name => 'ssh_option' },
        "ssh-path:s"              => { name => 'ssh_path' },
        "ssh-command:s"           => { name => 'ssh_command', default => 'ssh' },
        "timeout:s"               => { name => 'timeout', default => 30 },
        "command:s"               => { name => 'command', default => 'show' },
        "command-path:s"          => { name => 'command_path' },
        "command-options:s"       => { name => 'command_options', default => 'performance -type port' },
        "filter-name:s"           => { name => 'filter_name' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (defined($self->{option_results}->{hostname}) && $self->{option_results}->{hostname} ne '') {
        $self->{option_results}->{remote} = 1;
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $stdout = centreon::plugins::misc::execute(
        output => $self->{output},
        options => $self->{option_results},
        ssh_pipe => 1,
        command => $self->{option_results}->{command},
        command_path => $self->{option_results}->{command_path},
        command_options => $self->{option_results}->{command_options}
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

=over 8

=item B<--hostname>

Hostname to query.

=item B<--ssh-option>

Specify multiple options like the user (example: --ssh-option='-l=centreon-engine' --ssh-option='-p=52').

=item B<--ssh-path>

Specify ssh command path (default: none)

=item B<--ssh-command>

Specify ssh command (default: 'ssh'). Useful to use 'plink'.

=item B<--timeout>

Timeout in seconds for the command (Default: 30).

=item B<--command>

Command to get information (Default: 'show').
Can be changed if you have output in a file.

=item B<--command-path>

Command path (Default: none).

=item B<--command-options>

Command options (Default: 'performance -type port').

=item B<--filter-name>

Filter by name (regexp can be used).

=item B<--warning-*>

Threshold warning.
Can be: 'read-iops', 'write-iops', 'read-traffic', 'write-traffic'.

=item B<--critical-*>

Threshold critical.
Can be: 'read-iops', 'write-iops', 'read-traffic', 'write-traffic'.

=back

=cut
