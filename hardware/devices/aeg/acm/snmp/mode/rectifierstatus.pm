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

package hardware::devices::aeg::acm::snmp::mode::rectifierstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = sprintf("status is '%s'", $self->{result_values}->{status});
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_rectState'};
    return 0;
}

sub prefix_rect_output {
    my ($self, %options) = @_;

    return "Rectifier '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 }  },
        { name => 'rect', type => 1, cb_prefix_output => 'prefix_rect_output', message_multiple => 'All rectifiers are ok', skipped_code => { -10 => 1 } },
    ];
        
    $self->{maps_counters}->{global} = [
        { label => 'voltage', set => {
                key_values => [ { name => 'rectVoltage' } ],
                output_template => 'Voltage : %s V',
                perfdatas => [
                    { label => 'voltage', value => 'rectVoltage', template => '%s', 
                      unit => 'V' },
                ],
            }
        },
        { label => 'current', set => {
                key_values => [ { name => 'rectCurrent' } ],
                output_template => 'Current : %s A',
                perfdatas => [
                    { label => 'current', value => 'rectCurrent', template => '%s', 
                      min => 0, unit => 'A' },
                ],
            }
        },
        { label => 'faulty-count', set => {
                key_values => [ { name => 'nbrOfFaultyRect' } ],
                output_template => 'Faulty rectifiers : %s',
                perfdatas => [
                    { label => 'faulty_count', value => 'nbrOfFaultyRect', template => '%s', 
                      min => 0, unit => '' },
                ],
            }
        },
    ];

    $self->{maps_counters}->{rect} = [
         { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'rectState' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "warning-status:s"        => { name => 'warning_status', default => '' },
        "critical-status:s"       => { name => 'critical_status', default => '%{status} !~ /ok|notInstalled/i' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

my %map_state = (
    1 => 'ok',
    255 => 'notInstalled',
);

my $mapping_acm1000 = {
    rectVoltage     => { oid => '.1.3.6.1.4.1.15416.37.2.1', divider => '100' },
    rectCurrent     => { oid => '.1.3.6.1.4.1.15416.37.2.2', divider => '100' },
    nbrOfFaultyRect => { oid => '.1.3.6.1.4.1.15416.37.2.4' },
};
my $mapping_acmi1000 = {
    rectVoltage     => { oid => '.1.3.6.1.4.1.15416.38.2.1', divider => '100' },
    rectCurrent     => { oid => '.1.3.6.1.4.1.15416.38.2.2', divider => '100' },
    nbrOfFaultyRect => { oid => '.1.3.6.1.4.1.15416.38.2.4' },
};
my $mapping_acm1d = {
    rectState        => { oid => '.1.3.6.1.4.1.15416.29.3.1.2' },
};
my $oid_acm1000DcPlant = '.1.3.6.1.4.1.15416.37.2';
my $oid_acmi1000DcPlant = '.1.3.6.1.4.1.15416.38.2';
my $oid_acm1dRectEntry = '.1.3.6.1.4.1.15416.29.3.1';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = {};
    $self->{rect} = {};
    $self->{results} = $options{snmp}->get_multiple_table(oids => [ { oid => $oid_acm1000DcPlant },
                                                                    { oid => $oid_acmi1000DcPlant },
                                                                    { oid => $oid_acm1dRectEntry },
                                                                  ],
                                                          nothing_quit => 1);

    my $result_acm1000 = $options{snmp}->map_instance(mapping => $mapping_acm1000, results => $self->{results}->{$oid_acm1000DcPlant}, instance => '0');
    my $result_acmi1000 = $options{snmp}->map_instance(mapping => $mapping_acmi1000, results => $self->{results}->{$oid_acmi1000DcPlant}, instance => '0');

    foreach my $name (keys %{$mapping_acm1000}) {
        if (defined($result_acm1000->{$name})) {
            $self->{global}->{$name} = $result_acm1000->{$name};
            $self->{global}->{$name} = $result_acm1000->{$name} / $mapping_acm1000->{$name}->{divider} if defined($mapping_acm1000->{$name}->{divider});
        }
    }
    foreach my $name (keys %{$mapping_acmi1000}) {
        if (defined($result_acmi1000->{$name})) {
            $self->{global}->{$name} = $result_acmi1000->{$name};
            $self->{global}->{$name} = $result_acmi1000->{$name} / $mapping_acmi1000->{$name}->{divider} if defined($mapping_acmi1000->{$name}->{divider});
        }
    }

    foreach my $oid (keys %{$self->{results}->{$oid_acm1dRectEntry}}) {
        next if ($oid !~ /^$mapping_acm1d->{rectState}->{oid}\.(.*)$/);
        my $instance = $1;

        $self->{rect}->{$instance} = { 
            rectState => $map_state{$self->{results}->{$oid_acm1dRectEntry}->{$mapping_acm1d->{rectState}->{oid} . '.' . $instance}},
            display => $instance
        };
    }
}

1;

__END__

=head1 MODE

Check rectifiers status and statistics.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^status|current$'

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{status}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} !~ /ok|notInstalled/i').
Can used special variables like: %{status}

=item B<--warning-*>

Threshold warning.
Can be: 'voltage', 'current', 'faulty-count'.

=item B<--critical-*>

Threshold critical.
Can be: 'voltage', 'current', 'faulty-count'.

=back

=cut
