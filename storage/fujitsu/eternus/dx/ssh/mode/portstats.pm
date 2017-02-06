#
# Copyright 2017 Centreon (http://www.centreon.com/)
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

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::values;

my $maps_counters = {
    port => { 
        '000_read-iops'   => {
            set => {
                key_values => [ { name => 'read_iops' }, { name => 'display' } ],
                output_template => 'Read IOPS : %d',
                perfdatas => [
                    { label => 'read_iops', value => 'read_iops_absolute', template => '%d',
                      unit => 'iops', min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            },
        },
        '001_write-iops'   => {
            set => {
                key_values => [ { name => 'write_iops' }, { name => 'display' } ],
                output_template => 'Write IOPS : %d',
                perfdatas => [
                    { label => 'write_iops', value => 'write_iops_absolute', template => '%d',
                      unit => 'iops', min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            },
        },
        '002_read-traffic'   => {
            set => {
                key_values => [ { name => 'read_traffic' }, { name => 'display' } ],
                output_template => 'Read Traffic : %s %s/s', output_change_bytes => 2,
                perfdatas => [
                    { label => 'read_traffic', value => 'read_traffic_absolute', template => '%d',
                      unit => 'b/s', min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            },
        },
        '003_write-traffic'   => {
            set => {
                key_values => [ { name => 'write_traffic' }, { name => 'display' } ],
                output_template => 'Write Traffic : %s %s/s', output_change_bytes => 2,
                perfdatas => [
                    { label => 'write_traffic', value => 'write_traffic_absolute', template => '%d',
                      unit => 'b/s', min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            },
        },
    }
};

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "hostname:s"              => { name => 'hostname' },
                                  "ssh-option:s@"           => { name => 'ssh_option' },
                                  "ssh-path:s"              => { name => 'ssh_path' },
                                  "ssh-command:s"           => { name => 'ssh_command', default => 'ssh' },
                                  "timeout:s"               => { name => 'timeout', default => 30 },
                                  "command:s"               => { name => 'command', default => 'show' },
                                  "command-path:s"          => { name => 'command_path' },
                                  "command-options:s"       => { name => 'command_options', default => 'performance -type port' },
                                  "no-component:s"          => { name => 'no_component' },
                                  "filter-name:s"           => { name => 'filter_name' },
                                });
    $self->{no_components} = undef;
    
    foreach my $key (('port')) {
        foreach (keys %{$maps_counters->{$key}}) {
            my ($id, $name) = split /_/;
            if (!defined($maps_counters->{$key}->{$_}->{threshold}) || $maps_counters->{$key}->{$_}->{threshold} != 0) {
                $options{options}->add_options(arguments => {
                                                            'warning-' . $name . ':s'    => { name => 'warning-' . $name },
                                                            'critical-' . $name . ':s'    => { name => 'critical-' . $name },
                                               });
            }
            $maps_counters->{$key}->{$_}->{obj} = centreon::plugins::values->new(output => $self->{output}, perfdata => $self->{perfdata},
                                                      label => $name);
            $maps_counters->{$key}->{$_}->{obj}->set(%{$maps_counters->{$key}->{$_}->{set}});
        }
    }
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (defined($self->{option_results}->{hostname}) && $self->{option_results}->{hostname} ne '') {
        $self->{option_results}->{remote} = 1;
    }
    
    foreach my $key (('port')) {
        foreach (keys %{$maps_counters->{$key}}) {
            $maps_counters->{$key}->{$_}->{obj}->init(option_results => $self->{option_results});
        }
    }

    if (defined($self->{option_results}->{no_component})) {
        if ($self->{option_results}->{no_component} ne '') {
            $self->{no_components} = $self->{option_results}->{no_component};
        } else {
            $self->{no_components} = 'critical';
        }
    }
}

sub run {
    my ($self, %options) = @_;

    $self->manage_selection();
    
    my $multiple = 1;
    if (scalar(keys %{$self->{port}}) == 1) {
        $multiple = 0;
    }
    
    if ($multiple == 1) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'All Ports are ok');
    }
    
    foreach my $id (sort keys %{$self->{port}}) {
        my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
        my @exits = ();
        foreach (sort keys %{$maps_counters->{port}}) {
            my $obj = $maps_counters->{port}->{$_}->{obj};
            $obj->set(instance => $id);
        
            my ($value_check) = $obj->execute(values => $self->{port}->{$id});

            if ($value_check != 0) {
                $long_msg .= $long_msg_append . $obj->output_error();
                $long_msg_append = ', ';
                next;
            }
            my $exit2 = $obj->threshold_check();
            push @exits, $exit2;

            my $output = $obj->output();
            $long_msg .= $long_msg_append . $output;
            $long_msg_append = ', ';
            
            if (!$self->{output}->is_status(litteral => 1, value => $exit2, compare => 'ok')) {
                $short_msg .= $short_msg_append . $output;
                $short_msg_append = ', ';
            }
            
            $obj->perfdata(extra_instance => $multiple);
        }

        $self->{output}->output_add(long_msg => "Port '$self->{port}->{$id}->{display}' $long_msg");
        my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
        if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => "Port '$self->{port}->{$id}->{display}' $short_msg"
                                        );
        }
        
        if ($multiple == 0) {
            $self->{output}->output_add(short_msg => "Port '$self->{port}->{$id}->{display}' $long_msg");
        }
    }
     
    $self->{output}->display();
    $self->{output}->exit();
}

sub manage_selection {
    my ($self, %options) = @_;

    my $stdout = centreon::plugins::misc::execute(output => $self->{output},
                                                  options => $self->{option_results},
                                                  ssh_pipe => 1,
                                                  command => $self->{option_results}->{command},
                                                  command_path => $self->{option_results}->{command_path},
                                                  command_options => $self->{option_results}->{command_options});
    
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
        
        $self->{port}->{$port_name} = { display => $port_name,
                                        read_iops => $port_read_iops, write_iops => $port_write_iops,
                                        read_traffic => $port_read_traffic * 1000 * 1000 * 8,
                                        write_traffic => $port_write_traffic * 1000 * 1000 * 8 
                                       };
    }
    
    if (scalar(keys %{$self->{port}}) <= 0) {
        $self->{output}->output_add(severity => defined($self->{no_components}) ? $self->{no_components} : 'unknown',
                                    short_msg => 'No components are checked.');
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

=item B<--no-component>

Set the threshold where no components (Default: 'unknown' returns).

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
