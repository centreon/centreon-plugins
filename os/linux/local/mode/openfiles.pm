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

package os::linux::local::mode::openfiles;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'files-open', nlabel => 'system.files.open.count', set => {
                key_values => [ { name => 'openfiles' } ],
                output_template => 'current open files: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-username:s' => { name => 'filter_username' },
        'filter-appname:s'  => { name => 'filter_appname' },
        'filter-pid:s'      => { name => 'filter_pid' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($stdout) = $options{custom}->execute_command(
        command => 'lsof',
        command_options => '-a -d ^mem -d ^cwd -d ^rtd -d ^txt -d ^DEL 2>&1'
    );

    $self->{global} = { openfiles => 0 };
    my @lines = split /\n/, $stdout;
    shift @lines;
    foreach (@lines) {
        /^(\S+)\s+(\S+)\s+(\S+)/;
        my ($name, $pid, $user) = ($1, $2, $3);
        next if (defined($self->{option_results}->{filter_username}) && $self->{option_results}->{filter_username} ne '' &&
            $user !~ /$self->{option_results}->{filter_username}/);
        next if (defined($self->{option_results}->{filter_appname}) && $self->{option_results}->{filter_appname} ne '' &&
            $name !~ /$self->{option_results}->{filter_appname}/);
        next if (defined($self->{option_results}->{filter_pid}) && $self->{option_results}->{filter_pid} ne '' &&
            $pid !~ /$self->{option_results}->{filter_pid}/);

        $self->{global}->{openfiles}++;
    }
}

1;

__END__

=head1 MODE

Check open files.

Command used: lsof -a -d ^mem -d ^cwd -d ^rtd -d ^txt -d ^DEL 2>&1

=over 8

=item B<--filter-appname>

Filter application name (can be a regexp).

=item B<--filter-username>

Filter username name (can be a regexp).

=item B<--filter-pid>

Filter PID (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'files-open'.

=back

=cut
