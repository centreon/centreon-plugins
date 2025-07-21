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

package apps::java::cxf::jmx::mode::listservices;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my @mapping = ('name', 'state');

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

    my $request = [
        {
            mbean => 'org.apache.cxf:bus.id=*,type=Performance.Counter.Server,service=*,port=*',
            attributes => [
                { name => 'NumInvocations' }
            ] 
        }
    ];
    my $datas = $options{custom}->get_attributes(request => $request);

    my $results = {}; 
    foreach my $mbean (keys %$datas) {
        my ($service, $port);

        $service = $1 if ($mbean =~ /service=(.*?)(?:,|$)/);
        $port = $1 if ($mbean =~ /port=(.*?)(?:,|$)/);
        $service =~ s/^"(.*)"$/$1/;
        $port =~ s/^"(.*)"$/$1/;

        my $name = $service . ':' . $port;

        $results->{$name} = { name => $name, state => $datas->{$mbean}->{State} };
    }

    return $results;
}

sub run {
    my ($self, %options) = @_;
  
    my $results = $self->manage_selection(custom => $options{custom});
    foreach my $name (sort keys %$results) {
        $self->{output}->output_add(long_msg =>
            join('', map("[$_ = " . $results->{$name}->{$_} . ']', @mapping))
        );
    }
    
    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List services:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => [@mapping]);
}

sub disco_show {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(custom => $options{custom});
    foreach (sort keys %$results) {
        $self->{output}->add_disco_entry(
            %{$results->{$_}}
        );
    }
}

1;

__END__

=head1 MODE

List services.

=over 8

=back

=cut
    
