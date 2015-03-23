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

package network::paloalto::snmp::mode::clusterstatus;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my $oid_panSysHAState = '.1.3.6.1.4.1.25461.2.1.2.1.11.0'; # '.0' to have the mode
my $oid_panSysHAPeerState = '.1.3.6.1.4.1.25461.2.1.2.1.12.0';
my $oid_panSysHAMode = '.1.3.6.1.4.1.25461.2.1.2.1.13.0';

my $thresholds = {
    peer => [
    ],
    current => [
    ],
};

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                "threshold-overload:s@"  => { name => 'threshold_overload' },
                                });

    return $self;
}

sub check_treshold_overload {
    my ($self, %options) = @_;
    
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

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    $self->check_treshold_overload();
}

sub get_severity {
    my ($self, %options) = @_;
    my $status = 'OK'; # default 
    
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

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};
    
    $self->{result} = $self->{snmp}->get_leef(oids => [ $oid_panSysHAState, $oid_panSysHAPeerState, $oid_panSysHAMode ], 
                                                        nothing_quit => 1);
    
    # Check if mode cluster
    my $ha_mode = $self->{result}->{$oid_panSysHAMode};
    $self->{output}->output_add(long_msg => 'High availabily mode is ' . $ha_mode . '.');
    if ($ha_mode =~ /disabled/i) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => sprintf("No cluster configuration (standalone mode)."));
    } else {
        if ($ha_mode =~ /active-active/i) {
            $thresholds = {
                peer => [
                    ['^active$', 'OK'],
                    ['^passive$', 'CRITICAL'],
                ],
                current => [
                    ['^active$', 'OK'],
                    ['^passive$', 'CRITICAL'],
                ],
            };
        }
        
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => sprintf("Cluster status is ok."));
        
        $self->{output}->output_add(long_msg => sprintf("current high-availability state is %s",
                                                         $self->{result}->{$oid_panSysHAState}));
        my $exit = $self->get_severity(section => 'current', value => $self->{result}->{$oid_panSysHAState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("current high-availability state is %s",
                                                         $self->{result}->{$oid_panSysHAState}));
        }
        
        $self->{output}->output_add(long_msg => sprintf("peer high-availability state is %s",
                                                         $self->{result}->{$oid_panSysHAPeerState}));
        my $exit = $self->get_severity(section => 'peer', value => $self->{result}->{$oid_panSysHAPeerState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("peer high-availability state is %s",
                                                         $self->{result}->{$oid_panSysHAPeerState}));
        }
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check cluster status.

=over 8

=back

=cut