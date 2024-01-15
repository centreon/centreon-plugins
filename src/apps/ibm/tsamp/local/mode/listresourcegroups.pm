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

package apps::ibm::tsamp::local::mode::listresourcegroups;

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
        command => 'lssam',
        command_options => '-nocolor'
    );

    my $rg = [];
    while ($stdout =~ /^(\S.*)\s+IBM.ResourceGroup:(.*?)\s+.*?Nominal=(.*)\s*$/mig) {
        my ($name, $opState, $nominalState) = ($2, lc($1), lc($3));
        
        push @$rg, { name => $name, state => $opState, nominal => $nominalState };
    }

    return $rg;
}

sub run {
    my ($self, %options) = @_;

    my $rg = $self->manage_selection(%options);
    foreach (@$rg) {
        $self->{output}->output_add(
            long_msg => sprintf(
                "[name: %s][state: %s][nominal: %s]",
                $_->{name},
                $_->{state},
                $_->{nominal}
            )
        );
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List resource groups:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['name', 'state', 'nominal']);
}

sub disco_show {
    my ($self, %options) = @_;

    my $rg = $self->manage_selection(%options);
    foreach (@$rg) {
        $self->{output}->add_disco_entry(%$_);
    }
}

1;

__END__

=head1 MODE

List resource groups.

=over 8

=back

=cut
