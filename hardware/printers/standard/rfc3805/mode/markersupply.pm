################################################################################
# Copyright 2005-2013 MERETHIS
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

package hardware::printers::standard::rfc3805::mode::markersupply;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;

# 1 means: do percent calc
my %unit_managed = (
    3 => 1,     # tenThousandthsOfInches(3), -- .0001
    4 => 1,     # micrometers(4),
    12 => 1,    # thousandthsOfOunces(12),
    13 => 1,    # tenthsOfGrams(13),
    14 => 1,    # hundrethsOfFluidOunces(14),
    15 => 1,    # tenthsOfMilliliters(15)
    19 => 0,    # percent(19)
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "warning:s"   => { name => 'warning' },
                                  "critical:s"  => { name => 'critical' },
                                  "filter:s"    => { name => 'filter' },
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
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};
    
    my $oid_prtMarkerSuppliesColorantIndex = '.1.3.6.1.2.1.43.11.1.1.3';
    my $oid_prtMarkerSuppliesDescription = '.1.3.6.1.2.1.43.11.1.1.6';
    my $oid_prtMarkerSuppliesSupplyUnit = '.1.3.6.1.2.1.43.11.1.1.7';
    my $oid_prtMarkerSuppliesMaxCapacity = '.1.3.6.1.2.1.43.11.1.1.8';
    my $oid_prtMarkerSuppliesLevel = '.1.3.6.1.2.1.43.11.1.1.9';
    my $oid_prtMarkerColorantValue = '.1.3.6.1.2.1.43.12.1.1.4';
    my $result = $self->{snmp}->get_table(oid => $oid_prtMarkerSuppliesColorantIndex, nothing_quit => 1);
    
    $self->{snmp}->load(oids => [$oid_prtMarkerSuppliesDescription, $oid_prtMarkerSuppliesSupplyUnit,
                                 $oid_prtMarkerSuppliesMaxCapacity, $oid_prtMarkerSuppliesLevel],
                        instances => [keys %$result], instance_regexp => '(\d+\.\d+)$');
    foreach (keys %$result) {
        if ($result->{$_} != 0) {
            /(\d+)\.(\d+)$/; # $1 = hrDeviceIndex
            $self->{snmp}->load(oids => [$oid_prtMarkerColorantValue . '.' . $1 . '.' . $result->{$_}]);
        }
    }
    
    $self->{output}->output_add(severity => 'OK', 
                                short_msg => "Marker supply usages are ok.");
    
    my $perf_label = {};
    my $result2 = $self->{snmp}->get_leef();
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        $key =~ /(\d+).(\d+)$/;
        my ($hrDeviceIndex, $prtMarkerSuppliesIndex) = ($1, $2);
        my $instance = $hrDeviceIndex . '.' . $prtMarkerSuppliesIndex;
        my $unit = $result2->{$oid_prtMarkerSuppliesSupplyUnit . '.' . $instance};
        my $descr = centreon::plugins::misc::trim($result2->{$oid_prtMarkerSuppliesDescription . '.' . $instance});
        my $current_value = $result2->{$oid_prtMarkerSuppliesLevel . '.' . $instance};
        my $max_value = $result2->{$oid_prtMarkerSuppliesMaxCapacity . '.' . $instance};
        
        if (!defined($unit_managed{$unit})) {
            $self->{output}->output_add(long_msg => "Skipping marker supply '$descr': unit not managed."); 
            next;
        }
        if ($current_value == -1) {
            $self->{output}->output_add(long_msg => "Skipping marker supply '$descr': no level."); 
            next;
        } elsif ($current_value == -2) {
            $self->{output}->output_add(long_msg => "Skipping marker supply '$descr': level unknown."); 
            next;
        } elsif ($current_value == -3) {
            $self->{output}->output_add(long_msg => "Marker supply '$descr': no level but some space remaining."); 
            next;
        }
        if (defined($self->{option_results}->{filter}) && $self->{option_results}->{filter} ne '' &&
            $instance !~ /$self->{option_results}->{filter}/) {
            $self->{output}->output_add(long_msg => "Skipping marker supply '$descr' (instance: $instance): filter."); 
            next;
        }
        
        my $prct_value = $current_value;
        if ($unit_managed{$unit} == 1) {
            $prct_value = $current_value * 100 / $max_value;
        }
        
        my $exit = $self->{perfdata}->threshold_check(value => $prct_value, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);        
        $self->{output}->output_add(long_msg => sprintf("Marker supply '%s': %.2f %% [instance: '%s']", $descr, $prct_value, $hrDeviceIndex . '.' . $prtMarkerSuppliesIndex));
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Marker supply '%s': %.2f %%", $descr, $prct_value));
        }
        
        my $label = $descr;
        if ($result->{$oid_prtMarkerSuppliesColorantIndex . '.' . $instance} != 0) {
            $label = $result2->{$oid_prtMarkerColorantValue . '.' . $hrDeviceIndex . '.' . $result->{$oid_prtMarkerSuppliesColorantIndex . '.' . $instance}};
            if (defined($perf_label->{$label})) {
                $label .= '#' . $hrDeviceIndex . '#' . $prtMarkerSuppliesIndex;
            }
        }
        $perf_label->{$label} = 1;
        
        $self->{output}->perfdata_add(label => $label, unit => '%',
                                      value => sprintf("%.2f", $prct_value),
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                      min => 0, max => 100);
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check marker supply usages.

=over 8

=item B<--warning>

Threshold warning in percent.

=item B<--critical>

Threshold critical in percent.

=item B<--filter>

Filter maker supply instance.

=back

=cut
