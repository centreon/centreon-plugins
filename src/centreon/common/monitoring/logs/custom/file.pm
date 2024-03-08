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

package centreon::common::monitoring::logs::custom::file;

use base qw(centreon::plugins::script_custom::cli);

use strict;
use warnings;
use centreon::plugins::misc;
use Digest::MD5 qw(md5_hex);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, nohelp => 1);
    bless $self, $class;

    if (!defined($options{noptions})) {
        $options{options}->add_options(arguments => {
            'file:s' => { name => 'file' }
        });
    }

    $options{options}->add_help(package => __PACKAGE__, sections => 'FILE OPTIONS', once => 1);

    return $self;
}

sub check_options {
    my ($self, %options) = @_;

    $self->{option_results}->{command} = 'cat'
        if (!defined($self->{option_results}->{command}) || $self->{option_results}->{command} eq '');

    if (defined($self->{option_results}->{file})) {
        $self->{option_results}->{command_options} = centreon::plugins::misc::sanitize_command_param(value => $self->{option_results}->{file});
    }

    centreon::plugins::misc::check_security_command(
        output => $self->{output},
        command => $self->{option_results}->{command},
        command_options => $self->{option_results}->{command_options},
        command_path => $self->{option_results}->{command_path}
    );

    return 0;
}

sub get_uuid {
    my ($self, %options) = @_;

    return md5_hex(
        ((defined($self->{option_results}->{hostname}) && $self->{option_results}->{hostname} ne '') ? $self->{option_results}->{hostname} : 'none') . '_' .
        ((defined($self->{option_results}->{file}) && $self->{option_results}->{file} ne '') ? $self->{option_results}->{file} : 'none')
    );
}

sub read {
    my ($self, %options) = @_;

    my ($stdout) = $self->SUPER::execute_command(%options);
    return $stdout;
}

1;

__END__

=head1 NAME

Logs file

=head1 SYNOPSIS

Logs file custom mode

=head1 FILE OPTIONS

=over 8

=item B<--hostname>

Hostname to query (with ssh).

=item B<--command>

Command to get information (default: 'cat').

=item B<--file>

Path to the file to read logs from.

=back

=head1 DESCRIPTION

B<custom>.

=cut
