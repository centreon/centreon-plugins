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

package os::aix::local::mode::liststorages;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-fs:s'    => { name => 'filter_fs' },
        'filter-mount:s' => { name => 'filter_mount' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($stdout) = $options{custom}->execute_command(
        command => 'df',
        command_options => '-P -k 2>&1'
    );

    my $results = {};
    my @lines = split /\n/, $stdout;
    # Header not needed
    shift @lines;
    foreach my $line (@lines) {
        next if ($line !~ /^(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(.*)/);
        my ($fs, $size, $used, $available, $percent, $mount) = ($1, $2, $3, $4, $5, $6);
        
        if (defined($self->{option_results}->{filter_fs}) && $self->{option_results}->{filter_fs} ne '' &&
            $fs !~ /$self->{option_results}->{filter_fs}/) {
            $self->{output}->output_add(long_msg => "skipping storage '" . $mount . "': no matching filter fs", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_mount}) && $self->{option_results}->{filter_mount} ne '' &&
            $mount !~ /$self->{option_results}->{filter_mount}/) {
            $self->{output}->output_add(long_msg => "skipping storage '" . $mount . "': no matching filter mount", debug => 1);
            next;
        }
        
        $results->{$mount} = { fs => $fs };
    }

    return $results;
}

sub run {
    my ($self, %options) = @_;
	
    my $results = $self->manage_selection(custom => $options{custom});
    foreach my $name (sort(keys %$results)) {
        $self->{output}->output_add(
            long_msg => sprintf(
                "'%s' [fs = %s]",
                $name,
                $results->{$name}->{fs}
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
    
    $self->{output}->add_disco_format(elements => ['name', 'fs']);
}

sub disco_show {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(custom => $options{custom});
    foreach my $name (sort(keys %$results)) {     
        $self->{output}->add_disco_entry(
            name => $name,
            fs => $results->{$name}->{fs},
        );
    }
}

1;

__END__

=head1 MODE

List storages.
Command used: df -P -k 2>&1

=over 8

=item B<--filter-fs>

Filter filesystem (regexp can be used).

=item B<--filter-mount>

Filter mount point (regexp can be used).

=back

=cut
