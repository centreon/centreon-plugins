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

package centreon::common::emc::navisphere::mode::cache;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %states = (
    read_cache => [
        ['^enabled$'   , 'OK'],
        ['^disabling$' , 'CRITICAL'], 
        ['^disabled$'  , 'CRITICAL'], 
        ['^.*$'        , 'CRITICAL'], 
    ],
    write_cache => [
        ['^enabled$'    , 'OK'],
        ['^disabled$'   , 'CRITICAL'],
        ['^enabling$'   , 'OK'],
        ['^initializing$' , 'WARNING'],
        ['^dumping$'      , 'CRITICAL'],
        ['^frozen$'       , 'CRITICAL'],
        ['^.*$'           , 'CRITICAL'],
    ],
    write_mirror => [
        ['^yes$'    , 'OK'],
        ['^.*$'     , 'CRITICAL'],
    ],
);


sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                "threshold-overload:s@"     => { name => 'threshold_overload' },
                                "warning:s"               => { name => 'warning', },
                                "critical:s"              => { name => 'critical', },
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
    $self->{overload_th} = {};
    foreach my $val (@{$self->{option_results}->{threshold_overload}}) {
        if ($val !~ /(.*?):(.*?)=(.*)/) {
            $self->{output}->add_option_msg(short_msg => "Wrong treshold-overload option '" . $val . "'.");
            $self->{output}->option_exit();
        }

        my ($label, $filter, $threshold) = ($1, $2, $3);
        if ($self->{output}->is_litteral_status(status => $threshold) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong treshold-overload status '" . $val . "'.");
            $self->{output}->option_exit();
        }
        $self->{overload_th}->{$label} = {} if (!defined($self->{overload_th}->{$label}));
        $self->{overload_th}->{$label}->{$filter} = $threshold;
    }
}

sub get_severity {
    my ($self, %options) = @_;
    my $status = 'unknown';
    
    foreach my $entry (@{$states{$options{label}}}) {
        if ($options{value} =~ /${$entry}[0]/i) {
            $status = ${$entry}[1];
            foreach my $filter (keys %{$self->{overload_th}->{$options{label}}}) {
                if (${$entry}[0] =~ /$filter/i) {
                    $status = $self->{overload_th}->{$options{label}}->{$filter};
                    last;
                }
            }
            last;
        }
    }

    return $status;
}

sub run {
    my ($self, %options) = @_;
    my $clariion = $options{custom};
    
    #Prct Dirty Cache Pages =            0
    #SP Read Cache State                 Enabled
    #SP Write Cache State                Enabled
    #Write Cache Mirrored:               YES
    my $response = $clariion->execute_command(cmd => 'getcache -pdp -state -mirror');
    chomp $response;
    
    if ($response !~ /^SP Read Cache State\s+(.*)/im) {
        $self->{output}->output_add(severity => 'UNKNOWN',
                                short_msg => 'Cannot find cache informations.');
        $self->{output}->display();
        $self->{output}->exit();
    }
    my $read_cache_state = $1;
    
    $response =~ /^SP Write Cache State\s+(.*)\s*$/im;
    my $write_cache_state = $1;
    
    $response =~ /^Write Cache Mirrored:\s+(.*)\s*$/im;
    my $write_cache_mirror = $1;
    
    $response =~ /^Prct.*?=\s+(\S+)/im;
    my $dirty_prct = $1;
    
    $self->{output}->output_add(severity => $self->get_severity(value => $read_cache_state,
                                                                label => 'read_cache'),
                                short_msg => sprintf("Read cache state is '%s'", 
                                                    $read_cache_state));
    $self->{output}->output_add(severity => $self->get_severity(value => $write_cache_state,
                                                                label => 'write_cache'),
                                short_msg => sprintf("Write cache state is '%s'", 
                                                    $write_cache_state));
    $self->{output}->output_add(severity => $self->get_severity(value => $write_cache_mirror,
                                                                label => 'write_mirror'),
                                short_msg => sprintf("Write cache mirror is '%s'", 
                                                    $write_cache_mirror));
    
    my $exit = $self->{perfdata}->threshold_check(value => $dirty_prct, 
                                                  threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("Dirty Cache Pages is %s %%", $dirty_prct));
    }
    $self->{output}->perfdata_add(label => 'dirty_cache', unit => '%',
                                  value => $dirty_prct,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                  min => 0, max => 100);
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check status of the read and write cache.

=over 8

=item B<--warning>

Threshold warning in percent (for dirty cache).

=item B<--critical>

Threshold critical in percent (for dirty cache).

=item B<--threshold-overload>

Set to overload default threshold value.
Example: --threshold-overload='read_cache:(enabled)=critical'

=back

=cut
