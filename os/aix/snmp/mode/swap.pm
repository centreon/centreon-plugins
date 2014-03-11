################################################################################
# Copyright 2005-2014 MERETHIS
# Centreon is developped by : Julien Mathis and Romain Le Merlus under
# GPL Licence 2.0.
# 
# This program is free software; you can redistribute it and/or modify it under 
# the terms of the GNU General Public License as published by the Free Software 
# Foundation ; either version 2 of the License.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along with 
# this program; if not, see <http://www.gnu.org/licenses>.
# 
# Linking this program statically or dynamically with other modules is making a 
# combined work based on this program. Thus, the terms and conditions of the GNU 
# General Public License cover the whole combination.
# 
# As a special exception, the copyright holders of this program give MERETHIS 
# permission to link this program with independent modules to produce an executable, 
# regardless of the license terms of these independent modules, and to copy and 
# distribute the resulting executable under terms of MERETHIS choice, provided that 
# MERETHIS also meet, for each linked independent module, the terms  and conditions 
# of the license of that module. An independent module is a module which is not 
# derived from this program. If you modify this program, you may extend this 
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
# 
# For more information : contact@centreon.com
# Authors : Quentin Garnier <qgarnier@merethis.com>
#
####################################################################################

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
                                });

    $self->{swap_memory_id} = undef;
    
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
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    my $aix_swap_pool       = ".1.3.6.1.4.1.2.6.191.2.4.2.1";    # aixPageEntry
    my $aix_swap_name       = ".1.3.6.1.4.1.2.6.191.2.4.2.1.1";  # aixPageName
    my $aix_swap_total      = ".1.3.6.1.4.1.2.6.191.2.4.2.1.4";  # aixPageSize (in MB)
    my $aix_swap_usage      = ".1.3.6.1.4.1.2.6.191.2.4.2.1.5";  # aixPagePercentUsed
    my $aix_swap_status     = ".1.3.6.1.4.1.2.6.191.2.4.2.1.6";  # aixPageStatus
    my $aix_swap_index      = ".1.3.6.1.4.1.2.6.191.2.4.2.1.8";
    
    my @indexes = ();
    my $result = $self->{snmp}->get_table(oid => $aix_swap_pool);
    
    foreach my $key (keys %$result) {
        if ($key =~ /^$aix_swap_index/ ) {
            $key =~ /\.([0-9]+)$/;
            push @indexes, $1;
        }
    }
    
    if (scalar(@indexes) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No paging space found.");
        $self->{output}->option_exit();
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'All Page spaces are ok.');
    my $nactive = 0;
    foreach (@indexes) {
        #  Check if the paging space is active.
        #  Values are :
        #   1 = "active"
        #   2 = "notActive"
        #  We set "notActive" because of aixmibd seem to give false status.
        if ($result->{$aix_swap_status . "." . $_} == 1) {
            $nactive = 1;
            my $swap_total = $result->{$aix_swap_total . "." . $_} * 1024 * 1024;
            my $prct_used = $result->{$aix_swap_usage . "." . $_};
            my $total_used = $prct_used * $swap_total  / 100;

            my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $swap_total);
            my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $total_used);
            my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $swap_total - $total_used);
            my $exit = $self->{perfdata}->threshold_check(value => $prct_used, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Page space '%s' Total: %s Used: %s (%.2f%%) Free: %s (%d%%)", $result->{$aix_swap_name . "." . $_},
                                                $total_size_value . " " . $total_size_unit,
                                                $total_used_value . " " . $total_used_unit, $total_used * 100 / $swap_total,
                                                $total_free_value . " " . $total_free_unit, 100 - ($total_used * 100 / $result->{$aix_swap_total . "." . $_})));
            }
            
            $self->{output}->output_add(long_msg => sprintf("Page space '%s' Total: %s Used: %s (%.2f%%) Free: %s (%d%%)", $result->{$aix_swap_name . "." . $_},
                                                $total_size_value . " " . $total_size_unit,
                                                $total_used_value . " " . $total_used_unit, $total_used * 100 / $swap_total,
                                                $total_free_value . " " . $total_free_unit, 100 - ($total_used * 100 / $swap_total)));
            $self->{output}->perfdata_add(label => 'page_space_' . $result->{$aix_swap_name . "." . $_}, unit => 'B',
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

=back

=cut
