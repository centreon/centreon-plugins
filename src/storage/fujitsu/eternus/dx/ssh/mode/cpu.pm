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

package storage::fujitsu::eternus::dx::ssh::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;

sub prefix_cpu_output {
    my ($self, %options) = @_;
    
    return "CPU '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'cpu', type => 1, cb_prefix_output => 'prefix_cpu_output', message_multiple => 'All CPUs are ok' }
    ];
    
    $self->{maps_counters}->{cpu} = [
        { label => 'usage', nlabel => 'cpu.utilization.percentage', set => {
                key_values => [ { name => 'usage' }, { name => 'display' } ],
                output_template => 'Usage : %d %%',
                perfdatas => [
                    { label => 'cpu', template => '%d',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];
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
        command_options => "performance -type cm\n",
        ssh_pipe => 1
    );

    # Can have 4 columns also.
    
    #Location              Busy Rate(%) Copy Residual Quantity(MB)
    #--------------------- ------------ --------------------------
    #CM#0                            56                   55191552
    #CM#0 CPU Core#0                 66                          -
    #CM#0 CPU Core#1                 46                          -
    #CM#1                            52                   55191552
    #CM#1 CPU Core#0                 62                          -
    #CM#1 CPU Core#1                 42                          -
    
    $self->{cpu} = {};
    foreach (split /\n/, $stdout) {
        next if ($_ !~ /^(CM.*?)\s{2,}(\d+)\s+\S+/);
        my ($cpu_name, $cpu_value) = ($1, $2);

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $cpu_name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $cpu_name . "': no matching filter name.");
            next;
        }

        $self->{cpu}->{$cpu_name} = { display => $cpu_name, usage => $cpu_value };
    }

    if (scalar(keys %{$self->{cpu}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No component found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check CPUs usage.

Command used: show performance -type cm

=over 8

=item B<--filter-name>

Filter by name (regexp can be used).

=item B<--warning-usage>

Warning threshold (in percent).

=item B<--critical-usage>

Critical threshold (in percent).

=back

=cut
