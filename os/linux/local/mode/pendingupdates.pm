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

package os::linux::local::mode::pendingupdates;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'updates', type => 1 }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'total', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'Number of pending updates : %d',
                perfdatas => [
                    { label => 'total', template => '%d', min => 0 }
                ]
            }
        }
    ];
    
    $self->{maps_counters}->{updates} = [
        { label => 'update', set => {
                key_values => [ { name => 'package' }, { name => 'version' }, { name => 'repository' } ],
                closure_custom_output => $self->can('custom_updates_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => sub { return 'ok'; }
            }
        }
    ];
}

sub custom_updates_output {
    my ($self, %options) = @_;
    
    return sprintf(
        "Package '%s' [version: %s] [repository: %s]",
        $self->{result_values}->{package},
        $self->{result_values}->{version},
        $self->{result_values}->{repository}
    );
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'os-mode:s'           => { name => 'os_mode', default => 'rhel' },
        'filter-package:s'    => { name => 'filter_package' },
        'filter-repository:s' => { name => 'filter_repository' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{os_mode}) ||
        $self->{option_results}->{os_mode} eq '' ||
        $self->{option_results}->{os_mode} eq 'rhel'
        ) {
        $self->{command} = 'yum';
        $self->{command_options} = 'check-update 2>&1';
    } elsif ($self->{option_results}->{os_mode} eq 'debian') {
        $self->{command} = 'apt-get';
        $self->{command_options} = 'upgrade -sVq 2>&1';
    } elsif ($self->{option_results}->{os_mode} eq 'suse') {
        $self->{command} = 'zypper';
        $self->{command_options} = 'list-updates 2>&1';
    } else {
        $self->{output}->add_option_msg(short_msg => "os mode '" . $self->{option_results}->{os_mode} . "' not implemented" );
        $self->{output}->option_exit();
    }    
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($stdout) = $options{custom}->execute_command(
        command => $self->{command},
        command_options => $self->{command_options},
        no_quit => 1
    );

    $self->{global}->{total} = 0;
    $self->{updates} = {};
    my @lines = split /\n/, $stdout;
    foreach my $line (@lines) {
        next if ($line !~ /^(\S+)\s+(\d+\S+)\s+(\S+)/
            && $line !~ /\s+(\S+)\s+\(\S+\s\=\>\s(\S+)\)/
            && $line !~ /.*\|.*\|\s+(\S+)\s+\|.*\|\s+(\d+\S+)\s+\|.*/);
        my ($package, $version, $repository) = ($1, $2, $3);
        $repository = "-" if (!defined($repository) || $repository eq '');

        if (defined($self->{option_results}->{filter_package}) && $self->{option_results}->{filter_package} ne '' &&
            $package !~ /$self->{option_results}->{filter_package}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $package . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_repository}) && $self->{option_results}->{filter_repository} ne '' &&
            $repository !~ /$self->{option_results}->{filter_repository}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $repository . "': no matching filter.", debug => 1);
            next;
        }

        $self->{updates}->{$package} = {
            package => $package,
            version => $version,
            repository => $repository,
        };

        $self->{global}->{total}++;
    }
}

1;

__END__

=head1 MODE

Check pending updates.

For rhel/centos: yum check-update 2>&1
For Debian: apt-get upgrade -sVq 2>&1
For Suse: zypper list-updates 2>&1

=over 8

=item B<--os-mode>

Default mode for parsing and command: 'rhel' (default), 'debian', 'suse'.

=item B<--warning-total>

Threshold warning for total amount of pending updates.

=item B<--critical-total>

Threshold critical for total amount of pending updates.

=item B<--filter-package>

Filter package name.

=item B<--filter-repository>

Filter repository name.

=back

=cut
