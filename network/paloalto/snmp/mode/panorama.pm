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

package network::paloalto::snmp::mode::panorama;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my $thresholds = {
    panorama => [
        ['^connected$', 'OK'],
        ['^non-connected$', 'CRITICAL'],
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
                                "exclude:s"              => { name => 'exclude' },
                                });

    return $self;
}

sub check_treshold_overload {
    my ($self, %options) = @_;
    
    $self->{overload_th} = {};
    foreach my $val (@{$self->{option_results}->{threshold_overload}}) {
        if ($val !~ /^(.*?),(.*)$/) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload option '" . $val . "'.");
            $self->{output}->option_exit();
        }
        my ($section, $status, $filter) = ('panorama', $2, $3);
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

sub check_exclude {
    my ($self, %options) = @_;

    if (defined($self->{option_results}->{exclude}) && $self->{option_results}->{exclude} =~ /(^|\s|,)${options{section}}[^,]*#\Q$options{instance}\E#/) {
        $self->{output}->output_add(long_msg => sprintf("Skipping options{instance} instance."));
        return 1;
    }
    return 0;
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

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    my $oid_panMgmtPanoramaConnected = '.1.3.6.1.4.1.25461.2.1.2.4.1.0';
    my $oid_panMgmtPanorama2Connected = '.1.3.6.1.4.1.25461.2.1.2.4.2.0';
    my $result = $self->{snmp}->get_leef(oids => [$oid_panMgmtPanoramaConnected, $oid_panMgmtPanorama2Connected], nothing_quit => 1);
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'Panorama connection statuses are ok.');
    if (!$self->check_exclude(section => 'panorama', instance => 1)) {
        my $exit = $self->get_severity(section => 'panorama', value => $result->{$oid_panMgmtPanoramaConnected});
        $self->{output}->output_add(long_msg => sprintf("panorama '1' connection status is %s",
                                                         $result->{$oid_panMgmtPanoramaConnected}));
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("panorama '1' connection status is %s",
                                                             $result->{$oid_panMgmtPanoramaConnected}));
        }
    }
    if (!$self->check_exclude(section => 'panorama', instance => 2)) {
        my $exit = $self->get_severity(section => 'panorama', value => $result->{$oid_panMgmtPanorama2Connected});
        $self->{output}->output_add(long_msg => sprintf("panorama '2' connection status is %s",
                                                         $result->{$oid_panMgmtPanorama2Connected}));
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("panorama '2' connection status is %s",
                                                             $result->{$oid_panMgmtPanorama2Connected}));
        }
    }
    

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check panorama connection status.

=over 8

=item B<--threshold-overload>

Set to overload default threshold value.
Example: --threshold-overload='(not-connected)=warning'

=item B<--exclude>

Exclude some parts (comma seperated list)
Can also exclude specific instance: --exclude=panorama#2#

=back

=cut
    