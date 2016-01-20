#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package storage::fujitsu::eternus::dx::ssh::mode::volumestats;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::values;

my $maps_counters = {
    vol => { 
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
                key_values => [ { name => 'read_throughput' }, { name => 'display' } ],
                output_template => 'Read Traffic : %s %s/s', output_change_bytes => 2,
                perfdatas => [
                    { label => 'read_throughput', value => 'read_throughput_absolute', template => '%d',
                      unit => 'b/s', min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            },
        },
        '003_write-traffic'   => {
            set => {
                key_values => [ { name => 'write_throughput' }, { name => 'display' } ],
                output_template => 'Write Traffic : %s %s/s', output_change_bytes => 2,
                perfdatas => [
                    { label => 'write_throughput', value => 'write_throughput_absolute', template => '%d',
                      unit => 'b/s', min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            },
        },
        '004_read-response-time'   => {
            set => {
                key_values => [ { name => 'read_response_time' }, { name => 'display' } ],
                output_template => 'Read Response Time : %d ms',
                perfdatas => [
                    { label => 'read_response_time', value => 'read_response_time_absolute', template => '%d',
                      unit => 'ms', min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            },
        },
        '005_write-response-time'   => {
            set => {
                key_values => [ { name => 'write_response_time' }, { name => 'display' } ],
                output_template => 'Write Response Time : %d ms',
                perfdatas => [
                    { label => 'write_response_time', value => 'write_response_time_absolute', template => '%d',
                      unit => 'ms', min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            },
        },
        '006_read-processing-time'   => {
            set => {
                key_values => [ { name => 'read_processing_time' }, { name => 'display' } ],
                output_template => 'Read Processing Time : %d ms',
                perfdatas => [
                    { label => 'read_processing_time', value => 'read_processing_time_absolute', template => '%d',
                      unit => 'ms', min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            },
        },
       '007_write-processing-time'   => {
            set => {
                key_values => [ { name => 'write_processing_time' }, { name => 'display' } ],
                output_template => 'Write Processing Time : %d ms',
                perfdatas => [
                    { label => 'write_processing_time', value => 'write_processing_time_absolute', template => '%d',
                      unit => 'ms', min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            },
        },
        '008_read-cache-hit-rate'   => {
            set => {
                key_values => [ { name => 'read_cache_hit_rate' }, { name => 'display' } ],
                output_template => 'Read Cache Hit Rate : %d %%',
                perfdatas => [
                    { label => 'read_cache_hit_rate', value => 'read_cache_hit_rate_absolute', template => '%d',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            },
        },
        '009_write-cache-hit-rate'   => {
            set => {
                key_values => [ { name => 'write_cache_hit_rate' }, { name => 'display' } ],
                output_template => 'Write Cache Hit Rate : %d %%',
                perfdatas => [
                    { label => 'write_cache_hit_rate', value => 'write_cache_hit_rate_absolute', template => '%d',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display_absolute' },
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
                                  "command-options:s"       => { name => 'command_options', default => ' performance -type host-io' },
                                  "no-component:s"          => { name => 'no_component' },
                                  "filter-name:s"           => { name => 'filter_name' },
                                });
    $self->{no_components} = undef;
    
    foreach my $key (('vol')) {
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
    
    foreach my $key (('vol')) {
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
    if (scalar(keys %{$self->{vol}}) == 1) {
        $multiple = 0;
    }
    
    if ($multiple == 1) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'All Volumes are ok');
    }
    
    foreach my $id (sort keys %{$self->{vol}}) {
        my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
        my @exits = ();
        foreach (sort keys %{$maps_counters->{vol}}) {
            my $obj = $maps_counters->{vol}->{$_}->{obj};
            $obj->set(instance => $id);
        
            my ($value_check) = $obj->execute(values => $self->{vol}->{$id});

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

        $self->{output}->output_add(long_msg => "Volume '$self->{vol}->{$id}->{display}' $long_msg");
        my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
        if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => "Volume '$self->{vol}->{$id}->{display}' $short_msg"
                                        );
        }
        
        if ($multiple == 0) {
            $self->{output}->output_add(short_msg => "Volume '$self->{vol}->{$id}->{display}' $long_msg");
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
    
    #Volume                                 IOPS(IOPS)            Throughput(MB/s)      Response Time(msec.)   Processing Time(msec.)  Cache Hit Rate(%)
    #No.   Name                             Read     / Write      Read     / Write      Read     / Write       Read     / Write        Read     / Write    / Prefetch
    #----- -------------------------------- ---------- ---------- ---------- ---------- ---------- ----------  ---------- ----------   ---------- ---------- ----------
    #    1 VOL001                                 6621       5192        589        379      17055      12056       10025      10010           41         37         36
    #    2 VOL002                                 7791       6608        613        292      12148      11045       10005      10007           41         37         36
    
    $self->{vol} = {};
    my %template_label = (cache_hit_rate => { labels => ['read', 'write', 'prefetch'] });
    my @template_values = ();
    foreach (split /\n/, $stdout) {
        if (/^Volume/) {            
            while (/(\sIOPS|\sThroughput|\sResponse Time|\sProcessing Time|[^C]\sCache Hit Rate)/mgi) {
                my $value = lc(centreon::plugins::misc::trim($1));
                $value =~ s/ /_/g;
                
                my $labels = ['read', 'write'];
                if (defined($template_label{$value})) {
                    $labels = $template_label{$value}->{labels};
                }
                
                foreach (@{$labels}) {
                    push @template_values, { label => $_ . '_' . $value };
                }
            }
            next;
        }
        next if (/----|Name/i);
        my $value = centreon::plugins::misc::trim($_);
        my @matches = split /\s+/, $value;
            
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $matches[1] !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "Skipping  '" . $matches[1] . "': no matching filter name.");
            next;
        }
        
        my %counters = ();
        for (my $i = 0; $i < scalar(@template_values); $i++) {
            $counters{$template_values[$i]->{label}} = $matches[$i + 2];
        }
        $counters{read_throughput} *= 1000 * 1000 * 8 if (defined($counters{read_throughput}));
        $counters{write_throughput} *= 1000 * 1000 * 8 if (defined($counters{write_throughput}));
        
        $self->{vol}->{$matches[0]} = { display => $matches[1],
                                %counters
                              };
    }
    
    if (scalar(keys %{$self->{vol}}) <= 0) {
        $self->{output}->output_add(severity => defined($self->{no_components}) ? $self->{no_components} : 'unknown',
                                    short_msg => 'No components are checked.');
    }
}

1;

__END__

=head1 MODE

Check Volume statistics.

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

Command options (Default: 'performance -type host-io').

=item B<--no-component>

Set the threshold where no components (Default: 'unknown' returns).

=item B<--filter-name>

Filter by name (regexp can be used).

=item B<--warning-*>

Threshold warning.
Can be: 'read-iops', 'write-iops', 'read-traffic', 'write-traffic',
'read-response-time', 'write-response-time', 'read-processing-time', 'write-processing-time',
'read-cache-hit-rate', 'write-cache-hit-rate'.

=item B<--critical-*>

Threshold critical.
Can be: 'read-iops', 'write-iops', 'read-traffic', 'write-traffic',
'read-response-time', 'write-response-time', 'read-processing-time', 'write-processing-time',
'read-cache-hit-rate', 'write-cache-hit-rate'.

=back

=cut
