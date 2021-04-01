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

package storage::hp::msl::snmp::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

    $self->{cb_hook2} = 'snmp_execute';

    $self->{thresholds} = {
        library => [
            ['unknown', 'UNKNOWN'],
            ['unused', 'UNKNOWN'],
            ['ok', 'OK'],
            ['warning', 'WARNING'],
            ['critical', 'CRITICAL'],
            ['nonrecoverable', 'CRITICAL'],
        ],
    };

    $self->{components_path} = 'storage::hp::msl::snmp::mode::components';
    $self->{components_module} = ['library'];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_absent => 1, no_performance => 1, no_load_components => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

sub snmp_execute {
    my ($self, %options) = @_;

    $self->{snmp} = $options{snmp};
    $self->{results} = $self->{snmp}->get_multiple_table(oids => $self->{request});
}

1;

=head1 MODE

Check hardware.

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'library'.

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='library,CRITICAL,^(?!(ok)$)'

=back

=cut

package storage::hp::msl::snmp::mode::components::library;

use strict;
use warnings;

my %map_health = (1 => 'unknown', 2 => 'unused', 3 => 'ok',
    4 => 'warning', 5 => 'critical', 6 => 'nonrecoverable',
);

my $mapping_library = {
    hpHttpMgDeviceHealth => { oid => '.1.3.6.1.4.1.11.2.36.1.1.5.1.1.3', map => \%map_health },
};

sub load {
    my ($self) = @_;

    push @{$self->{request}}, { oid => $mapping_library->{hpHttpMgDeviceHealth}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking library");
    $self->{components}->{library} = {name => 'library', total => 0, skip => 0};
    return if ($self->check_filter(section => 'library'));

    foreach ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{ $mapping_library->{hpHttpMgDeviceHealth}->{oid} }})) {
        /^$mapping_library->{hpHttpMgDeviceHealth}->{oid}\.(.*)$/;
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping_library, results => $self->{results}->{ $mapping_library->{hpHttpMgDeviceHealth}->{oid} }, instance => $instance);

        next if ($self->check_filter(section => 'library', instance => $instance));

        $self->{components}->{library}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("library '%s' status is '%s' [instance = %s]",
                                                        $instance, $result->{hpHttpMgDeviceHealth}, $instance));
        my $exit = $self->get_severity(section => 'library', value => $result->{hpHttpMgDeviceHealth});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                       short_msg => sprintf("Library '%s' status is '%s'", $instance, $result->{hpHttpMgDeviceHealth}));
        }
    }
}

1;
