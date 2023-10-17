#
# Copyright 2023 Centreon (http://www.centreon.com/)
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

# Path to the plugin
package network::mysnmpplugin::snmp::mode::cpu;

# Consider this as mandatory when writing a new mode.
use base qw(centreon::plugins::templates::counter);

# Needed libraries
use strict;
use warnings;

sub prefix_cpu_output {
    my ($self, %options) = @_;

    return "CPU '" . $options{instance_value}->{name} . "' usage: ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        # app_metrics groups connections and errors and each will receive value for both instances (my-awesome-frontend and my-awesome-db)

        #A compléter

            # the type => 1 explicits that
            # You can define a callback (cb) function to manage the output prefix. This function is called
            # each time a value is passed to the counter and can be shared across multiple counters.
            { name => 'cpu', type => 1, cb_prefix_output => 'prefix_cpu_output', message_multiple => 'All CPUs are ok' }
    ];

    $self->{maps_counters}->{cpu} = [
        { label => 'cpu-usage-prct', nlabel => 'cpu.usage.percentage', set => {
            key_values      => [ { name => 'cpu_usage' }, { name => 'name' } ],
            output_template => '%.2f %%',
            perfdatas       => [
                # we add the label_extra_instance option to have one perfdata per instance
                { label => 'cpu', template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'name' }
            ]
        }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    # All options/properties of this mode, always add the force_new_perfdata => 1 to enable new metric/performance data naming.
    # It also where you can specify that the plugin uses a cache file for example
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    # Declare options
    $options{options}->add_options(arguments => {
        # One the left it's the option name that will be used in the command line. The ':s' at the end is to
        # define that this options takes a value.
        # On the right, it's the code name for this option, optionnaly you can define a default value so the user
        # doesn't have to set it.
        # option name        => variable name
        'filter-id:s' => { name => 'filter_id' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;
    ###################################################
    ##### Load SNMP informations to a result hash #####
    ###################################################

    # Select relevant oids for CPU monitoring
    my $mapping = {
        # hashKey => { oid => 'oid_number_path'}
        hrProcessorID    => { oid => '.1.3.6.1.2.1.25.3.3.1.1' },
        hrProcessorLoad     => { oid => '.1.3.6.1.2.1.25.3.3.1.2' }
        #
    };

    # Point at the begining of the SNMP table
    # Oid to point the table ahead all the oids given in mapping
    my $oid_hrProcessorTable = '.1.3.6.1.2.1.25.3.3.1';

    # Use SNMP Centreon plugins tools to push SNMP result in hash to handle with.
    # $cpu_result is a hash table where keys are oids
    my $cpu_result = $options{snmp}->get_table(
        oid => $oid_hrProcessorTable,
        nothing_quit => 1
    );

    ###################################################
    ##### SNMP Result table to browse             #####
    ###################################################
    foreach my $oid (keys %{$cpu_result}) {
        next if ($oid !~ /^$mapping->{hrProcessorID}->{oid}\.(.*)$/);

        # Catch table instance if exist :
        # Instance is a number availible for a same oid refering to different target
        my $instance = $1;
        # Uncomment the lines below to see what instance looks like :

        # use Data::Dumper;
        # print Dumper($oid);
        # print Dumper($instance);

        # Data Dumper returns : with oid = hrProcessorID.instance
        # $VAR1 = '.1.3.6.1.2.1.25.3.3.1.1.769';
        # $VAR1 = '769';
        # $VAR1 = '.1.3.6.1.2.1.25.3.3.1.1.768';
        # $VAR1 = '768';

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $cpu_result, instance => $instance);

        # Here is the way to handle with basic name/id filter.
        # This filter is compare with hrProcessorID and in case of no match the oid is skipped
        if (defined($self->{option_results}->{filter_id}) && $self->{option_results}->{filter_id} ne '' &&
            $result->{hrProcessorID} !~ /$self->{option_results}->{filter_id}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{hrProcessorID} . "': no matching filter.", debug => 1);
            next;
        }

        # If the oid is not skipped above, here is convert the target values in result hash.
        # Here is where the counter magic happens.
        # $self->{cpu} is your counter definition (see $self->{maps_counters}->{<name>})
        # Here, we map the obtained string $result->{hrProcessorLoad} with the cpu_usage key_value in the counter.
        $self->{cpu}->{$instance} = {
            name => $result->{hrProcessorID},
            cpu_usage => $result->{hrProcessorLoad}
        };
    }

    # IMPORTANT !
    # If you use a way to filter the values set in result hash,
    # check if at the end of parsing the result table isn't empty.
    # If it's the case, add a message for user to explain the filter doesn't match.
    if (scalar(keys %{$self->{cpu}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No processor ID matching with filter found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check system CPUs.

=over 8

=item B<--filter-id>

Filter on one ID name.

=item B<--warning>

Warning threshold for CPU.

=item B<--critical>

Critical threshold for CPU.

=back

=cut