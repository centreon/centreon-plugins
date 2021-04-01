#
# Copyright 2021 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and application monitoring for
# service performance.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

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
    
    $options{options}->add_options(arguments =>
                                {
                                "cache-command:s"         => { name => 'cache_command', default => 'getcache' },
                                "cache-options:s"         => { name => 'cache_options', default => '-pdp -state -mirror' },
                                "threshold-overload:s@"   => { name => 'threshold_overload' },
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
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload option '" . $val . "'.");
            $self->{output}->option_exit();
        }

        my ($label, $filter, $threshold) = ($1, $2, $3);
        if ($self->{output}->is_litteral_status(status => $threshold) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload status '" . $val . "'.");
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
    my $response = $clariion->execute_command(cmd => $self->{option_results}->{cache_command} . ' ' . $self->{option_results}->{cache_options});
    chomp $response;
    
    my ($read_cache_state, $write_cache_state);
    if ($response !~ /^SP Read Cache State(\s+|:\s+)(.*)/im) {
        $self->{output}->output_add(severity => 'UNKNOWN',
                                short_msg => 'Cannot find cache informations.');
        $self->{output}->display();
        $self->{output}->exit();
    }
    $read_cache_state = $2;
    
    $response =~ /^SP Write Cache State(\s+|:\s+)(.*)\s*$/im;
    $write_cache_state = $2;
    
    my ($write_cache_mirror, $dirty_prct);
    if ($response =~ /^Write Cache Mirrored:\s+(.*)\s*$/im) {
        $write_cache_mirror = $1;
    }
    
    if ($response =~ /^Prct.*?=\s+(\S+)/im) {
        $dirty_prct = $1;
    }

    $self->{output}->output_add(severity => $self->get_severity(value => $read_cache_state,
                                                                label => 'read_cache'),
                                short_msg => sprintf("Read cache state is '%s'", 
                                                    $read_cache_state));
    $self->{output}->output_add(severity => $self->get_severity(value => $write_cache_state,
                                                                label => 'write_cache'),
                                short_msg => sprintf("Write cache state is '%s'", 
                                                    $write_cache_state));
    if (defined($write_cache_mirror)) {
        $self->{output}->output_add(severity => $self->get_severity(value => $write_cache_mirror,
                                                                    label => 'write_mirror'),
                                    short_msg => sprintf("Write cache mirror is '%s'", 
                                                         $write_cache_mirror));
    }
    if (defined($dirty_prct)) {
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
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check status of the read and write cache.

=over 8

=item B<--cache-command>

Set cache command (Default: 'getcache').

=item B<--cache-options>

Set option for cache command (Default: '-pdp -state -mirror').

=item B<--warning>

Threshold warning in percent (for dirty cache).

=item B<--critical>

Threshold critical in percent (for dirty cache).

=item B<--threshold-overload>

Set to overload default threshold value.
Example: --threshold-overload='read_cache:(enabled)=critical'

=back

=cut
