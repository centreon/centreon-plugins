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

package network::extreme::snmp::mode::stack;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %mapping_truth = (
    0 => 'disabled',
    1 => 'enable',
    2 => 'disable',
);
my %mapping_stack_status = (
    1 => 'up',
    2 => 'down',
    3 => 'mismatch',
);
my %mapping_stack_role = (
    1 => 'master',
    2 => 'slave',
    3 => 'backup',
);
my $thresholds = {
    stack => [
        ['up', 'OK'],
        ['down', 'CRITICAL'],
        ['mismatch', 'WARNING'],
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
    extremeStackDetection => { oid => '.1.3.6.1.4.1.1916.1.33.1', map => \%mapping_truth },  
};
my $mapping2 = {
    extremeStackMemberOperStatus => { oid => '.1.3.6.1.4.1.1916.1.33.2.1.3', map => \%mapping_stack_status },  
};
my $mapping3 = {
    extremeStackMemberRole => { oid => '.1.3.6.1.4.1.1916.1.33.2.1.4', map => \%mapping_stack_role },  
};
my $mapping4 = {
    extremeStackMemberMACAddress => { oid => '.1.3.6.1.4.1.1916.1.33.2.1.6' },  
};

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    my $results = $self->{snmp}->get_multiple_table(oids => [
                                                            { oid => $mapping->{extremeStackDetection}->{oid} },
                                                            { oid => $mapping2->{extremeStackMemberOperStatus}->{oid} },
                                                            { oid => $mapping3->{extremeStackMemberRole}->{oid} },
                                                            { oid => $mapping4->{extremeStackMemberMACAddress}->{oid} },
                                                            ], nothing_quit => 1);
    
    my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $results->{$mapping->{extremeStackDetection}->{oid}}, instance => '0');
    if ($result->{extremeStackDetection} eq 'disable') {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'Stacking is disable');
        $self->{output}->display();
        $self->{output}->exit();
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'Stack ring is redundant');
    foreach my $oid (keys %{$results->{$mapping2->{extremeStackMemberOperStatus}->{oid}}}) {
        $oid =~ /\.([0-9]+)$/;
        my $instance = $1;

        my $result2 = $self->{snmp}->map_instance(mapping => $mapping2, results => $results->{$mapping2->{extremeStackMemberOperStatus}->{oid}}, instance => $instance);
        my $result3 = $self->{snmp}->map_instance(mapping => $mapping3, results => $results->{$mapping3->{extremeStackMemberRole}->{oid}}, instance => $instance);
        my $result4 = $self->{snmp}->map_instance(mapping => $mapping4, results => $results->{$mapping4->{extremeStackMemberMACAddress}->{oid}}, instance => $instance);
            
        $self->{output}->output_add(long_msg => sprintf("Member '%s' state is %s [Role is '%s'] [Mac: %s]", 
                                                        $instance, $result2->{extremeStackMemberOperStatus}, 
                                                        $result3->{extremeStackMemberRole}, 
                                                        defined($result4->{extremeStackMemberMACAddress}) ? unpack('H*', $result4->{extremeStackMemberMACAddress}) : '-'));
        my $exit = $self->get_severity(section => 'stack', value => $result2->{extremeStackMemberOperStatus});
        if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
            $self->{output}->output_add(severity => $exit,
                                       short_msg => sprintf("Member '%s' state is %s", 
                                                           $instance, $result2->{extremeStackMemberOperStatus}));
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

Check stack status.

=over 8

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='stack,WARNING,mismatch'

=back

=cut
    