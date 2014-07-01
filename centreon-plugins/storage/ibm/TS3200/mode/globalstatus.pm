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

package storage::ibm::TS3200::mode::globalstatus;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %states = (
    1 => ['other', 'WARNING'], 
    2 => ['unknown', 'WARNING'], 
    3 => ['ok', 'OK'], 
    4 => ['non critical', 'WARNING'],
    5 => ['critical', 'CRITICAL'],
    6 => ['nonRecoverable', 'WARNING'],
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                "threshold-overload:s@"     => { name => 'threshold_overload' },
                                });

    return $self;
}

sub check_treshold_overload {
    my ($self, %options) = @_;
    
    $self->{overload_th} = {};
    foreach my $val (@{$self->{option_results}->{threshold_overload}}) {
        if ($val !~ /(.*?)=(.*)/) {
            $self->{output}->add_option_msg(short_msg => "Wrong treshold-overload option '" . $val . "'.");
            $self->{output}->option_exit();
        }
        my ($filter, $threshold) = ($1, $2);
        if ($self->{output}->is_litteral_status(status => $threshold) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong treshold-overload status '" . $val . "'.");
            $self->{output}->option_exit();
        }
        $self->{overload_th}->{$filter} = $threshold;
    }
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub get_severity {
    my ($self, %options) = @_;
    my $status = ${$states{$options{value}}}[1];
    
    foreach (keys %{$self->{overload_th}}) {
        if (${$states{$options{value}}}[0] =~ /$_/) {
            $status = $self->{overload_th}->{$_};
        }
    }
    return $status;
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    my $oid_ibm3200StatusGlobalStatus = '.1.3.6.1.4.1.2.6.211.2.1.0';
    my $result = $self->{snmp}->get_leef(oids => [$oid_ibm3200StatusGlobalStatus], nothing_quit => 1);
    
    $self->{output}->output_add(severity => $self->get_severity(value => $result->{$oid_ibm3200StatusGlobalStatus}),
                                short_msg => sprintf("Overall global status is '%s'.", 
                                                ${$states{$result->{$oid_ibm3200StatusGlobalStatus}}}[0]));

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check the overall status of the appliance.

=over 8

=item B<--threshold-overload>

Set to overload default threshold value.
Example: --threshold-overload='(unknown|non critical)=critical'

=back

=cut
    