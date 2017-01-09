#
# Copyright 2017 Centreon (http://www.centreon.com/)
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

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "warning:s"               => { name => 'warning' },
                                  "critical:s"              => { name => 'critical' },
                                  "paging-state-buggy"      => { name => 'paging_state_buggy' },
                                });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
       $self->{output}->option_exit();
    }    
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

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
    my $results = $self->{snmp}->get_multiple_table(oids => [ 
                                                        { oid => $aix_swap_pool },
                                                        { oid => $oid_sysDescr },
                                                    ]);
    
    foreach my $key (keys %{$results->{$aix_swap_pool}}) {
        if ($key =~ /^$aix_swap_index\.(.*)/ ) {
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
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'All Page spaces are ok.');
    my $nactive = 0;
    foreach (@indexes) {
       
        if ($results->{$aix_swap_pool}->{$aix_swap_status . "." . $_} == $active_swap) {
            $nactive = 1;
            my $swap_name = $results->{$aix_swap_pool}->{$aix_swap_name . "." . $_};
            my $swap_total = $results->{$aix_swap_pool}->{$aix_swap_total . "." . $_} * 1024 * 1024;
            my $prct_used = $results->{$aix_swap_pool}->{$aix_swap_usage . "." . $_};
            my $total_used = $prct_used * $swap_total  / 100;

            my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $swap_total);
            my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $total_used);
            my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $swap_total - $total_used);
            my $exit = $self->{perfdata}->threshold_check(value => $prct_used, threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Page space '%s' Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)", $swap_name,
                                                $total_size_value . " " . $total_size_unit,
                                                $total_used_value . " " . $total_used_unit, $total_used * 100 / $swap_total,
                                                $total_free_value . " " . $total_free_unit, 100 - ($total_used * 100 / $swap_total)));
            }
            
            $self->{output}->output_add(long_msg => sprintf("Page space '%s' Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)", $swap_name,
                                                $total_size_value . " " . $total_size_unit,
                                                $total_used_value . " " . $total_used_unit, $total_used * 100 / $swap_total,
                                                $total_free_value . " " . $total_free_unit, 100 - ($total_used * 100 / $swap_total)));
            $self->{output}->perfdata_add(label => 'page_space_' . $swap_name, unit => 'B',
                                          value => int($total_used),
                                          warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning', total => $total_used, cast_int => 1),
                                          critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical', total => $total_used, cast_int => 1),
                                          min => 0, max => $swap_total);
        }
    }
    
    if ($nactive == 0) {
        $self->{output}->output_add(severity => 'WARNING',
                                    short_msg => 'No paging space active.');
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check AIX swap memory.

=over 8

=item B<--warning>

Threshold warning in percent.

=item B<--critical>

Threshold critical in percent.

=item B<--paging-state-buggy>

Paging state can be buggy. Please use the following option to swap state value.

=back

=cut
