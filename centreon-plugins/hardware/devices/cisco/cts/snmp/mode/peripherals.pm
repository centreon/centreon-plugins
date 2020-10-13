#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package hardware::devices::cisco::cts::snmp::mode::peripherals;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'status: %s',
        $self->{result_values}->{status}
    );
}

sub prefix_peripheral_output {
    my ($self, %options) = @_;

    return "Peripheral '" . $options{instance_value}->{description} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'peripherals', type => 1, cb_prefix_output => 'prefix_peripheral_output', message_multiple => 'All peripherals are ok' }
    ];
    
    $self->{maps_counters}->{peripherals} = [
        { label => 'status', type => 2, critical_default => '%{status} !~ /noError/i', set => {
                key_values => [ { name => 'status' }, { name => 'description' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{global} = [
         { label => 'total', nlabel => 'peripherals.total.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'Total peripherals: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-description:s' => { name => 'filter_description' }
    });

    return $self;
}

my $mapping_status = {
    0 => 'noError', 1 => 'other', 2 => 'cableError', 3 => 'powerError',
    4 => 'mgmtSysConfigError', 5 => 'systemError', 6 => 'deviceError',
    7 => 'linkError', 8 => 'commError', 9 => 'detectionDisabled'
};

my $mapping = {
    description => { oid => '.1.3.6.1.4.1.9.9.643.1.2.1.1.2' }, # ctpPeripheralDescription
    status      => { oid => '.1.3.6.1.4.1.9.9.643.1.2.1.1.3', map => $mapping_status } # ctpPeripheralStatus
};
my $oid_ctpPeripheralStatusEntry = '.1.3.6.1.4.1.9.9.643.1.2.1.1';

sub manage_selection {
    my ($self, %options) = @_;
    
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_ctpPeripheralStatusEntry,
        start => $mapping->{description}->{oid},
        end => $mapping->{status}->{oid},
        nothing_quit => 1
    );

    $self->{peripherals} = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{status}->{oid}\.(.*)/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        if (defined($self->{option_results}->{filter_description}) && $self->{option_results}->{filter_description} ne '' &&
            $result->{description} !~ /$self->{option_results}->{filter_description}/) {
            $self->{output}->output_add(long_msg => "skipping phone '" . $instance . "': no matching filter.", debug => 1);
            next;
        }

        $self->{peripherals}->{$instance} = $result;
    }

    $self->{global} = { total => scalar(keys %{$self->{peripherals}}) };
}
    
1;

__END__

=head1 MODE

Check peripherals.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='status'

=item B<--filter-description>

Filter peripheral by description (can be a regexp).

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{status}, %{description}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} !~ /^registered/').
Can used special variables like: %{status}, %{description}

=item B<--warning-*> B<--critical-*>

Thresholds.

Can be: 'total'.

=back

=cut
