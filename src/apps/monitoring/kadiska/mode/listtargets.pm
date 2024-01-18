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

package apps::monitoring::kadiska::mode::listtargets;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'runner-name:s'    => { name => 'runner_name' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{runner_name}) || $self->{option_results}->{runner_name} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --runner-name option.");
        $self->{output}->option_exit();
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $raw_form_post = {
        "select" => [
            "target_name"
        ],
        "from" => "traceroute",
        "groupby" => [
            "target_name"
        ],
        "offset" => 0,
        "options" => {"sampling" => \1 }
    };

    $raw_form_post->{where} = ["=","runner_name",["\$", $self->{option_results}->{runner_name}]];

    $self->{targets} = $options{custom}->request_api(
        method => 'POST',
        endpoint => 'query',
        query_form_post => $raw_form_post
    );
}

sub run {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $target (@{$self->{targets}->{data}}){
        $self->{output}->output_add(
            long_msg => sprintf("[target: %s][runner: %s]", 
                $target->{target_name},
                $self->{option_results}->{runner_name}
            )
        );
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'Target-groups list:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['target', 'runner']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);

    foreach my $target (@{$self->{targets}->{data}}){
        $self->{output}->add_disco_entry( 
            target => $target->{target_name},
            runner => $self->{option_results}->{runner_name}
        );
    }
}

1;

__END__

=head1 MODE

List tracer targets for a given runner.

=over 8

=item B<--runner-name>

Specify runner name to list linked tracer targets. 

=back

=cut
