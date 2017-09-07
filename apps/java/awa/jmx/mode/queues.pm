#
# Copyright 2017 Centreon (http://www.centreon.com/)
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

package apps::java::awa::jmx::mode::queues;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(
        arguments => {
            "queue-name:s" => {
                name    => 'queue_name',
                default => 'NAME'
            },
        }
    );

    return $self;
}

sub disco_format {
    my ($self, %options) = @_;

    my $attributs = [ 'name', 'side', 'type' ];
    $self->{output}->add_disco_format(elements => $attributs);

    return;
}

sub disco_show {
    my ($self, %options) = @_;

    my $ref_data = $self->manage_selection(%options);

    foreach my $key (keys %{$ref_data}) {
        $self->{output}->add_disco_entry(
            'name' => $key,
            'type' => $ref_data->{$key}{'mbean_infos'}{'type'},
            'side' => $ref_data->{$key}{'mbean_infos'}{'side'},
        );
    }

    return;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{request} = [
        {   mbean      => 'Automic:name=*,type=*,side=Queues',
            attributes => [ { name => 'Status' }, { name => 'Name' }, ]
        },
    ];

    my $result = $options{custom}->get_attributes(request => $self->{request}, nothing_quit => 1);

    my @list_key = keys(%{$result});

    my %data = ();
    foreach my $key (@list_key) {
        my $rec = $key;

        $rec =~ s/Automic://;
        my %mbean_infos = split /[=,]/, $rec;
        my $name = $mbean_infos{'name'};
        delete $mbean_infos{'name'};

        $data{$name}{'mbean_infos'} = \%mbean_infos;
        $data{$name}{'attributes'}  = $result->{$key};
    }

    my $name
        = defined($self->{'option_results'}{'queue_name'})
        ? $self->{'option_results'}{'queue_name'}
        : 'NAME';

    my ($extented_status_information, $status_information, $severity,);

    @list_key = keys(%data);

    unless (grep {/^$name$/}, @list_key) {
        $status_information = "Queue ($name) No found\n";
        $severity           = 'CRITICAL';

        $self->{output}->output_add(
            severity  => $severity,
            short_msg => $status_information,
            long_msg  => $extented_status_information,
        );
        $self->{output}->display();
        $self->{output}->exit();

        return;
    }

    my %hash = %{ $data{$name}{'attributes'} };

    if (!keys %hash) {
        $status_information = "No data\n";
        $severity           = 'CRITICAL';
        $self->{output}->output_add(
            severity  => $severity,
            short_msg => $status_information,
            long_msg  => $extented_status_information,
        );
        $self->{output}->display();
        $self->{output}->exit();

        return;
    }

    if ($hash{'Status'} eq 'GREEN') {
        $status_information = "Queue $hash{'Name'} $data{$name}{'mbean_infos'}{'type'} is Green.";
        $status_information .= " Queue is OK.\n";
        $severity = 'OK';
    }
    elsif ($hash{'Status'} eq 'RED') {
        $status_information          = "Queue is not started\n";
        $extented_status_information = "Queue: $hash{'Name'}\n";
        $extented_status_information .= "Env: $data{$name}{'mbean_infos'}{'type'}\n";
        $severity = 'CRITICAL';
    }
    else {
        $status_information = "Case not implemented";
        $severity           = 'CRITICAL';
    }

    $self->{output}->output_add(
        severity  => $severity,
        short_msg => $status_information,
        long_msg  => $extented_status_information,
    );
    $self->{output}->display();
    $self->{output}->exit();

    return;
}

1;

__END__

=head1 MODE

Queue Monitoring.

=over 8

=item B<--queue-name>

Name of queue (Default: 'NAME').

=back

=cut
