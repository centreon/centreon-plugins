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

use base qw(centreon::plugins::mode);

use strict;
use warnings;

use Data::Dumper;

my $debug = 0;
my @input = ('Status', 'Name',);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(
        arguments => {
            "max-depth:s"           => { name => 'max_depth',           default => 6 },
            "max-objects:s"         => { name => 'max_objects',         default => 10000 },
            "max-collection-size:s" => { name => 'max_collection_size', default => 150 },
            "mbean-name:s"          => {
                name    => 'mbean_name',
                default => 'NAME'
            },
            "hostname:s" => { name => 'hostname' },
        }
    );
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub exploit_data {
    my ($self, %params) = @_;

    my %options = %{ $params{'-option_results'} };
    my %data    = %{ $params{'-data'} };

    my $name
        = defined($options{'mbean_name'})
        ? $options{'mbean_name'}
        : 'NAME';

    print Data::Dumper->Dump([ \%data ], [qw(*data)]) if $debug;

    my @list_key = keys(%data);

    unless (grep(/^$name$/, @list_key)) {

        print "no name=$name found\n";
        exit 1;
    }

    print Data::Dumper->Dump([ \@list_key ], [qw(*list_key)]) if $debug;

    my %hash = %{ $data{$name}{'attributes'} };

    my ($extented_status_information, $status_information, $severity,);

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
        return undef;
    }

    print Data::Dumper->Dump([ \%hash ], [qw(*hash)]) if $debug;

    if ($hash{'Status'} eq 'GREEN') {
        $status_information = "Queue $hash{'Name'} $data{$name}{'mbean_infos'}{'type'} is Green.";
        $status_information .= " Queue is OK.\n";

        $severity = 'OK';
    }

    elsif ($hash{'Status'} eq 'RED') {
        $status_information = "Queue is not started\n";

        $extented_status_information = "Queue: $hash{'Name'}\n";
        $extented_status_information .= "Env: $data{$name}{'mbean_infos'}{'type'}\n";

        $severity = 'CRITICAL';
    }

    else {
        $status_information = "Case not implemented";

        $severity = 'CRITICAL';
    }

    $self->{output}->output_add(
        severity  => $severity,
        short_msg => $status_information,
        long_msg  => $extented_status_information,
    );
    $self->{output}->display();
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    my $attributs = [ 'name', 'side', 'type' ];
    $self->{output}->add_disco_format(elements => $attributs);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->{connector} = $options{custom};

    my $ref_data = $self->{connector}->get_data_disco(
        '-option_results' => \%{ $self->{'option_results'} },
        '-side'           => 'Queues',
    );

    print Data::Dumper->Dump([$ref_data], [qw(*ref_data)]) if $debug;

    foreach my $key (keys %{$ref_data}) {
        $self->{output}->add_disco_entry(
            'name' => $key,
            'type' => $ref_data->{$key}{'mbean_infos'}{'type'},
            'side' => $ref_data->{$key}{'mbean_infos'}{'side'},
        );
    }
}

sub run {
    my ($self, %options) = @_;

    $self->{connector} = $options{custom};
    my $ref_data = $self->{connector}->get_data(
        '-option_results' => \%{ $self->{'option_results'} },
        '-data'           => \@input,
        '-side'           => 'Queues',
    );
    $self->exploit_data(
        '-option_results' => \%{ $self->{'option_results'} },
        '-data'           => $ref_data,
    );
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Agen Monitoring.

=over 8

=item B<--hostname>

Hostname to query.

=item B<--max-depth>

Maximum nesting level of the returned JSON structure for a certain MBean (Default: 6)

=item B<--max-collection-size>

Maximum size of a collection after which it gets truncated (default: 150)

=item B<--max-objects>

Maximum overall objects to fetch for a mbean (default: 10000)

=item B<--mbean-name>

Pattern matching for name (Default: 'NAME').

=back

=cut
