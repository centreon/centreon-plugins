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

package storage::netapp::snmp::mode::nvram;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %mapping_nvram_state = (
    1 => 'ok',
    2 => 'partiallyDischarged',
    3 => 'fullyDischarged',
    4 => 'notPresent',
    5 => 'nearEndOfLife',
    6 => 'atEndOfLife',
    7 => 'unknown',
    8 => 'overCharged',
    9 => 'fullyCharged',
);

my $thresholds = {
    nvram => [
        ['ok', 'OK'],
        ['partiallyDischarged', 'WARNING'],
        ['fullyDischarged', 'CRITICAL'],
        ['notPresent', 'CRITICAL'],
        ['nearEndOfLife', 'WARNING'],
        ['atEndOfLife', 'CRITICAL'],
        ['unknown', 'UNKNOWN'],
        ['overCharged', 'OK'],
        ['fullyCharged', 'OK'],
    ],
};

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "threshold-overload:s@"   => { name => 'threshold_overload' },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    $self->{overload_th} = {};
    foreach my $val (@{$self->{option_results}->{threshold_overload}}) {
        if ($val !~ /^(.*?),(.*?),(.*)$/) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload option '" . $val . "'.");
            $self->{output}->option_exit();
        }
        my ($section, $status, $filter) = ($1, $2, $3);
        if ($self->{output}->is_litteral_status(status => $status) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload status '" . $val . "'.");
            $self->{output}->option_exit();
        }
        $self->{overload_th}->{$section} = [] if (!defined($self->{overload_th}->{$section}));
        push @{$self->{overload_th}->{$section}}, {filter => $filter, status => $status};
    }
}

my $mapping = {
    nvramBatteryStatus => { oid => '.1.3.6.1.4.1.789.1.2.5.1', map => \%mapping_nvram_state },  
};
my $mapping2 = {
    nodeNvramBatteryStatus => { oid => '.1.3.6.1.4.1.789.1.25.2.1.17', map => \%mapping_nvram_state },  
};

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    my $oid_nodeName = '.1.3.6.1.4.1.789.1.25.2.1.1';
    my $results = $self->{snmp}->get_multiple_table(oids => [
                                                            { oid => $mapping->{nvramBatteryStatus}->{oid} },
                                                            { oid => $oid_nodeName },
                                                            { oid => $mapping2->{nodeNvramBatteryStatus}->{oid} },
                                                            ], nothing_quit => 1);
    
    if (defined($results->{$mapping->{nvramBatteryStatus}->{oid}}->{$mapping->{nvramBatteryStatus}->{oid} . '.0'})) {
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $results->{$mapping->{nvramBatteryStatus}->{oid}}, instance => '0');
        my $exit = $self->get_severity(section => 'nvram', value => $result->{nvramBatteryStatus});
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("NVRAM Batteries status is '%s'", $result->{nvramBatteryStatus}));
    } else {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'NVRAM Batteries status are ok on all nodes');
        foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$results->{$mapping2->{nodeNvramBatteryStatus}->{oid}}})) {
            $oid =~ /^$mapping2->{nodeNvramBatteryStatus}->{oid}\.(.*)$/;
            my $instance = $1;
            my $name = $results->{$oid_nodeName}->{$oid_nodeName . '.' . $instance};
            my $result = $self->{snmp}->map_instance(mapping => $mapping2, results => $results->{$mapping2->{nodeNvramBatteryStatus}->{oid}}, instance => $instance);
            
            my $exit = $self->get_severity(section => 'nvram', value => $result->{nodeNvramBatteryStatus});
            $self->{output}->output_add(long_msg => sprintf("NVRAM Batteries status is '%s' on node '%s'", 
                                                            $result->{nodeNvramBatteryStatus}, $name));
            if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("NVRAM Batteries status is '%s' on node '%s'", 
                                                            $result->{nodeNvramBatteryStatus}, $name));
            }
        }
    }

    $self->{output}->display();
    $self->{output}->exit();
}

sub get_severity {
    my ($self, %options) = @_;
    my $status = 'UNKNOWN'; # default 
    
    if (defined($self->{overload_th}->{$options{section}})) {
        foreach (@{$self->{overload_th}->{$options{section}}}) {            
            if ($options{value} =~ /$_->{filter}/i) {
                $status = $_->{status};
                return $status;
            }
        }
    }
    foreach (@{$thresholds->{$options{section}}}) {           
        if ($options{value} =~ /$$_[0]/i) {
            $status = $$_[1];
            return $status;
        }
    }
    
    return $status;
}

1;

__END__

=head1 MODE

Check current status of the NVRAM batteries.

=over 8

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='nvram,CRITICAL,^(?!(ok)$)'

=back

=cut
    