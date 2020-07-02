#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package os::linux::local::mode::memory;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'warning:s'  => { name => 'warning' },
        'critical:s' => { name => 'critical' }
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
}

sub check_rhel_version {
    my ($self, %options) = @_;

    $self->{rhel_71} = 0;
    return if ($options{stdout} !~ /(?:Redhat|CentOS|Red[ \-]Hat).*?release\s+(\d+)\.(\d+)/mi);
    $self->{rhel_71} = 1 if ($1 >= 8 || ($1 == 7 && $2 >= 1));
}

sub run {
    my ($self, %options) = @_;

    my ($stdout) = $options{custom}->execute_command(
        command => 'cat',
        command_options => '/proc/meminfo /etc/redhat-release 2>&1',
        no_quit => 1
    );

    # Buffer can be missing. In Openvz container for example.
    my $buffer_used = 0;
    my ($cached_used, $free, $total_size, $slab_used);
    foreach (split(/\n/, $stdout)) {
        if (/^MemTotal:\s+(\d+)/i) {
            $total_size = $1 * 1024;
        } elsif (/^Cached:\s+(\d+)/i) {
            $cached_used = $1 * 1024;
        } elsif (/^Buffers:\s+(\d+)/i) {
            $buffer_used = $1 * 1024;
        } elsif (/^Slab:\s+(\d+)/i) {
            $slab_used = $1 * 1024;
        } elsif (/^MemFree:\s+(\d+)/i) {
            $free = $1 * 1024;
        }
    }

    if (!defined($total_size) || !defined($cached_used) || !defined($free)) {
        $self->{output}->add_option_msg(short_msg => 'Some informations missing.');
        $self->{output}->option_exit();
    }

    $self->check_rhel_version(stdout => $stdout);

    my $physical_used = $total_size - $free;
    my $nobuf_used = $physical_used - $buffer_used - $cached_used;
    
    my ($slab_value, $slab_unit);
    ($slab_value, $slab_unit) = $self->{perfdata}->change_bytes(value => $slab_used) if (defined($slab_used));
    if ($self->{rhel_71} == 1) {
        $nobuf_used -= $slab_used;
    }

    my $prct_used = $nobuf_used * 100 / $total_size;
    my $exit = $self->{perfdata}->threshold_check(value => $prct_used, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

    my ($nobuf_value, $nobuf_unit) = $self->{perfdata}->change_bytes(value => $nobuf_used);
    my ($buffer_value, $buffer_unit) = $self->{perfdata}->change_bytes(value => $buffer_used);
    my ($cached_value, $cached_unit) = $self->{perfdata}->change_bytes(value => $cached_used);

    $self->{output}->output_add(
        severity => $exit,
        short_msg => sprintf(
            'Ram used (-buffers/cache%s) %s (%.2f%%), Buffer: %s, Cached: %s%s',
            ($self->{rhel_71} == 1 && defined($slab_used)) ? '/slab' : '',
            $nobuf_value . " " . $nobuf_unit,
            $prct_used,
            $buffer_value . " " . $buffer_unit,
            $cached_value . " " . $cached_unit,
            (defined($slab_used)) ? ', Slab: ' . $slab_value . ' ' . $slab_unit : '',
        )
    );

    $self->{output}->perfdata_add(
        label => 'cached', unit => 'B',
        value => $cached_used,
        min => 0
    );
    $self->{output}->perfdata_add(
        label => 'buffer', unit => 'B',
        value => $buffer_used,
        min => 0
    );
    $self->{output}->perfdata_add(
        label => 'used', unit => 'B',
        value => $nobuf_used,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning', total => $total_size),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical', total => $total_size),
        min => 0, max => $total_size
    );
    $self->{output}->perfdata_add(
        label => 'slab', unit => 'B',
        value => $slab_used,
        min => 0
    ) if (defined($slab_used));

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check physical memory (need '/proc/meminfo' file).

Command used: cat /proc/meminfo /etc/redhat-release 2>&1

=over 8

=item B<--warning>

Threshold warning in percent.

=item B<--critical>

Threshold critical in percent.

=back

=cut
