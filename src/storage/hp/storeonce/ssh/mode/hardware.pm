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

package storage::hp::storeonce::ssh::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;
    
    $self->{cb_hook2} = 'ssh_execute';
    
    $self->{thresholds} = {
        hardware => [
            ['ok', 'OK'],
            ['failed', 'CRITICAL'],
            ['degraded', 'WARNING'],
            ['missing', 'OK'],
        ],
        serviceset => [
            ['running', 'OK'],
            ['fault', 'CRITICAL'],
        ],
    };
    
    $self->{components_path} = 'storage::hp::storeonce::ssh::mode::components';
    $self->{components_module} = ['hardware', 'serviceset'];
}

sub ssh_execute {
    my ($self, %options) = @_;
    
    ($self->{result}, $self->{exit_code}) = $options{custom}->execute_command(commands => $self->{commands});
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_absent => 1, no_performance => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    $self->{commands} = [];
    return $self;
}

sub get_hasharray {
    my ($self, %options) = @_;

    my $result = [];
    return $result if ($options{content} eq '');
    my ($header, @lines) = split /\n/, $options{content};
    my @header_names = split /$options{delim}/, $header;
    
    for (my $i = 0; $i <= $#lines; $i++) {
        my @content = split /$options{delim}/, $lines[$i];
        my $data = {};
        for (my $j = 0; $j <= $#header_names; $j++) {
            $data->{$header_names[$j]} = $content[$j];
        }
        push @$result, $data;
    }
    
    return $result;
}

1;

__END__

=head1 MODE

Check components (hardware and service set).

=over 8

=item B<--component>

Which component to check (default: '.*').
Can be: 'hardware', 'serviceset'.

=item B<--filter>

Exclude the items given as a comma-separated list (example: --filter=hardware --filter=serviceset).
You can also exclude items from specific instances: --filter=hardware,storageCluster

=item B<--no-component>

Define the expected status if no components are found (default: critical).

=item B<--threshold-overload>

Use this option to override the status returned by the plugin when the status label matches a regular expression (syntax: section,[instance,]status,regexp).
Example: --threshold-overload='hardware,networkSwitch,OK,degraded'

=back

=cut
