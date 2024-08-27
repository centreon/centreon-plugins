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

package apps::protocols::imap::mode::searchmessage;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'warning:s'  => { name => 'warning' },
        'critical:s' => { name => 'critical' },
        'search:s'   => { name => 'search' },
        'delete'     => { name => 'delete' },
        'folder:s'   => { name => 'folder', default => 'INBOX' }
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

    if (!defined($self->{option_results}->{search})) {
        $self->{output}->add_option_msg(short_msg => 'Please set the --search option');
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;

    $options{custom}->connect(connection_exit => 'critical');
    my ($num) = $options{custom}->search(
        folder => $self->{option_results}->{folder},
        search => $self->{option_results}->{search},
        delete => $self->{option_results}->{delete}
    );
    $options{custom}->disconnect();

    my $exit = $self->{perfdata}->threshold_check(
        value => $num,
        threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]
    );
    $self->{output}->output_add(
        severity => $exit,
        short_msg => sprintf('%d message(s) found', $num)
    );
    $self->{output}->perfdata_add(
        nlabel => 'messages.found.count',
        value => $num,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
        min => 0
    );

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check messages in a mailbox with IMAP filter.

=over 8

=item B<--search>

Set the search string (required)

=item B<--delete>

Delete messages found

=item B<--folder>

Set IMAP folder (default: 'INBOX')

=item B<--warning>

Warning threshold of number messages found

=item B<--critical>

Critical threshold of number message found

=back

=cut
