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

package apps::virtualization::ovirt::mode::cpuhost;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'host', type => 1, cb_prefix_output => 'prefix_output', message_multiple => 'All hosts are ok' },
    ];

    $self->{maps_counters}->{host} = [
        { label => 'cpu-user', nlabel => 'host.cpu.user.utilization.percentage', set => {
                key_values => [ { name => 'user' }, { name => 'display' } ],
                output_template => 'user: %.2f %%',
                perfdatas => [
                    { value => 'user', template => '%.2f', unit => '%', 
                      min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'cpu-system', nlabel => 'host.cpu.system.utilization.percentage', set => {
                key_values => [ { name => 'system' }, { name => 'display' } ],
                output_template => 'system: %.2f %%',
                perfdatas => [
                    { value => 'system', template => '%.2f', unit => '%', 
                      min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub prefix_output {
    my ($self, %options) = @_;

    return "Host '" . $options{instance_value}->{display} . "' CPU utilization ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "filter-name:s" => { name => 'filter_name' },
        "filter-id:s"   => { name => 'filter_id' },
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{host} = {};

    if (!defined($self->{cache_hosts})) {
        $self->{cache_hosts} = $options{custom}->cache_hosts();
    }

    foreach my $host (@{$self->{cache_hosts}}) {
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne ''
            && $host->{name} !~ /$self->{option_results}->{filter_name}/);
        next if (defined($self->{option_results}->{filter_id}) && $self->{option_results}->{filter_id} ne ''
            && $host->{id} !~ /$self->{option_results}->{filter_id}/);

        my $stats = $options{custom}->get_host_statistics(id => $host->{id});

        foreach my $stat (@{$stats}) {
            next if ($stat->{name} !~ /^cpu\.current\..*/);
            
            $self->{host}->{$host->{id}}->{display} = $host->{name};
            $self->{host}->{$host->{id}}->{user} = $stat->{values}->{value}[0]->{datum} if ($stat->{name} =~ /^cpu.current.user$/);
            $self->{host}->{$host->{id}}->{system} = $stat->{values}->{value}[0]->{datum} if ($stat->{name} =~ /^cpu.current.system$/);
        }
    }
    
    if (scalar(keys %{$self->{host}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No hosts found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check host cpu utilization.

=over 8

=item B<--filter-name>

Filter host name (Can be a regexp).

=item B<--filter-id>

Filter host id (Can be a regexp).

=item B<--warning-*>

Threshold warning.
Can be: 'host-cpu-user-utilization-percentage', 'host-cpu-system-utilization-percentage'.

=item B<--critical-*>

Threshold critical.
Can be: 'host-cpu-user-utilization-percentage', 'host-cpu-system-utilization-percentage'.

=back

=cut
