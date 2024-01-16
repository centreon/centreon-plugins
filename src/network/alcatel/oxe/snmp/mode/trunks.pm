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

package network::alcatel::oxe::snmp::mode::trunks;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return 'status: ' . $self->{result_values}->{trunkstatus};
}

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        instances => $self->{result_values}->{name},
        value => $self->{result_values}->{used},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, total => $self->{result_values}->{total}, cast_int => 1),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, total => $self->{result_values}->{total}, cast_int => 1),
        min => 0, max => $self->{result_values}->{total}
    );
}

sub custom_usage_threshold {
    my ($self, %options) = @_;
    
    my $exit = $self->{perfdata}->threshold_check(
        value => $self->{result_values}->{prct_used},
        threshold => [ 
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } 
        ]
    );
    return $exit;
}

sub custom_usage_output {
    my ($self, %options) = @_;

    return sprintf(
        "channels usage total: %s used: %s (%.2f%%) free: %s (%.2f%%)",
        $self->{result_values}->{total},
        $self->{result_values}->{used}, $self->{result_values}->{prct_used},
        $self->{result_values}->{free}, $self->{result_values}->{prct_free}
    );
}

sub custom_trunk_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{name} = $options{new_datas}->{$self->{instance} . '_name'};
    $self->{result_values}->{free} = $options{new_datas}->{$self->{instance} . '_freechan'};
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_busychan'};
    $self->{result_values}->{total} = $self->{result_values}->{free} + $self->{result_values}->{used};

    return -10 if ($self->{result_values}->{total} <= 0);

    $self->{result_values}->{prct_free} = $self->{result_values}->{free} * 100 / $self->{result_values}->{total};
    $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
    return 0;
}

sub prefix_trunk_output {
    my ($self, %options) = @_;

    return "Trunk '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'trunk', type => 1, cb_prefix_output => 'prefix_trunk_output', message_multiple => 'All trunks are ok', skipped_code => { -2 => 1, -10 => 1 } }
    ];

    $self->{maps_counters}->{trunk} = [
        { label => 'trunk-status', type => 2, critical_default => '%{trunkstatus} =~ /oos/i', set => {
                key_values => [ { name => 'trunkstatus' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'channel-usage', nlabel => 'trunk.channels.usage.count', set => {
                key_values => [ { name => 'busychan' }, { name => 'freechan' }, { name => 'name' } ],
                closure_custom_calc => $self->can('custom_trunk_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold')
            }
        },
        { label => 'channel-outofservice', nlabel => 'trunk.channels.outofservice.count', set => {
                key_values => [ { name => 'ooschan' } ],
                output_template => 'channels out of service %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
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
        "filter-trunk:s"   => { name => 'filter_trunk' },
    });

    return $self;
}

my $map_trunk_status = { 0 => 'OOS', 1 => 'INS' };

my $mapping = {
    trunkname    => { oid => '.1.3.6.1.4.1.637.64.4400.1.9.1.2' },
    crystalno    => { oid => '.1.3.6.1.4.1.637.64.4400.1.9.1.3' }, # not used
    couplerno    => { oid => '.1.3.6.1.4.1.637.64.4400.1.9.1.4' }, # not used
    trunktype    => { oid => '.1.3.6.1.4.1.637.64.4400.1.9.1.5' }, # not used
    nodepbx      => { oid => '.1.3.6.1.4.1.637.64.4400.1.9.1.6' }, # not used
    freechan     => { oid => '.1.3.6.1.4.1.637.64.4400.1.9.1.7' },
    busychan     => { oid => '.1.3.6.1.4.1.637.64.4400.1.9.1.8' },
    ooschan      => { oid => '.1.3.6.1.4.1.637.64.4400.1.9.1.9' },
    trunkstatus  => { oid => '.1.3.6.1.4.1.637.64.4400.1.9.1.10', map => $map_trunk_status },
    cumuloos     => { oid => '.1.3.6.1.4.1.637.64.4400.1.9.1.11' }, # not used
    cumuloverrun => { oid => '.1.3.6.1.4.1.637.64.4400.1.9.1.12' }  # not used
};

sub manage_selection {
    my ($self, %options) = @_;
 
    my $oid_trunkEntry = '.1.3.6.1.4.1.637.64.4400.1.9.1';
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_trunkEntry,
        nothing_quit => 1
    );

    $self->{trunk} = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{trunkname}->{oid}\.(\d+)/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        next if (defined($self->{option_results}->{filter_trunk}) && $self->{option_results}->{filter_trunk} ne '' &&
            $result->{trunkname} !~ /$self->{option_results}->{filter_trunk}/);

        $self->{trunk}->{ $result->{trunkname} } = { 
            name => $result->{trunkname},
            %{$result}
        };
    }

    if (scalar(keys %{$self->{trunk}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No trunk found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check Trunk usages.

=over 8

=item B<--filter-trunk>

Filter by trunk name (regexp can be used).

=item B<--warning-trunk-status>

Define the conditions to match for the status to be WARNING
You can use the following variables: %{trunkstatus}

=item B<--critical-trunk-status>

Define the conditions to match for the status to be CRITICAL (default: '%{trunkstatus} =~ /oos/i').
You can use the following variables: %{trunkstatus}

=item B<--warning-*>

Warning threshold.
Can be: 'channel-usage' (%), 'channel-outofservice' (absolute)

=item B<--critical-*>

Critical threshold.
Can be: 'channel-usage' (%), 'channel-outofservice' (absolute)

=back

=cut
