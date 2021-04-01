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

package storage::hp::eva::cli::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_numeric_check_section_option} = '^(fan|temperature|psu)$';
    
    $self->{cb_hook2} = 'api_execute';
    
    $self->{thresholds} = {
        default => [
            ['^good$', 'OK'],
            ['notinstalled', 'OK'],
            ['^normal$', 'OK'],
            ['unsupported', 'OK'],
            ['attention', 'WARNING'],
            ['.*', 'CRITICAL'],
        ],
    };
    
    $self->{components_path} = 'storage::hp::eva::cli::mode::components';
    $self->{components_module} = ['fan', 'temperature', 'system', 'disk', 'diskgrp', 'psu', 'battery', 'iomodule'];
}

sub api_execute {
    my ($self, %options) = @_;
    
    $self->{xml_result} = $options{custom}->ssu_execute(commands => $self->{ssu_commands});
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    $self->{ssu_commands} = {};
    return $self;
}

1;

__END__

=head1 MODE

Check hardware.

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'fan'.

=item B<--filter>

Exclude some parts (comma seperated list) (Example: --filter=temperature --filter=fan)
Can also exclude specific instance: --filter="fan,Fan Block 1"

=item B<--absent-problem>

Return an error if an entity is not 'present' (default is skipping)
Can be specific or global: --absent-problem="fan,Fan Block 1"

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='fan,OK,degraded'

=item B<--warning>

Set warning threshold for 'temperature', 'fan' (syntax: type,regexp,threshold)
Example: --warning='temperature,.*,30'

=item B<--critical>

Set critical threshold for 'temperature', 'fan' (syntax: type,regexp,threshold)
Example: --critical='temperature,.*,50'

=back

=cut
