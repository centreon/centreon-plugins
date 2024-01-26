#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package os::solaris::local::mode::cpu;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::statefile;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'warning:s'  => { name => 'warning' },
        'critical:s' => { name => 'critical' }
    });

    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);
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
    
    $self->{statefile_cache}->check_options(%options);
}

sub run {
    my ($self, %options) = @_;

    my ($stdout) = $options{custom}->execute_command(
        command => 'kstat',
        command_options => '-n sys 2>&1'
    );

    $self->{statefile_cache}->read(statefile => 'cache_solaris_local_' . $options{custom}->get_identifier()  . '_' .  $self->{mode});
    my $old_timestamp = $self->{statefile_cache}->get(name => 'last_timestamp');
    my $datas = {};
    $datas->{last_timestamp} = time();

    $self->{output}->output_add(
        severity => 'OK', 
        short_msg => "CPUs usages are ok."
    );
    my @output_cpu_instance = split("instance", $stdout);
    shift @output_cpu_instance;
    foreach (@output_cpu_instance) {
        /:\s.*?(\d+)/;
        my $cpu_number = $1;
        /.*?cpu_ticks_idle\s.*?(\d+).*?cpu_ticks_kernel\s.*?(\d+).*?cpu_ticks_user\s.*?(\d+)/ms;
        $datas->{'cpu_idle_' . $cpu_number} = $1;
        $datas->{'cpu_system_' . $cpu_number} = $2;
        $datas->{'cpu_user_' . $cpu_number} = $3;
        
        if (!defined($old_timestamp)) {
            next;
        }
        my $old_cpu_idle = $self->{statefile_cache}->get(name => 'cpu_idle_' . $cpu_number);
        my $old_cpu_system = $self->{statefile_cache}->get(name => 'cpu_system_' . $cpu_number);
        my $old_cpu_user = $self->{statefile_cache}->get(name => 'cpu_user_' . $cpu_number);
        if (!defined($old_cpu_system) || !defined($old_cpu_idle) || !defined($old_cpu_user)) {
            next;
        }

        if ($datas->{'cpu_idle_' . $cpu_number} < $old_cpu_idle) {
            # We set 0. Has reboot.
            $old_cpu_user = 0;
            $old_cpu_idle = 0;
            $old_cpu_system = 0;
        }
        
        my $total_elapsed = ($datas->{'cpu_idle_' . $cpu_number} + $datas->{'cpu_user_' . $cpu_number} + $datas->{'cpu_system_' . $cpu_number}) - ($old_cpu_user + $old_cpu_idle + $old_cpu_system);
        my $idle_elapsed = $datas->{'cpu_idle_' . $cpu_number} - $old_cpu_idle;
        my $cpu_ratio_usetime = 100 * $idle_elapsed / $total_elapsed;
        $cpu_ratio_usetime = 100 - $cpu_ratio_usetime;        

        my $exit_code = $self->{perfdata}->threshold_check(
            value => $cpu_ratio_usetime, 
            threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]
        );

        $self->{output}->output_add(long_msg => sprintf("CPU %d %.2f%%", $cpu_number, $cpu_ratio_usetime));
        if (!$self->{output}->is_status(litteral => 1, value => $exit_code, compare => 'ok')) {
            $self->{output}->output_add(
                severity => $exit_code,
                short_msg => sprintf("CPU %d %.2f%%", $cpu_number, $cpu_ratio_usetime)
            );
        }
        $self->{output}->perfdata_add(
            label => 'cpu_' . $cpu_number, unit => '%',
            value => sprintf("%.2f", $cpu_ratio_usetime),
            warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
            critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
            min => 0, max => 100
        );
    }

	$self->{statefile_cache}->write(data => $datas);
    if (!defined($old_timestamp)) {
        $self->{output}->output_add(
            severity => 'OK',
            short_msg => "Buffer creation..."
        );
    }
 
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check system CPUs

Command used: 'kstat -n sys 2>&1'

=over 8

=item B<--warning>

Warning threshold in percent.

=item B<--critical>

Critical threshold in percent.

=back

=cut
