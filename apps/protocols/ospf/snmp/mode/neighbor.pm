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

package apps::protocols::ospf::snmp::mode::neighbor;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;
    
    return 'state : ' . $self->{result_values}->{NbrState};
}

sub custom_change_output {
    my ($self, %options) = @_;
    
    return 'Neighbors current : ' . $self->{result_values}->{Total} . ' (last : ' . $self->{result_values}->{TotalLast} . ')';
}

sub custom_change_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{TotalLast} = $options{old_datas}->{$self->{instance} . '_total'};
    $self->{result_values}->{Total} = $options{new_datas}->{$self->{instance} . '_total'};
    return 0;
}

sub prefix_nb_output {
    my ($self, %options) = @_;
    
    return "Neighbor '" . $options{instance_value}->{NbrIpAddr} . "/" . $options{instance_value}->{NbrRtrId} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0,  message_separator => ' - ' },
        { name => 'nb', type => 1, cb_prefix_output => 'prefix_nb_output', message_multiple => 'All neighbor relations are ok' }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'total', nlabel => 'neighbors.total.count',set => {
                key_values => [ { name => 'total' } ],
                output_template => 'Total neighbors : %s',
                perfdatas => [
                    { label => 'total', template => '%s', min => 0 }
                ]
            }
        },
        { label => 'total-change', type => 2, set => {
                key_values => [ { name => 'total', diff => 1 } ],
                closure_custom_calc => $self->can('custom_change_calc'),
                closure_custom_output => $self->can('custom_change_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{nb} = [
        { 
            label => 'status', 
            type => 2,
            critical_default => '%{NbrState} =~ /down/i',
            set => {
                key_values => [ { name => 'NbrIpAddr' }, { name => 'NbrRtrId' }, { name => 'NbrState' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
    });
    
    return $self;
}

my %map_state = (
    1 => 'down',
    2 => 'attempt',
    3 => 'init',
    4 => 'twoWay',
    5 => 'exchangeStart',
    6 => 'exchange',
    7 => 'loading',
    8 => 'full'
);
my $mapping = {
    NbrIpAddr   => { oid => '.1.3.6.1.2.1.14.10.1.1' },
    NbrRtrId    => { oid => '.1.3.6.1.2.1.14.10.1.3' },
    NbrState    => { oid => '.1.3.6.1.2.1.14.10.1.6', map => \%map_state }
};

my $oid_ospfNbrEntry = '.1.3.6.1.2.1.14.10.1';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{nb} = {};
    $self->{global} = { total => 0 };
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_ospfNbrEntry,
        nothing_quit => 1
    );

    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{NbrState}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        
        $self->{global}->{total}++;
        $self->{nb}->{$instance} = { %$result };
    }

    if (scalar(keys %{$self->{nb}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No neighbors found.");
        $self->{output}->option_exit();
    }

    $self->{cache_name} = 'ospf_' . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check neighbor relations.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^status$'

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{NbrState}, %{NbrRtrId}, %{NbrIpAddr}

=item B<--critical-status>

Set critical threshold for status (Default: '%{NbrState} =~ /down/i').
Can used special variables like: %{NbrState}, %{NbrRtrId}, %{NbrIpAddr}

=item B<--warning-total-change>

Set warning threshold. Should be used if there is a difference of total neighbors between two checks.
Example: %{TotalLast} != %{Total}

=item B<--critical-total-change>

Set critical threshold. Should be used if there is a difference of total neighbors between two checks.
Example: %{TotalLast} != %{Total}

=item B<--warning-*>

Threshold warning.
Can be: 'total'.

=item B<--critical-*>

Threshold critical.
Can be: 'total'.

=back

=cut
