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

package hardware::server::hpbladechassis::mode::components::blade;

my %conditions = (
    1 => ['other', 'CRITICAL'], 
    2 => ['ok', 'OK'], 
    3 => ['degraded', 'WARNING'], 
    4 => ['failed', 'CRITICAL'],
);

my %present_map = (
    1 => 'other',
    2 => 'absent',
    3 => 'present',
    4 => 'Weird!!!', # for blades it can return 4, which is NOT spesified in MIB
);

sub check {
    my ($self) = @_;

    $self->{components}->{blades} = {name => 'blades', total => 0};
    $self->{output}->output_add(long_msg => "Checking blades");
    return if ($self->check_exclude('blades'));
    
    my $oid_cpqRackServerBladePresent = '.1.3.6.1.4.1.232.22.2.4.1.1.1.12';
    my $oid_cpqRackServerBladeIndex = '.1.3.6.1.4.1.232.22.2.4.1.1.1.3';
    my $oid_cpqRackServerBladeName = '.1.3.6.1.4.1.232.22.2.4.1.1.1.4';
    my $oid_cpqRackServerBladePartNumber = '.1.3.6.1.4.1.232.22.2.4.1.1.1.6';
    my $oid_cpqRackServerBladeSparePartNumber = '.1.3.6.1.4.1.232.22.2.4.1.1.1.7';
    my $oid_cpqRackServerBladeProductId = '.1.3.6.1.4.1.232.22.2.4.1.1.1.17';
    my $oid_cpqRackServerBladeStatus = '.1.3.6.1.4.1.232.22.2.4.1.1.1.21'; # v2
    my $oid_cpqRackServerBladeFaultDiagnosticString = '.1.3.6.1.4.1.232.22.2.4.1.1.1.24'; # v2
    
    my $result = $self->{snmp}->get_table(oid => $oid_cpqRackServerBladePresent);
    return if (scalar(keys %$result) <= 0);
    my @get_oids = ();
    my @oids_end = ();
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        next if ($present_map{$result->{$key}} ne 'present');
        $key =~ /\.([0-9]+)$/;
        my $oid_end = $1;
        
        push @oids_end, $oid_end;
        push @get_oids, $oid_cpqRackServerBladeIndex . "." . $oid_end, $oid_cpqRackServerBladeName . "." . $oid_end,
                $oid_cpqRackServerBladePartNumber . "." . $oid_end, $oid_cpqRackServerBladeSparePartNumber . "." . $oid_end,
                $oid_cpqRackServerBladeProductId . "." . $oid_end, 
                $oid_cpqRackServerBladeStatus . "." . $oid_end, $oid_cpqRackServerBladeFaultDiagnosticString . "." . $oid_end;
    }

    $result = $self->{snmp}->get_leef(oids => \@get_oids);
    foreach (@oids_end) {
        my $blade_index = $result->{$oid_cpqRackServerBladeIndex . '.' . $_};
        my $blade_status = defined($result->{$oid_cpqRackServerBladeStatus . '.' . $_}) ? $result->{$oid_cpqRackServerBladeStatus . '.' . $_} : '';
        my $blade_name = $result->{$oid_cpqRackServerBladeName . '.' . $_};
        my $blade_part = $result->{$oid_cpqRackServerBladePartNumber . '.' . $_};
        my $blade_spare = $result->{$oid_cpqRackServerBladeSparePartNumber . '.' . $_};
        my $blade_productid = $result->{$oid_cpqRackServerBladeProductId . '.' . $_};
        my $blade_diago = defined($result->{$oid_cpqRackServerBladeFaultDiagnosticString . '.' . $_}) ? $result->{$oid_cpqRackServerBladeFaultDiagnosticString . '.' . $_} : '';
        
        $self->{components}->{blades}->{total}++;
        if ($blade_status eq '') {
            $self->{output}->output_add(long_msg => sprintf("Skipping Blade %d (%s, %s). Cant get status.",
                                        $blade_index, $blade_name, $blade_productid));
            next;
        }
        $self->{output}->output_add(long_msg => sprintf("Blade %d (%s, %s) status is %s [part: %s, spare: %s]%s.",
                                    $blade_index, $blade_name, $blade_productid,
                                    ${$conditions{$blade_status}}[0],
                                    $blade_part, $blade_spare,
                                    ($blade_diago ne '') ? " (Diagnostic '$blade_diago')" : ''
                                    ));
        if ($blade_status != 2) {
            $self->{output}->output_add(severity =>  ${$conditions{$blade_status}}[1],
                                        short_msg => sprintf("Blade %d (%s, %s) status is %s",
                                            $blade_index, $blade_name, $blade_productid,
                                            ${$conditions{$blade_status}}[0]
                                       ));
        }
    }
}

1;