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

package os::aix::snmp::mode::swap;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    my $msg = sprintf("Usage Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
                   $total_size_value . " " . $total_size_unit,
                   $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
                   $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free});
    return $msg;
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    return -10 if ($options{new_datas}->{$self->{instance} . '_total'} <= 0);
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_total'};
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_used'};
    $self->{result_values}->{free} = $self->{result_values}->{total} - $self->{result_values}->{used};
    $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
    $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, message_separator => ' - ', cb_init => 'skip_global', },
        { name => 'swap', type => 1, cb_prefix_output => 'prefix_swap_output', message_multiple => 'All Page spaces are ok' },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total-usage', nlabel => 'page.space.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'total' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                threshold_use => 'prct_used',
                perfdatas => [
                    { label => 'total_page_space', value => 'used', template => '%s', cast_int => 1,
                      unit => 'B', min => 0, max => 'total', threshold_total => 'total' },
                ],
            }
        },
        { label => 'total-active', nlabel => 'page.space.active.count', display_ok => 0, set => {
                key_values => [ { name => 'nactive' }, { name => 'ntotal' } ],
                output_template => 'Total page space active : %s',
                perfdatas => [
                    { label => 'total_active', value => 'nactive', template => '%s',
                      min => 0, max => 'ntotal' },
                ],
            }
        },
    ];

    $self->{maps_counters}->{swap} = [
        { label => 'usage', nlabel => 'page.space.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'total' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                threshold_use => 'prct_used',
                perfdatas => [
                    { label => 'page_space', value => 'used', template => '%s', cast_int => 1,
                      unit => 'B', min => 0, max => 'total', threshold_total => 'total',
                      label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}


sub prefix_swap_output {
    my ($self, %options) = @_;

    return "Page space '" . $options{instance_value}->{display} . "' ";
}

sub skip_global {
    my ($self, %options) = @_;

    scalar(keys %{$self->{swap}}) > 1 ? return(0) : return(1);
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'paging-state-buggy'    => { name => 'paging_state_buggy' },
    });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    # sysDescr values:
    # Aix 5.2: .*Base Operating System Runtime AIX version: 05.02.*
    # Aix 5.3: .*Base Operating System Runtime AIX version: 05.03.*
    # Aix 6.1: .*Base Operating System Runtime AIX version: 06.01.*
    # Aix 7.1: .*Base Operating System Runtime AIX version: 07.01.*
    
    my $oid_sysDescr        = ".1.3.6.1.2.1.1.1"; 
    my $aix_swap_pool       = ".1.3.6.1.4.1.2.6.191.2.4.2.1";    # aixPageEntry
    my $aix_swap_name       = ".1.3.6.1.4.1.2.6.191.2.4.2.1.1";  # aixPageName
    my $aix_swap_total      = ".1.3.6.1.4.1.2.6.191.2.4.2.1.4";  # aixPageSize (in MB)
    my $aix_swap_usage      = ".1.3.6.1.4.1.2.6.191.2.4.2.1.5";  # aixPagePercentUsed
    my $aix_swap_status     = ".1.3.6.1.4.1.2.6.191.2.4.2.1.6";  # aixPageStatus
    my $aix_swap_index      = ".1.3.6.1.4.1.2.6.191.2.4.2.1.8";
    
    my @indexes = ();
    my $results = $options{snmp}->get_multiple_table(
        oids => [ 
            { oid => $aix_swap_pool },
            { oid => $oid_sysDescr },
        ]
    );
    
    foreach my $key (keys %{$results->{$aix_swap_pool}}) {
        if ($key =~ /^$aix_swap_name\.(.*)/ ) {
            push @indexes, $1;
        }
    }
    
    if (scalar(@indexes) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No paging space found.");
        $self->{output}->option_exit();
    }
    
    #  Check if the paging space is active.
    #  Values are :
    #   1 = "active"
    #   2 = "notActive"
    #  On AIX 5.x it's ok. But in AIX 6.x, 7.x, it's the contrary ??!!!
    my $active_swap = 2;
    if ($results->{$oid_sysDescr}->{$oid_sysDescr . ".0"} =~ /AIX version: 05\./i) {
        $active_swap = 1;
    }
    if (defined($self->{option_results}->{paging_state_buggy})) {
        if ($active_swap == 2) {
            $active_swap = 1;
        } else {
            $active_swap = 2;
        }
    }

    $self->{global} = { nactive => 0, ntotal => 0, total => 0, used => 0 };
    $self->{swap} = {};
    foreach (@indexes) {
        $self->{global}->{ntotal}++;
        
        if ($results->{$aix_swap_pool}->{$aix_swap_status . "." . $_} == $active_swap) {
            $self->{global}->{nactive}++;
            
            my $swap_name = $results->{$aix_swap_pool}->{$aix_swap_name . "." . $_};
            my $used = ($results->{$aix_swap_pool}->{$aix_swap_usage . "." . $_} * $results->{$aix_swap_pool}->{$aix_swap_total . "." . $_} / 100) 
                * 1024 * 1024;
            my $total = $results->{$aix_swap_pool}->{$aix_swap_total . "." . $_} * 1024 * 1024;
            $self->{swap}->{$swap_name} = {
                display => $swap_name,
                used => $used,
                total => $total,
            };
            $self->{global}->{used} += $used;
            $self->{global}->{total} += $total;
        }
    }
}

1;

__END__

=head1 MODE

Check AIX swap memory.

=over 8

=item B<--warning-usage>

Threshold warning in percent.

=item B<--critical-usage>

Threshold critical in percent.

=item B<--warning-total-usage>

Threshold warning in percent.

=item B<--critical-total-usage>

Threshold critical in percent.

=item B<--warning-total-active>

Threshold warning total page space active.

=item B<--critical-total-active>

Threshold critical total page space active.

=item B<--paging-state-buggy>

Paging state can be buggy. Please use the following option to swap state value.

=back

=cut
