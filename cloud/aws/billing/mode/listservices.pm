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

package cloud::aws::billing::mode::listservices;

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

    $self->{dimensions} = $options{custom}->cloudwatch_list_metrics(
        namespace => 'AWS/Billing'
    );
}

sub run {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    
    my %already;
    foreach my $dimension (@{$self->{dimensions}}) {
        my $servicename = '';
        my $currency = '';
        foreach my $name (@{$dimension->{Dimensions}}) {
            $servicename = $name->{Value} if ($name->{Name} =~ m/ServiceName/ && $name->{Value} ne '');
            $currency = $name->{Value} if ($name->{Name} =~ m/Currency/ && $name->{Value} ne '');
        }
        next if (defined($already{$servicename}) || $servicename eq '');
        $self->{output}->output_add(long_msg => sprintf("[ServiceName = %s][Currency = %s]", $servicename, $currency));
        $already{$servicename} = 1;
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List services:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['servicename', 'currency']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);

    my %already;
    foreach my $dimension (@{$self->{dimensions}}) {
        my $servicename = '';
        my $currency = '';
        foreach my $name (@{$dimension->{Dimensions}}) {
            $servicename = $name->{Value} if ($name->{Name} =~ m/ServiceName/ && $name->{Value} ne '');
            $currency = $name->{Value} if ($name->{Name} =~ m/Currency/ && $name->{Value} ne '');
        }
        next if (defined($already{$servicename}) || $servicename eq '');
        $self->{output}->add_disco_entry(
            servicename => $servicename,
            currency => $currency,
        );
        $already{$servicename} = 1;
    }
}

1;

__END__

=head1 MODE

List billed Amazon services.

=over 8

=back

=cut
    
