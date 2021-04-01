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

package os::linux::local::mode::listpartitions;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-name:s' => { name => 'filter_name' }
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
        command => 'cat',
        command_options => '/proc/partitions 2>&1'
    );

    my $results = {};
    my @lines = split /\n/, $stdout;
    # Header not needed
    shift @lines;
    foreach my $line (@lines) {
        next if ($line !~ /^\s*(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/);
        my ($major, $minor, $blocks, $name) = ($1, $2, $3, $4);
        
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "Skipping partition '" . $name . "': no matching filter name");
            next;
        }
        
        $results->{$name} = 1;
    }

    return $results;
}

sub run {
    my ($self, %options) = @_;
	
    my $results = $self->manage_selection(custom => $options{custom});
    foreach my $name (sort(keys %$results)) {
        $self->{output}->output_add(long_msg => "'" . $name . "'");
    }
    
    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List partitions:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name']);
}

sub disco_show {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(custom => $options{custom});
    foreach my $name (sort(keys %$results)) {     
        $self->{output}->add_disco_entry(name => $name);
    }
}

1;

__END__

=head1 MODE

List partitions.

Command used: cat /proc/partitions 2>&1

=over 8

=item B<--filter-name>

Filter partition name (regexp can be used).

=back

=cut
