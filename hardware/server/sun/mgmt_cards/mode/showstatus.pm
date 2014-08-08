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

package hardware::server::sun::mgmt_cards::mode::showstatus;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;

my $thresholds = [
    ['Faulted', 'CRITICAL'],
    ['Degraded', 'WARNING'],
    ['Deconfigured', 'WARNING'],
    ['Maintenance', 'OK'],
    ['Normal', 'OK'],
];

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "hostname:s"       => { name => 'hostname' },
                                  "username:s"       => { name => 'username' },
                                  "password:s"       => { name => 'password' },
                                  "timeout:s"        => { name => 'timeout', default => 30 },
                                  "command-plink:s"  => { name => 'command_plink', default => 'plink' },
                                  "threshold-overload:s@"   => { name => 'threshold_overload' },
                                  "exclude:s@"              => { name => 'exclude' },
                                });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{hostname})) {
       $self->{output}->add_option_msg(short_msg => "Need to specify a hostname.");
       $self->{output}->option_exit(); 
    }
    if (!defined($self->{option_results}->{username})) {
       $self->{output}->add_option_msg(short_msg => "Need to specify a username.");
       $self->{output}->option_exit(); 
    }
    if (!defined($self->{option_results}->{password})) {
       $self->{output}->add_option_msg(short_msg => "Need to specify a password.");
       $self->{output}->option_exit(); 
    }
    
    $self->{overload_th} = [];
    foreach my $val (@{$self->{option_results}->{threshold_overload}}) {
        if ($val !~ /^(.*?),(.*)$/) {
            $self->{output}->add_option_msg(short_msg => "Wrong treshold-overload option '" . $val . "'.");
            $self->{output}->option_exit();
        }
        my ($status, $filter) = ($1, $2);
        if ($self->{output}->is_litteral_status(status => $status) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong treshold-overload status '" . $val . "'.");
            $self->{output}->option_exit();
        }
        push @{$self->{overload_th}}, {filter => $filter, status => $status};
    }
}

sub get_severity {
    my ($self, %options) = @_;
    my $status = 'unknown'; # default 
    
    foreach (@{$self->{overload_th}}) {
        if ($options{value} =~ /$_->{filter}/msi) {
            $status = $_->{status};
            return $status;
        }
    }
    foreach (@{$thresholds}) {
        if ($options{value} =~ /$$_[0]/msi) {
            $status = $$_[1];
            return $status;
        }
    }

    return $status;
}

sub check_exclude {
    my ($self, %options) = @_;

    foreach (@{$self->{option_results}->{exclude}}) {
        if ($options{value} =~ /$_/i) {
            $self->{output}->output_add(long_msg => sprintf("Skip Component '%s'",
                                                            $options{value}));
            return 1;
        }
    }
    
    return 0;
}

sub check_tree {
    my ($self) = @_;
    
    my $total_components = 0;
    my @stack = ({ indent => 0, long_instance => '', long_status => ''});
    while ($self->{stdout} =~ /^([* \t]+)(.*)\s+Status:(.+?);/mg) {
        my ($indent, $unit_number, $status) = (length($1), $2, $3);
        my ($long_instance, $long_status);
        
        while ($indent <= $stack[$#stack]->{indent}) {
            pop @stack;
        }
        
        $long_instance = $stack[$#stack]->{long_instance} . '>' . $unit_number;
        $long_status = $stack[$#stack]->{long_status} . ' > ' . $unit_number . ' Status:' . $status;
        if ($indent > $stack[$#stack]->{indent}) {
            push @stack, { indent => $indent, 
                           long_instance => $stack[$#stack]->{long_instance} . '>' . $unit_number,
                           long_status => $stack[$#stack]->{long_status} . ' > ' . $unit_number . ' Status:' . $status };
        }
        
        next if ($self->check_exclude(value => $long_instance));
        
        my $exit = $self->get_severity(value => $status);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Component '%s' status is '%s'",
                                                             $unit_number, $status));
        }
        
        $self->{output}->output_add(long_msg => sprintf("Component '%s' status is '%s' [%s] [%s]",
                                                        $unit_number, $status, $long_instance, $long_status));
        $total_components++;
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => sprintf("All %s components are ok.", 
                                                     $total_components)
                                );
}

sub run {
    my ($self, %options) = @_;
    my ($lerror, $exit_code);
    
    ######
    # Command execution
    ######
    ($lerror, $self->{stdout}, $exit_code) = centreon::plugins::misc::backtick(
                                                 command => $self->{option_results}->{command_plink},
                                                 timeout => $self->{option_results}->{timeout},
                                                 arguments => ['-batch', '-l', $self->{option_results}->{username}, 
                                                               '-pw', $self->{option_results}->{password},
                                                               $self->{option_results}->{hostname}, 'showhardconf'],
                                                 wait_exit => 1,
                                                 redirect_stderr => 1
                                                 );
    $self->{stdout} =~ s/\r//g;
    if ($lerror <= -1000) {
        $self->{output}->output_add(severity => 'UNKNOWN', 
                                    short_msg => $self->{stdout});
        $self->{output}->display();
        $self->{output}->exit();
    }
    if ($exit_code != 0) {
        $self->{stdout} =~ s/\n/ - /g;
        $self->{output}->output_add(severity => 'UNKNOWN', 
                                    short_msg => "Command error: $self->{stdout}");
        $self->{output}->display();
        $self->{output}->exit();
    }
   
    $self->check_tree();
 
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Sun Mxxxx (M3000, M4000,...) Hardware (through XSCF).

=over 8

=item B<--hostname>

Hostname to query.

=item B<--username>

ssh username.

=item B<--password>

ssh password.

=item B<--command-plink>

Plink command (default: plink). Use to set a path.

=item B<--timeout>

Timeout in seconds for the command (Default: 30).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='UNKNOWN,Normal'

=item B<--exclude>

Filter components (multiple) (can be a regexp).
Example: --exclude='MEM#2B' --exclude='MBU_A>MEM#0B'.

=back

=cut
