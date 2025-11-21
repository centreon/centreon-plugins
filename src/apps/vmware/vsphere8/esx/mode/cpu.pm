#
# Copyright 2025 Centreon (http://www.centreon.com/)
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

package apps::vmware::vsphere8::esx::mode::cpu;
use strict;
use warnings;
use base qw(apps::vmware::vsphere8::esx::mode);

sub new {
    my ($class, %options) = @_;

    my $self = $class->SUPER::new(package => __PACKAGE__, %options);

    $options{options}->add_options(
        arguments => {
            'add-contention' => { name => 'add_contention' },
            'add-demand'     => { name => 'add_demand' },
            'add-corecount'  => { name => 'add_corecount' }
        }
    );

    return $self;
}

sub check_options {
    my ($self, %options) = @_;

    $self->SUPER::check_options(%options);

    # If a threshold is given on contention, we enable the corresponding data collection
    if (grep {$_ =~ /contention/ && defined($self->{option_results}->{$_}) && $self->{option_results}->{$_} ne ''} keys %{$self->{option_results}}) {
        $self->{option_results}->{add_contention} = 1;
    }
    # If a threshold is given on demand, we enable the corresponding data collection
    if (grep {$_ =~ /demand/ && defined($self->{option_results}->{$_}) && $self->{option_results}->{$_} ne ''} keys %{$self->{option_results}}) {
        $self->{option_results}->{add_demand} = 1;
    }
    # If a threshold is given on corecount, we enable the corresponding data collection
    if (grep {$_ =~ /corecount/ && defined($self->{option_results}->{$_}) && $self->{option_results}->{$_} ne ''} keys %{$self->{option_results}}) {
        $self->{option_results}->{add_corecount} = 1;
    }
}

# Skip contention processing if there is no available data
sub skip_contention {
    my ($self, %options) = @_;

    return 0 if (defined($self->{cpu_contention})
        && ref($self->{cpu_contention}) eq 'HASH'
        && scalar(keys %{$self->{cpu_contention}}) > 0);

    return 1;
}

# Skip demand processing if there is no available data
sub skip_demand {
    my ($self, %options) = @_;

    return 0 if (defined($self->{cpu_demand})
        && ref($self->{cpu_demand}) eq 'HASH'
        && scalar(keys %{$self->{cpu_demand}}) > 0);

    return 1;
}

# Skip corecount processing if there is no available data
sub skip_corecount {
    my ($self, %options) = @_;

    return 0 if (defined($self->{cpu_corecount})
        && ref($self->{cpu_corecount}) eq 'HASH'
        && scalar(keys %{$self->{cpu_corecount}}) > 0);

    return 1;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'cpu_usage',      type => 0 },
        { name => 'cpu_contention', type => 0, cb_init => 'skip_contention' },
        { name => 'cpu_demand',     type => 0, cb_init => 'skip_demand' },
        { name => 'cpu_corecount',  type => 0, cb_init => 'skip_corecount' }
    ];

    $self->{maps_counters}->{cpu_usage} = [
        {
            label  => 'usage-prct',
            type   => 1,
            nlabel => 'cpu.capacity.usage.percentage',
            set    => {
                output_template => 'CPU average usage is %.2f %%',
                key_values      => [ { name => 'prct_used' } ],
                output_use      => 'prct_used',
                threshold_use   => 'prct_used',
                perfdatas       => [
                    {
                        value    => 'prct_used',
                        template => '%.2f',
                        min      => 0,
                        max      => 100,
                        unit     => '%'
                    }
                ]
            }
        },
        {
            label  => 'usage-frequency',
            type   => 1,
            nlabel => 'cpu.capacity.usage.hertz',
            set    => {
                key_values      => [ { name => 'cpu.capacity.usage.HOST' }, { name => 'cpu_usage_hertz' }, { name => 'cpu_provisioned_hertz' } ],
                output_use      => 'cpu.capacity.usage.HOST',
                threshold_use   => 'cpu.capacity.usage.HOST',
                output_template => 'used frequency is %s kHz',
                perfdatas       => [
                    {
                        value    => 'cpu_usage_hertz',
                        template => '%s',
                        min      => 0,
                        max      => 'cpu_provisioned_hertz',
                        unit     => 'Hz'
                    }
                ]
            }
        }
    ];

    $self->{maps_counters}->{cpu_contention} = [
        {
            label  => 'contention-prct',
            type   => 1,
            nlabel => 'cpu.capacity.contention.percentage',
            set    => {
                output_template => 'CPU average contention is %.2f %%',
                key_values      => [ { name => 'cpu.capacity.contention.HOST' } ],
                output_use      => 'cpu.capacity.contention.HOST',
                threshold_use   => 'cpu.capacity.contention.HOST',
                perfdatas       => [
                    {
                        value    => 'cpu.capacity.contention.HOST',
                        template => '%.2f',
                        min      => 0,
                        max      => 100,
                        unit     => '%'
                    }
                ]
            }
        }
    ];
    $self->{maps_counters}->{cpu_demand} = [
        {
            label  => 'demand-prct',
            type   => 1,
            nlabel => 'cpu.capacity.demand.percentage',
            set    => {
                output_template => 'CPU average demand is %.2f %%',
                key_values      => [ { name => 'prct_demand' } ],
                output_use      => 'prct_demand',
                threshold_use   => 'prct_demand',
                perfdatas       => [ { value => 'prct_demand', template => '%s', unit => '%', min => 0, max => 100 } ]
            }
        },
        {
            label  => 'demand-frequency',
            type   => 1,
            nlabel => 'cpu.capacity.demand.hertz',
            set    => {
                key_values      => [
                    { name => 'cpu.capacity.demand.HOST' },
                    { name => 'cpu_demand_hertz' },
                    { name => 'cpu_provisioned_hertz' }
                ],
                output_use      => 'cpu.capacity.demand.HOST',
                threshold_use   => 'cpu.capacity.demand.HOST',
                output_template => 'demand frequency is %s kHz',
                perfdatas       => [
                    {
                        value    => 'cpu_demand_hertz',
                        template => '%s',
                        min      => 0,
                        max      => 'cpu_provisioned_hertz',
                        unit     => 'Hz'
                    }
                ]
            }
        }
    ];

    $self->{maps_counters}->{cpu_corecount} = [
        {
            label  => 'corecount-usage-count',
            type   => 1,
            nlabel => 'cpu.corecount.usage.count',
            set    => {
                output_template => 'CPU cores used: %s',
                output_use      => 'cpu.corecount.usage.HOST',
                key_values      => [ { name => 'cpu.corecount.usage.HOST' } ],
                threshold_use   => 'cpu.corecount.usage.HOST',
                perfdatas       => [
                    {
                        value    => 'cpu.corecount.usage.HOST',
                        template => '%s'
                    }
                ]
            }
        }
    ];
}

sub manage_selection {
    my ($self, %options) = @_;

    # Set the list of basic counters IDs
    my @counters = (
        'cpu.capacity.provisioned.HOST',
        'cpu.capacity.usage.HOST'
    );

    # Add some counters depending on the options
    push @counters, 'cpu.capacity.contention.HOST'     if ($self->{option_results}->{add_contention});
    push @counters, 'cpu.capacity.demand.HOST'         if ($self->{option_results}->{add_demand});
    push @counters, 'cpu.corecount.provisioned.HOST',
                    'cpu.corecount.usage.HOST'         if ($self->{option_results}->{add_corecount});

    # The corecount contention is available but does not seem useful atm. Keeping it here for later
    #push @counters_list, 'cpu.corecount.contention.HOST'    if ($self->{option_results}->{add_contention} && $self->{option_results}->{add_corecount});

    # Get all the needed stats
    my %results = map {
        $_ => $self->get_esx_stats(%options, cid => $_, esx_id => $self->{esx_id}, esx_name => $self->{esx_name} )
    } @counters;

    if (!defined($results{'cpu.capacity.usage.HOST'}) || !defined($results{'cpu.capacity.provisioned.HOST'})) {
        $self->{output}->option_exit(short_msg => "get_esx_stats function failed to retrieve stats");
    }

    # Fill the counter structure depending on their availability
    # Fill the basic stats
    $self->{cpu_usage} = {
        'prct_used'               => 100 * $results{'cpu.capacity.usage.HOST'} / $results{'cpu.capacity.provisioned.HOST'},
        'cpu_usage_hertz'         => $results{'cpu.capacity.usage.HOST'} * 1000,
        'cpu_provisioned_hertz'   => $results{'cpu.capacity.provisioned.HOST'} * 1000,
        'cpu.capacity.usage.HOST' => $results{'cpu.capacity.usage.HOST'}
    };

    # Fill the contention stats
    if ( defined($results{'cpu.capacity.contention.HOST'}) ) {
        $self->{cpu_contention} = {
            'cpu.capacity.contention.HOST' => $results{'cpu.capacity.contention.HOST'}
        };
    }

    # Fill the demand stats
    if (defined($results{'cpu.capacity.demand.HOST'}) && defined($results{'cpu.capacity.provisioned.HOST'})) {
        $self->{cpu_demand} = {
            'prct_demand'              => 100 * $results{'cpu.capacity.demand.HOST'} / $results{'cpu.capacity.provisioned.HOST'},
            'cpu.capacity.demand.HOST' => $results{'cpu.capacity.demand.HOST'},
            'cpu_demand_hertz'         => $results{'cpu.capacity.demand.HOST'} * 1000,
            'cpu_provisioned_hertz'    => $results{'cpu.capacity.provisioned.HOST'} * 1000
        };
    }

    # Fill the corecount stats
    if (defined($results{'cpu.corecount.usage.HOST'})) {
        $self->{cpu_corecount}->{'cpu.corecount.usage.HOST'} = $results{'cpu.corecount.usage.HOST'};
        # This counter is the number of physical CPU cores of the ESX, it does not seem worth monitoring
        #$self->{cpu_corecount}->{'cpu.corecount.provisioned.HOST'} = $results{'cpu.corecount.provisioned.HOST'};
    }

    # Example of retrieved stats:
    # $VAR1 = {
    #           'cpu.capacity.demand.HOST' => '2790',
    #           'cpu.capacity.provisioned.HOST' => '50280',
    #           'cpu.capacity.usage.HOST' => '3228.36',
    #           'cpu.corecount.provisioned.HOST' => '24',
    #           'cpu.capacity.contention.HOST' => '0.55',
    #           'cpu.corecount.usage.HOST' => '78',
    #           'cpu.corecount.contention.HOST' => '0'
    #         };

    return 1;
}

1;

__END__

=head1 MODE

Monitor the CPU stats of VMware ESX hosts through vSphere 8 REST API.

    Meaning of the available counters in the VMware API:
    - cpu.capacity.provisioned.HOST     Capacity in kHz of the physical CPU cores.
    - cpu.capacity.usage.HOST           CPU usage as a percent during the interval.
    - cpu.capacity.contention.HOST      Percent of time the virtual machine is unable to run because it is contending for access to the physical CPU(s).
    - cpu.capacity.demand.HOST          The amount of CPU resources a virtual machine would use if there were no CPU contention or CPU limit.
    - cpu.corecount.usage.HOST          The number of virtual processors running on the host.
    - cpu.corecount.provisioned.HOST    The number of virtual processors provisioned to the entity.
    - cpu.corecount.contention.HOST     Time the virtual machine vCPU is ready to run, but is unable to run due to co-scheduling constraints.

    The default metrics provided by this plugin are:
    - cpu.capacity.usage.hertz based on the API's cpu.capacity.usage.HOST counter
    - cpu.capacity.usage.percentage based on 100 * cpu.capacity.usage.HOST / cpu.capacity.provisioned.HOST

=over 8

=item B<--add-demand>

Add counter related to CPU demand:

C<cpu.capacity.demand.HOST>: The amount of CPU resources a virtual machine would use if there were no CPU contention or CPU limit.

=item B<--add-contention>

Add counter related to CPU demand:

C<cpu.capacity.contention.HOST>: Percent of time the virtual machine is unable to run because it is contending for access to the physical CPU(s).

=item B<--add-corecount>

Add counter related to CPU core count:

C<cpu.corecount.usage.HOST>: The number of virtual processors running on the host.

=item B<--warning-contention-prct>

Threshold in percentage.

=item B<--critical-contention-prct>

Threshold in percentage.

=item B<--warning-corecount-usage-count>

Threshold.

=item B<--critical-corecount-usage-count>

Threshold.

=item B<--warning-demand-frequency>

Threshold in Hertz.

=item B<--critical-demand-frequency>

Threshold in Hertz.

=item B<--warning-demand-prct>

Threshold in percentage.

=item B<--critical-demand-prct>

Threshold in percentage.

=item B<--warning-usage-frequency>

Threshold in Hertz.

=item B<--critical-usage-frequency>

Threshold in Hertz.

=item B<--warning-usage-prct>

Threshold in percentage.

=item B<--critical-usage-prct>

Threshold in percentage.

=back

=cut
