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

package cloud::aws::fsx::mode::discovery;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use JSON::XS;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'prettify' => { name => 'prettify' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub run {
    my ($self, %options) = @_;

    my @disco_data;
    my $disco_stats;

    $disco_stats->{start_time} = time();

    my $fsx_instances = $options{custom}->discovery(
        service => 'fsx',
        command => 'describe-file-systems'
    );

    foreach my $fsx_instance (@{$fsx_instances->{FileSystems}}) {
        next if (!defined($fsx_instance->{FileSystemId}));
        my %fsx;
        $fsx{type} = "fsx";
        $fsx{id} = $fsx_instance->{FileSystemId};
        $fsx{dns_name} = $fsx_instance->{DNSName};
        $fsx{creation_time} = $fsx_instance->{CreationTime};
        $fsx{lifecycle} = $fsx_instance->{Lifecycle};
        $fsx{fsx_type} = $fsx_instance->{FileSystemType};
        foreach my $tag (@{$fsx_instance->{Tags}}) {
            push @{$fsx{tags}}, { key => $tag->{Key}, value => $tag->{Value} };
        }
        push @disco_data, \%fsx;
    }

    $disco_stats->{end_time} = time();
    $disco_stats->{duration} = $disco_stats->{end_time} - $disco_stats->{start_time};
    $disco_stats->{discovered_items} = @disco_data;
    $disco_stats->{results} = \@disco_data;

    my $encoded_data;
    eval {
        if (defined($self->{option_results}->{prettify})) {
            $encoded_data = JSON::XS->new->utf8->pretty->encode($disco_stats);
        } else {
            $encoded_data = JSON::XS->new->utf8->encode($disco_stats);
        }
    };
    if ($@) {
        $encoded_data = '{"code":"encode_error","message":"Cannot encode discovered data into JSON format"}';
    }

    return @disco_data if (defined($options{discover}));

    $self->{output}->output_add(short_msg => $encoded_data);
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1);
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

FSX discovery.

=over 8

=item B<--prettify>

Prettify JSON output.

=back

=cut
