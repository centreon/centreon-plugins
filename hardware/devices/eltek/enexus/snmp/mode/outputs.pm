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

package hardware::devices::eltek::enexus::snmp::mode::outputs;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);
use centreon::plugins::misc;

sub custom_status_output { 
    my ($self, %options) = @_;

    return sprintf('status: %s',
        $self->{result_values}->{status}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'cuo', type => 1, cb_prefix_output => 'prefix_cuo_output', message_multiple => 'All outputs for control units are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'outputs-disconnected', nlabel => 'outputs.disconnected.count', display_ok => 0, set => {
                key_values => [ { name => 'disconnected' }, { name => 'total_contactors' } ],
                output_template => 'current disconnected outputs: %d',
                perfdatas => [
                    { value => 'disconnected', template => '%d', min => 0, max => 'total_contactors' }
                ]
            }
        },
        { label => 'outputs-notenergized', nlabel => 'outputs.notenergized.count', display_ok => 0, set => {
                key_values => [ { name => 'notenergized' }, { name => 'total_relay' } ],
                output_template => 'current not energized outputs: %d',
                perfdatas => [
                    { value => 'notenergized', template => '%d', min => 0, max => 'total_relay' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{cuo} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'name' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        }
    ];
}

sub prefix_cuo_output {
    my ($self, %options) = @_;

    return "Control unit output '" . $options{instance_value}->{name} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-name:s'     => { name => 'filter_name' },
        'unknown-status:s'  => { name => 'unknown_status', default => '' },
        'warning-status:s'  => { name => 'warning_status', default => '' },
        'critical-status:s' => { name => 'critical_status', default => '%{status} =~ /notenergized|disconnected/i' }
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => [
        'warning_status', 'critical_status', 'unknown_status',
    ]);
}

my $map_status = { 0 => 'notenergized', 1 => 'energized', 2 => 'disconnected', 3 => 'connected' };

my $mapping = {
    outputControlUnitOutputStatus      => { oid => '.1.3.6.1.4.1.12148.10.12.2.1.2', map => $map_status }, 
    outputControlUnitOutputDescription => { oid => '.1.3.6.1.4.1.12148.10.12.2.1.3' }
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_outputControlUnitOutputEntry = '.1.3.6.1.4.1.12148.10.12.2.1';
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_outputControlUnitOutputEntry,
        start => $mapping->{outputControlUnitOutputStatus}->{oid},
        nothing_quit => 1
    );

    $self->{global} = { total_relay => 0, total_contactors => 0, energized => 0, notenergized => 0, connected => 0, disconnected => 0 };
    $self->{cuo} = {};
    my $duplicated = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{outputControlUnitOutputStatus}->{oid}\.(.*)$/);
        my $instance = $1;

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        my $name = centreon::plugins::misc::trim($result->{outputControlUnitOutputDescription});
        $name = $instance if ($name eq '');
        $name = $instance if (defined($duplicated->{$name}));

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping control unit output '" . $name . "'.", debug => 1);
            next;
        }

        if (defined($self->{cuo}->{$name})) {
            $duplicated->{$name} = 1;
            my $instance2 = $self->{cuo}->{$name}->{instance};
            $self->{cuo}->{$instance2} = $self->{cuo}->{$name};
            $self->{cuo}->{$instance2}->{name} = $instance2;
            delete $self->{cuo}->{$name};
            $name = $instance;
        }

        $self->{cuo}->{$name} = {
            instance => $instance,
            name => $name,
            status => $result->{outputControlUnitOutputStatus}
        };
        $self->{global}->{total_relay}++ if ($result->{outputControlUnitOutputStatus} =~ /energized/);
        $self->{global}->{total_contactors}++ if ($result->{outputControlUnitOutputStatus} =~ /connected/);
        $self->{global}->{$result->{outputControlUnitOutputStatus}}++;
    }
}

1;

__END__

=head1 MODE

Check outputs for control units.

=over 8

=item B<--filter-name>

Filter name (can be a regexp).

=item B<--unknown-status>

Set unknown threshold for status.
Can used special variables like: %{status}, %{name}

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{status}, %{name}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /notenergized|disconnected/i').
Can used special variables like: %{status}, %{name}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'outputs-disconnected', 'outputs-notenergized'.

=back

=cut
