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

package apps::backup::veeam::wsman::mode::listrepositories;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use apps::backup::veeam::wsman::mode::resources::types qw($repository_type $repository_status);
use centreon::common::powershell::veeam::repositories;
use centreon::plugins::misc;
use JSON::XS;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'ps-exec-only'      => { name => 'ps_exec_only' },
        'ps-display'        => { name => 'ps_display' }
    });

    return $self;
}


sub run {
    my ($self, %options) = @_;

    my $repos = $self->manage_selection(%options);
    foreach (@$repos) {
        $self->{output}->output_add(
            long_msg => sprintf(
                '[name: %s][type: %s][status: %s][totalSpace: %s]',
                $_->{name},
                $_->{type},
                $_->{status},
                $_->{totalSpace}
            )
        );
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List repositories:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['name', 'type', 'status', 'totalSpace']);
}

sub disco_show {
    my ($self, %options) = @_;

    my $repos = $self->manage_selection(%options);
    foreach (@$repos) {
        $self->{output}->add_disco_entry(%$_);
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $ps = centreon::common::powershell::veeam::repositories::get_powershell();
    if (defined($self->{option_results}->{ps_display})) {
        $self->{output}->output_add(
            severity => 'OK',
            short_msg => $ps
        );
        $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
        $self->{output}->exit();
    }

    my $result = $options{wsman}->execute_powershell(
        label => 'repositories',
        content => centreon::plugins::misc::powershell_encoded($ps)
    );
    if (defined($self->{option_results}->{ps_exec_only})) {
        $self->{output}->output_add(
            severity => 'OK',
            short_msg => $result->{repositories}->{stdout}
        );
        $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
        $self->{output}->exit();
    }

    my $decoded;
    eval {
        $decoded = JSON::XS->new->decode($self->{output}->decode($result->{repositories}->{stdout}));
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
        $self->{output}->option_exit();
    }

    my $repos = [];
    foreach (@$decoded) {
        push @$repos, {
            name => $_->{name},
            type => defined($repository_type->{ $_->{type} }) ? $repository_type->{ $_->{type} } : 'unknown',
            status => defined($repository_status->{ $_->{status} }) ? $repository_status->{ $_->{status} } : 'unknown',
            totalSpace => $_->{totalSpace}
        };
    }

    return $repos;
}

1;

__END__

=head1 MODE

[EXPERIMENTAL] List repositories.

=over 8


=item B<--ps-display>

Display powershell script.

=item B<--ps-exec-only>

Print powershell output.

=back

=cut
