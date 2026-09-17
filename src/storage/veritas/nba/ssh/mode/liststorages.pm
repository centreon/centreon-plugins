#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package storage::veritas::nba::ssh::mode::liststorages;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my @labels = (
    'name',
    'status'
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($result) = $options{custom}->execute_scenario(
        request => {
            interactive => 1,
            pty => {
                rows => 800,
                cols => 80
            },
            scenario => [
                { "cmd" => "waitfor", "options" => { "Match" =>  'Main_Menu>', "Timeout" => "30" } },
                { "cmd" => "put", "options" => { "String" => "Manage\n", "Timeout" => "5" } },
                { "cmd" => "waitfor", "options" => { "Match" =>  'Manage>', "Timeout" => "5" } },
                { "cmd" => "put", "options" => { "String" => "Storage\n", "Timeout" => "5" } },
                { "cmd" => "waitfor", "options" => { "Match" =>  'Storage>', "Timeout" => "5" } },
                { "cmd" => "put", "options" => { "String" => "Show ALL\n", "Timeout" => "5" } },
                { "cmd" => "waitfor", "options" => { "Match" =>  'to quit|Waiting for data', "Timeout" => "20" } },
                { "cmd" => "close" }
            ]
        }
    );

    my $results = {};
    while ($result =~ /^(.*?)\|.*?\|.*?\|.*?\|.*?\|\s+(Optimal|Degraded|Not\s+Accessible|Not\s+Configured)/mig) {
        my ($part_name, $part_status) = (centreon::plugins::misc::trim($1), $2);
        $results->{ $part_name } = {
            name   => $part_name,
            status => $part_status
        };
    }

    return $results;
}

sub run {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(custom => $options{custom});
    foreach my $instance (sort keys %$results) {
        $self->{output}->output_add(long_msg => join('', map("[$_: " . $results->{$instance}->{$_} . ']', @labels)));
    }

    $self->{output}->output_add(
        severity  => 'OK',
        short_msg => 'List storages:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => [ @labels ]);
}

sub disco_show {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(custom => $options{custom});
    foreach (sort keys %$results) {
        $self->{output}->add_disco_entry(
            %{$results->{$_}}
        );
    }
}

1;

__END__

=head1 MODE

List storages.

=over 8

=back

=cut