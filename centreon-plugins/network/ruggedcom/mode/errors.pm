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

package network::ruggedcom::mode::errors;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my $oid_rcDeviceError = '.1.3.6.1.4.1.15004.4.2.1';
my $oid_rcDeviceErrWatchdogReset = '.1.3.6.1.4.1.15004.4.2.1.2.0';

my $thresholds = {
    error => [
        ['true', 'CRITICAL'],
        ['false', 'OK'],
    ],
};

my %map_errors = (
    2 => 'WatchdogReset',
    3 => 'ConfigurationFailure',
    4 => 'CrashLogCreated',
    5 => 'StackOverflow',
    6 => 'HeapError',
    7 => 'DateAndTimeSetFailed',
    8 => 'NtpServerUnreachable',
    9 => 'BootPTftpTrFailed',
    10 => 'RadiusServerUnreachable',
    11 => 'TacacsServerUnreachable',
);

my %map_state = (
    1 => 'true',
    2 => 'false',
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "exclude:s"         => { name => 'exclude' },
                                  "no-errors:s"       => { name => 'no_errors' },
                                });
  
    $self->{components} = {};
    $self->{no_errors} = undef;
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (defined($self->{option_results}->{no_errors})) {
        if ($self->{option_results}->{no_errors} ne '') {
            $self->{no_errors} = $self->{option_results}->{no_errors};
        } else {
            $self->{no_errors} = 'critical';
        }
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};
    
    $self->{results} = $self->{snmp}->get_table(oid => $oid_rcDeviceError, start => $oid_rcDeviceErrWatchdogReset);
    $self->check_errors();
    
    my $total_errors =  $self->{components}->{error}->{total};
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => sprintf("All %s device errors are ok.", 
                                                     $total_errors
                                                     )
                                );

    if (defined($self->{option_results}->{no_errors}) && $total_errors == 0) {
        $self->{output}->output_add(severity => $self->{no_errors},
                                    short_msg => 'No errors are checked.');
    }

    $self->{output}->display();
    $self->{output}->exit();
}

sub check_exclude {
    my ($self, %options) = @_;

    if (defined($self->{option_results}->{exclude}) && $self->{option_results}->{exclude} =~ /(^|\s|,)#\Q$options{instance}\E#/) {
        $self->{components}->{$options{section}}->{skip}++;
        $self->{output}->output_add(long_msg => sprintf("Skipping $options{instance} instance."));
        return 1;
    }
    return 0;
}

sub get_severity {
    my ($self, %options) = @_;
    my $status = 'UNKNOWN'; # default 

    foreach (@{$thresholds->{$options{section}}}) {           
        if ($options{value} =~ /$$_[0]/i) {
            $status = $$_[1];
            return $status;
        }
    }
    
    return $status;
}

sub check_errors {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking errors");
    $self->{components}->{error} = {name => 'errors', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'error'));

    for (my $i = 1; $i <= 11; $i++) {
        next if (!defined($self->{results}->{$oid_rcDeviceError . '.' . $i . '.0'}));
        my $instance = $map_errors{$i};
        my $state = $self->{results}->{$oid_rcDeviceError . '.' . $i . '.0'};

        next if ($self->check_exclude(section => 'error', instance => $instance));
        
        $self->{components}->{error}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Error '%s' state is %s.",
                                    $instance, $map_state{$state}));
        my $exit = $self->get_severity(section => 'error', value => $map_state{$state});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Error '%s' state is %s.", $instance, $map_state{$state}));
        }
    }
}

1;

__END__

=head1 MODE

Check errors (RUGGEDCOM-SYS-INFO-MIB).

=over 8

=item B<--exclude>

Exclude some instance (Example: --exclude='#WatchdogReset#CrashLogCreated#')

=item B<--no-errors>

Return an error if no errors are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=back

=cut
    
