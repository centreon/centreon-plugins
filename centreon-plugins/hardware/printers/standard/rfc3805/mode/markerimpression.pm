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

package hardware::printers::standard::rfc3805::mode::markerimpression;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::statefile;

my %unit_managed = (
    7 => 1,     # impressions(7)
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
                                });
    $self->{statefile_value} = centreon::plugins::statefile->new(%options);
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
    $self->{statefile_value}->check_options(%options);
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};
    $self->{hostname} = $self->{snmp}->get_hostname();
    $self->{snmp_port} = $self->{snmp}->get_port();
    
    my $new_datas = {};
    $new_datas->{last_timestamp} = time();
    $self->{statefile_value}->read(statefile => "snmpstandard_" . $self->{hostname}  . '_' . $self->{snmp_port} . '_' . $self->{mode});
    my $old_timestamp = $self->{statefile_value}->get(name => 'last_timestamp');
    
    my $oid_prtMarkerCounterUnit = '.1.3.6.1.2.1.43.10.2.1.3';
    my $oid_prtMarkerLifeCount = '.1.3.6.1.2.1.43.10.2.1.4';
    my $result = $self->{snmp}->get_table(oid => $oid_prtMarkerLifeCount, nothing_quit => 1);
    
    $self->{snmp}->load(oids => [$oid_prtMarkerCounterUnit],
                        instances => [keys %$result], instance_regexp => '(\d+\.\d+)$');
    
    $self->{output}->output_add(severity => 'OK', 
                                short_msg => "Marker impressions are ok.");
    
    my $perf_label = {};
    my $result2 = $self->{snmp}->get_leef();
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        $key =~ /(\d+).(\d+)$/;
        my ($hrDeviceIndex, $prtMarkerIndex) = ($1, $2);
        my $instance = $hrDeviceIndex . '.' . $prtMarkerIndex;
        my $counter_unit = $result2->{$oid_prtMarkerCounterUnit . '.' . $instance};
        $new_datas->{'lifecount_' . $instance} = $result->{$key};
        
        if (!defined($unit_managed{$counter_unit})) {
            $self->{output}->output_add(long_msg => "Skipping marker '" . $hrDeviceIndex . '#' . $prtMarkerIndex . "': unit not managed."); 
            next;
        }
        
        my $old_life_count = $self->{statefile_value}->get(name => 'lifecount_' . $instance);
        if (!defined($old_timestamp) || !defined($old_life_count)) {
            next;
        }
        
        if ($old_life_count > $new_datas->{'lifecount_' . $instance}) {
            $old_life_count = 0;
        }
        my $value = $new_datas->{'lifecount_' . $instance} - $old_life_count;
        
        my $exit = $self->{perfdata}->threshold_check(value => $value, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);        
        $self->{output}->output_add(long_msg => sprintf("Marker impressions '%s': %s", $hrDeviceIndex . '#' . $prtMarkerIndex, $value));
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Marker impressions '%s': %s", $hrDeviceIndex . '#' . $prtMarkerIndex, $value));
        }
        
        my $label = 'impressions';
        if (defined($perf_label->{$label})) {
            $label .= '#' . $hrDeviceIndex . '#' . $prtMarkerIndex;
        }
        $perf_label->{$label} = 1;
        
        $self->{output}->perfdata_add(label => $label,
                                      value => $value,
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                      min => 0);
    }
    
    $self->{statefile_value}->write(data => $new_datas);    
    if (!defined($old_timestamp)) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => "Buffer creation...");
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check marker impressions between two checks.

=over 8

=item B<--warning>

Threshold warning.

=item B<--critical>

Threshold critical.

=back

=cut
