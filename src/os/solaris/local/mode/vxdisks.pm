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

package os::solaris::local::mode::vxdisks;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'skip-vxdisk'  => { name => 'skip_vxdisk' },
        'skip-vxprint' => { name => 'skip_vxprint' },
        'warning:s'    => { name => 'warning' },
        'critical:s'   => { name => 'critical' }
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

sub vdisk_execute {
    my ($self, %options) = @_;

    my ($stdout) = $options{custom}->execute_command(
        command => 'vxdisk',
        command_options => 'list 2>&1',
        command_path => '/usr/sbin'
    );

    my $long_msg = $stdout;
    $long_msg =~ s/\|/~/mg;
    $self->{output}->output_add(long_msg => $long_msg);

    foreach (split /\n/, $stdout) {        
        if (/(failed)/i ) {
            my $status = $1;
            next if (! /\S+\s+\S+\s+(\S+)\s+/);
            $self->{num_errors}++;
            $self->{vxdisks_name} .= ' [' . $1 . '/' . $status . ']';
        }
    }
}

sub vxprint_execute {
    my ($self, %options) = @_;

    my ($stdout) = $options{custom}->execute_command(
        command => 'vxprint',
        command_options => '-Ath 2>&1',
        command_path => '/usr/sbin'
    );

    my $long_msg = $stdout;
    $long_msg =~ s/\|/~/mg;
    $self->{output}->output_add(long_msg => $long_msg);

    foreach (split /\n/, $stdout) {
        if (/(NODEVICE|FAILING)/i ) {
            my $status = $1;
            next if (! /^\s*\S+\s+(\S+)\s+/);
            $self->{num_errors}++;
            $self->{vxprint_name} .= ' [' . $1 . '/' . $status . ']';
        }
    }
}

sub run {
    my ($self, %options) = @_;
    $self->{num_errors} = 0;
    $self->{vxdisks_name} = '';
    $self->{vxprint_name} = '';

    if (!defined($self->{option_results}->{skip_vxdisk})) {
        $self->vdisk_execute(custom => $options{custom});
    }
    if (!defined($self->{option_results}->{skip_vxprint})) {
        $self->vxprint_execute(custom => $options{custom});
    }

    my ($exit_code) =  $self->{perfdata}->threshold_check(
        value => $self->{num_errors}, 
        threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]
    );
    if ($self->{num_errors} > 0) {
        $self->{output}->output_add(
            severity => $exit_code,
            short_msg => sprintf("Problems on some disks:" . $self->{vxdisks_name}  . $self->{vxprint_name})
        );
    } else {
        $self->{output}->output_add(
            severity => 'OK', 
            short_msg => "No problems on disks."
        );
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Veritas disk status.

Command used: '/usr/sbin/vxdisk list 2>&1' and '/usr/sbin/vxprint -Ath 2>&1'

=over 8

=item B<--warning>

Warning threshold.

=item B<--critical>

Critical threshold.

=item B<--skip-vxdisk>

Skip 'vxdisk' command (not executed).

=item B<--skip-vxprint>

Skip 'vxprint' command (not executed).


=back

=cut
