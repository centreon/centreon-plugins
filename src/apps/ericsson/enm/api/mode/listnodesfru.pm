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

package apps::ericsson::enm::api::mode::listnodesfru;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'add-extra-attrs'  => { name => 'add_extra_attrs' },
        'filter-node-id:s' => { name => 'filter_node_id' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $frus = $options{custom}->call_fruState();
    my $results = [];
    foreach my $fru (@$frus) {
        next if (defined($self->{option_results}->{filter_node_id}) && $self->{option_results}->{filter_node_id} ne '' &&
            $fru->{NodeId} !~ /$self->{option_results}->{filter_node_id}/);

        my $attr = { node_id => $fru->{NodeId}, fru_id => $fru->{FieldReplaceableUnitId} };
        if (defined($self->{option_results}->{add_extra_attrs})) {
            $attr->{label} = defined($fru->{userLabel}) && $fru->{userLabel} ne 'null' ? $fru->{userLabel} : '';
            $attr->{administrative_state} = lc($fru->{administrativeState});
            $attr->{availability_status} = $fru->{availabilityStatus} ne 'null' ? lc($fru->{availabilityStatus}) : '';
            $attr->{operational_state} = lc($fru->{operationalState});
        }
        push @$results, $attr;
    }

    return $results;
}

sub run {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(%options);
    foreach (@$results) {
        my $msg = sprintf('[node_id: %s][fru_id: %s]', $_->{node_id}, $_->{fru_id});
        if (defined($self->{option_results}->{add_extra_attrs})) {
            $msg .= sprintf(
                '[label: %s][administrative state: %s][availability status: %s][operational state: %s]',
                $_->{label},
                $_->{administrative_state},
                $_->{availability_status},
                $_->{operational_state}
            )
        }
        $self->{output}->output_add(long_msg => $msg);
    }
    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List field replaceable units:'
    );

    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    my $attrs = ['node_id', 'fru_id'];
    push @$attrs, ('label', 'administrative_state', 'availability_status', 'operational_state')
        if (defined($self->{option_results}->{add_extra_attrs}));
    $self->{output}->add_disco_format(
        elements => $attrs
    );
}

sub disco_show {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(%options);
    foreach (@$results) {
        $self->{output}->add_disco_entry(%$_);
    }
}

1;

__END__

=head1 MODE

List nodes field replaceable units.

=over 8

=item B<--filter-node-id>

Filter field replaceable units by node ID (can be a regexp).

=item B<--add-extra-attrs>

Display label/administrative_state/availability_status/operational_state.

=back

=cut
