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
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload option '" . $val . "'.");
            $self->{output}->option_exit();
        }
        my ($status, $filter) = ($1, $2);
        if ($self->{output}->is_litteral_status(status => $status) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload status '" . $val . "'.");
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
