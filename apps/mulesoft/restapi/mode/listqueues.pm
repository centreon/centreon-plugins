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

package apps::mulesoft::restapi::mode::listqueues;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s' => { name => 'filter_name' },
        'region-id:s'   => { name => 'region_id' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{region_id}) || $self->{option_results}->{region_id} eq '') {
            $self->{output}->add_option_msg(short_msg => "Need to specify --region-id option.");
            $self->{output}->option_exit();
    }
}


sub run {
    my ($self, %options) = @_;

    my $result = $options{custom}->list_objects(
        api_type  => 'mq',
        endpoint  => '/destinations',
        region_id => $self->{option_results}->{region_id},
    );

    foreach my $queue (@{$result}) {
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne ''
            && $queue->{queueId} !~ /$self->{option_results}->{filter_name}/);

        $self->{output}->output_add(
            long_msg => sprintf(
                "[name = %s]",
                $queue->{queueId}
            )
        );
    }

    $self->{output}->output_add(severity => 'OK', short_msg => 'Mulesoft Anypoint Message Qeues:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['name']);
}

sub disco_show {
    my ($self, %options) = @_;

    my $result = $options{custom}->list_objects(
        api_type  => 'mq',
        endpoint  => '/destinations',
        region_id => $self->{option_results}->{region_id},
    );

    foreach my $queue (@{$result}) {
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne ''
            && $queue->{queueId} !~ /$self->{option_results}->{filter_name}/);
        $self->{output}->add_disco_entry(name => $queue->{queueId});
    }
}

1;

__END__

=head1 MODE

List Mulesoft Anypoint Messages Queues.

=over 8

=item B<--filter-name>

Filter on queue name (Can be a regexp).

=item B<--region-id>

Specify the queue region ID (Mandatory).
Example: --region-id='eu-central-1'

=back

=cut
