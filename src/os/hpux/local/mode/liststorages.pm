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

package os::hpux::local::mode::liststorages;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

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

    my ($stdout) = $options{custom}->execute_command(
        command => 'bdf',
        command_options => '2>&1',
        no_quit => 1
    );

    my $results = {};
    my @lines = split(/\n/, $stdout);
    # Header not needed
    shift @lines;
    while (my $line = shift @lines) {
        # When the line is too long, the FS name is printed on a separated line
        if ($line !~ /^(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/) {
            $line .= "    " . shift(@lines);
        }
        next if ($line !~ /^(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/);
        my ($fs, $size, $mount) = ($1, $2 * 1024, $6);

        $results->{$mount} = { fs => $fs, size => $size };
    }

    return $results;
}

sub run {
    my ($self, %options) = @_;
	
    my $results = $self->manage_selection(custom => $options{custom});
    foreach my $name (sort(keys %$results)) {
        $self->{output}->output_add(
            long_msg => sprintf(
                '[name: %s][fs: %s][size: %s]',
                $name,
                $results->{$name}->{fs},
                $results->{$name}->{size}
            )
        );
    }
    
    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List storages:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'fs', 'size']);
}

sub disco_show {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(custom => $options{custom});
    foreach my $name (sort(keys %$results)) {
        $self->{output}->add_disco_entry(
            name => $name,
            fs => $results->{$name}->{fs},
            size => $results->{$name}->{size}
        );
    }
}

1;

__END__

=head1 MODE

List storages.

Command used: bdf 2>&1

=over 8

=back

=cut
