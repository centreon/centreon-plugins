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
use base qw(centreon::plugins::templates::counter);


sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(
        arguments => {
                'esx-id:s'       => { name => 'esx_id' },
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
    if ( centreon::plugins::misc::is_empty($self->{option_results}->{esx_id}) ) {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --esx-id option.');
        $self->{output}->option_exit();
    }

    # If a threshold is given on contention, we enable the corresponding data collection
    if ( grep {$_ =~ /contention/ && defined($self->{option_results}->{$_})} keys %{$self->{option_results}} ) {
        $self->{option_results}->{add_contention} = 1;
    }
    # If a threshold is given on demand, we enable the corresponding data collection
    if ( grep {$_ =~ /demand/ && defined($self->{option_results}->{$_})} keys %{$self->{option_results}} ) {
        $self->{option_results}->{add_demand} = 1;
    }
    # If a threshold is given on corecount, we enable the corresponding data collection
    if ( grep {$_ =~ /corecount/ && defined($self->{option_results}->{$_})} keys %{$self->{option_results}} ) {
        $self->{option_results}->{add_corecount} = 1;
    }
}

# Skip contention processing if there is no available data
sub skip_contention {
    my ($self, %options) = @_;

    return 0 if (defined($self->{cpu_contention})
            && ref($self->{cpu_contention}) eq 'HASH'
            && scalar(keys %{$self->{cpu_contention}}) > 1 );

    return 1;
}

# Skip demand processing if there is no available data
sub skip_demand {
    my ($self, %options) = @_;

    return 0 if (defined($self->{cpu_demand})
            && ref($self->{cpu_demand}) eq 'HASH'
            && scalar(keys %{$self->{cpu_demand}}) > 0 );

    return 1;
}

# Skip corecount processing if there is no available data
sub skip_corecount {
    my ($self, %options) = @_;

    return 0 if (defined($self->{cpu_corecount})
            && ref($self->{cpu_corecount}) eq 'HASH'
            && scalar(keys %{$self->{cpu_corecount}}) > 0 );

    return 1;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'cpu_usage',          type => 0 },
        { name => 'cpu_contention',     type => 0,      cb_init => 'skip_contention' },
        { name => 'cpu_demand',         type => 0,      cb_init => 'skip_demand' },
        { name => 'cpu_corecount',      type => 0,      cb_init => 'skip_corecount' }
    ];

    $self->{maps_counters}->{cpu_usage} = [
            {
                    label  => 'usage-percentage',
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
                                            max      => 'cpu_provisioned_hertz',
                                            unit     => 'Hz'
                                    }
                            ]
                    }
            }
    ];

    $self->{maps_counters}->{cpu_contention} = [
            {
                    label  => 'contention-percentage',
                    type   => 1,
                    nlabel => 'cpu.capacity.contention.percentage',
                    set    => {
                            output_template => 'CPU average contention is %.2f %%',
                            key_values      => [ { name => 'prct_contention' } ],
                            output_use      => 'prct_contention',
                            threshold_use   => 'prct_contention',
                            perfdatas       => [
                                    {
                                            value    => 'prct_contention',
                                            template => '%.2f',
                                            min      => 0,
                                            max      => 100,
                                            unit     => '%'
                                    }
                            ]
                    }
            },
            {
                    label  => 'contention-frequency',
                    type   => 1,
                    nlabel => 'cpu.capacity.contention.hertz',
                    set    => {
                            key_values    => [
                                    { name => 'cpu.capacity.contention.HOST' },
                                    { name => 'cpu_contention_hertz' },
                                    { name => 'cpu_provisioned_hertz' }
                            ],
                            output_use    => 'cpu.capacity.contention.HOST',
                            threshold_use => 'cpu.capacity.contention.HOST',
                            output_template => 'contention frequency is %s kHz',
                            perfdatas     => [
                                    {
                                            value => 'cpu_contention_hertz',
                                            template => '%s',
                                            max      => 'cpu_provisioned_hertz',
                                            unit     => 'Hz'
                                    }
                            ]
                    }
            }
    ];
    $self->{maps_counters}->{cpu_demand} = [
            {
                    label  => 'demand-percentage',
                    type   => 1,
                    nlabel => 'cpu.capacity.demand.percentage',
                    set    => {
                            output_template => 'CPU average demand is %.2f %%',
                            key_values    => [ { name => 'prct_demand' } ],
                            output_use    => 'prct_demand',
                            threshold_use => 'prct_demand',
                            perfdatas     => [ { value => 'prct_demand', template => '%s' } ]
                    }
            },
            {
                    label  => 'demand-frequency',
                    type   => 1,
                    nlabel => 'cpu.capacity.demand.hertz',
                    set    => {
                            key_values    => [
                                    { name => 'cpu.capacity.demand.HOST' },
                                    { name => 'cpu_demand_hertz' },
                                    { name => 'cpu_provisioned_hertz' }
                            ],
                            output_use    => 'cpu.capacity.demand.HOST',
                            threshold_use => 'cpu.capacity.demand.HOST',
                            output_template => 'demand frequency is %s kHz',
                            perfdatas     => [
                                    {
                                            value => 'cpu_demand_hertz',
                                            template => '%s',
                                            max      => 'cpu_provisioned_hertz',
                                            unit     => 'Hz'
                                    }
                            ]
                    }
            }
    ];

    $self->{maps_counters}->{cpu_corecount} = [
            {
                    label  => 'corecount-usage',
                    type   => 1,
                    nlabel => 'cpu.corecount.usage.count',
                    set    => {
                            output_template => 'CPU cores used: %s',
                            key_values    => [ { name => 'cpu.corecount.usage.HOST' } ],
                            output_use    => 'cpu.corecount.usage.HOST',
                            threshold_use => 'cpu.corecount.usage.HOST',
                            perfdatas     => [
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
    my @counters_list = (
        'cpu.capacity.provisioned.HOST',
        'cpu.capacity.usage.HOST'
    );

    # Add some counters depending on the options
    push @counters_list, 'cpu.capacity.contention.HOST'     if ($self->{option_results}->{add_contention});
    push @counters_list, 'cpu.capacity.demand.HOST'         if ($self->{option_results}->{add_demand});
    push @counters_list, 'cpu.corecount.provisioned.HOST',
                         'cpu.corecount.usage.HOST'         if ($self->{option_results}->{add_corecount});

    # The corecount contention is available but does not seem useful atm. Keeping it here for later
    #push @counters_list, 'cpu.corecount.contention.HOST'    if ($self->{option_results}->{add_contention} && $self->{option_results}->{add_corecount});

    # Get all the needed stats
    my %results = map { $_ => $options{custom}->get_stats(cid => $_, rsrc_id => $self->{option_results}->{esx_id}) } @counters_list;

    # Fill the counter structure depending on their availability
    # Fill the basic stats
    if ( defined($results{'cpu.capacity.usage.HOST'}) && defined($results{'cpu.capacity.provisioned.HOST'}) ) {
        $self->{cpu_usage} = {
                'prct_used'               => 100 * $results{'cpu.capacity.usage.HOST'} / $results{'cpu.capacity.provisioned.HOST'},
                'cpu_usage_hertz'         => $results{'cpu.capacity.usage.HOST'} * 1000,
                'cpu_provisioned_hertz'   => $results{'cpu.capacity.provisioned.HOST'} * 1000,
                'cpu.capacity.usage.HOST' => $results{'cpu.capacity.usage.HOST'} 
        };
    }

    # Fill the contention stats
    if ( defined($results{'cpu.capacity.contention.HOST'}) && defined($results{'cpu.capacity.provisioned.HOST'}) ) {
        $self->{cpu_contention} = {
                'prct_contention'              => 100 * $results{'cpu.capacity.contention.HOST'} / $results{'cpu.capacity.provisioned.HOST'},
                'cpu.capacity.contention.HOST' => $results{'cpu.capacity.contention.HOST'},
                'cpu_contention_hertz'         => $results{'cpu.capacity.contention.HOST'} * 1000,
                'cpu_provisioned_hertz'        => $results{'cpu.capacity.provisioned.HOST'} * 1000
        };
    }

    # Fill the demand stats
    if ( defined($results{'cpu.capacity.demand.HOST'}) && defined($results{'cpu.capacity.provisioned.HOST'}) ) {
        $self->{cpu_demand} = {
                'prct_demand'              => 100 * $results{'cpu.capacity.demand.HOST'} / $results{'cpu.capacity.provisioned.HOST'},
                'cpu.capacity.demand.HOST' => $results{'cpu.capacity.demand.HOST'},
                'cpu_demand_hertz'         => $results{'cpu.capacity.demand.HOST'} * 1000,
                'cpu_provisioned_hertz'    => $results{'cpu.capacity.provisioned.HOST'} * 1000
        };
    }

    # Fill the corecount stats
    if ( defined($results{'cpu.corecount.usage.HOST'}) ) {
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


=head1 MODE

Monitor the status of VMware ESX hosts through vSphere 8 REST API.

=over 8

=item B<--esx-id>

Define which ESX id to monitor based on their name.

=item B<--warning-usage-percentage>

Threshold in %.

=item B<--critical-usage-percentage>

Threshold in %.

=item B<--warning-usage-frequency>

Threshold in Hz.

=item B<--critical-usage-frequency>

Threshold in Hz.

=item B<--warning-contention-percentage>

Threshold in %.

=item B<--critical-contention-percentage>

Threshold in %.

=item B<--warning-contention-frequency>

Threshold in Hz.

=item B<--critical-contention-frequency>

Threshold in Hz.

=item B<--warning-demand-percentage>

Threshold in %.

=item B<--critical-demand-percentage>

Threshold in %.

=item B<--warning-demand-frequency>

Threshold in Hz.

=item B<--critical-demand-frequency>

Threshold in Hz.

=item B<--warning-corecount-usage>

Threshold in number of cores.

=item B<--critical-corecount-usage>

Threshold in number of cores.

=back

=cut
