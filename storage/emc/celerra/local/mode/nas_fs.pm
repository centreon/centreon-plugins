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

package storage::emc::celerra::local::mode::nas_fs;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

    $self->{cb_hook2} = 'cmd_execute';
    $self->{numeric_threshold} = { warning => 80, critical => 90 };
    $self->{components_path} = 'storage::emc::celerra::local::mode::components';
    $self->{components_module} = ['nas_fs'];
}

sub cmd_execute {
    my ($self, %options) = @_;

    ($self->{stdout}, my $exit_code) = $options{custom}->execute_command(
        command => '$SHELL -l -c "nas_fs -query:inuse==y:type=uxfs:IsRoot=False:RWServersNumeric==1 -fields:RWservers,rwvdms,StoragePoolName,Name,PctUsed,MaxSize -format:\"%L,%L,%s,%s,%d,%d\n\""',
        no_quit => 1
    );

    if ($exit_code != 0 && $exit_code != 255) {
        $self->{output}->add_option_msg(short_msg => "Command error: $self->{stdout}");
        $self->{output}->option_exit();
    }
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_absent => 1, no_performance => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

1;

__END__

=head1 MODE

Check nas_fs space.

Command used: /nas/sbin/nas_fs -query:inuse==y:type=uxfs:IsRoot=False:RWServersNumeric==1 -fields:RWservers,rwvdms,StoragePoolName,Name,PctUsed,MaxSize -format:"%L,%L,%s,%s,%d,%d\n"

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'nas_fs'.

=item B<--filter>

Exclude some parts (comma seperated list) (Example: --filter=fs_name)
Can also exclude specific instance: --filter=FS_TEST

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='nas_fs,CRITICAL,^(?!(normal)$)'

=back

=cut
