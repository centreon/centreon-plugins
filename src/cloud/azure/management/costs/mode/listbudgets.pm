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

package cloud::azure::management::costs::mode::listbudgets;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{budget} = $options{custom}->azure_list_budget();

}

sub run {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $budget (@{$self->{budget}->{value}}) {
        $self->{output}->output_add(
            long_msg => sprintf("[budget = %s][category = %s][amount = %s][timegrain = %s][id = %s]",
            $budget->{name}, $budget->{properties}->{category}, $budget->{properties}->{amount}, $budget->{properties}->{timeGrain}, $budget->{id})
        );
    }
    
    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List budgets:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['id', 'name', 'category', 'amount', 'timegrain']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $budget (@{$self->{budget}->{value}}) {
        $self->{output}->add_disco_entry(
            name => $budget->{name},
            category => $budget->{properties}->{category},
            amount => $budget->{properties}->{amount},
            timegrain => $budget->{properties}->{timeGrain},
            id => $budget->{id}
        );
    }
}

1;

__END__

=head1 MODE

List Azure budgets.

=over 8

=back

=cut
