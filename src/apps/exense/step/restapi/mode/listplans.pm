#
# Copyright 2025 Centreon (http://www.centreon.com/)
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

package apps::exense::step::restapi::mode::listplans;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use JSON::XS;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'tenant-name:s' => { name => 'tenant_name' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{tenant_name}) || $self->{option_results}->{tenant_name} eq '') {
        $self->{option_results}->{tenant_name} = '[All]';
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $payload = $self->{option_results}->{tenant_name};
    $options{custom}->request(method => 'POST', endpoint => '/rest/tenants/current', query_form_post => $payload, skip_decode => 1);

    $payload = {
        skip => 0,
        limit => 4000000,
        filters => [
            {
                collectionFilter => { type => 'True', field => 'visible' }
            }
        ],
        'sort' => {
            'field' => 'attributes.name',
            'direction' => 'ASCENDING'
        }
    };
    $payload = centreon::plugins::misc::json_encode($payload);
        unless($payload) {
        $self->{output}->add_option_msg(short_msg => 'cannot encode json request');
        $self->{output}->option_exit();
    }

    my $plans = $options{custom}->request(method => 'POST', endpoint => '/rest/table/plans', query_form_post => $payload);

    my $results = [];
    foreach my $plan (@{$plans->{data}}) {
        # skip plans created by keyword single execution
        next if ($plan->{visible} =~ /false|0/);

        push @$results, {
            id => $plan->{id},
            name => $plan->{attributes}->{name}
        };
    }

    return $results;
}

sub run {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(%options);
    foreach (@$results) {
        $self->{output}->output_add(
            long_msg => sprintf(
                '[id: %s][name: %s]',
                $_->{id},
                $_->{name}
            )
        );
    }
    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List plans:'
    );

    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['id', 'name']);
}

sub disco_show {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(%options);
    foreach (@$results) {
        $self->{output}->add_disco_entry(
            id => $_->{id},
            name => $_->{name}
        );
    }
}

1;

__END__

=head1 MODE

List plans.

=over 8

=item B<--tenant-name>

Check plan of a tenant (default: '[All]').

=back

=cut
