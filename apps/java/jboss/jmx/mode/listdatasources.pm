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

package apps::java::jboss::jmx::mode::listdatasources;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s' => { name => 'filter_name' }
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
        { mbean => 'jboss.jca:name=*,service=ManagedConnectionPool', attributes => 
             [ { name => 'ConnectionCount' } ] },
        { mbean => 'jboss.as*:data-source=*,statistics=pool,subsystem=datasources', attributes => 
             [ { name => 'ActiveCount' } ] },
        { mbean => 'jboss.as*:xa-data-source=*,statistics=pool,subsystem=datasources', attributes =>
             [ { name => 'ActiveCount' } ] }
    ];
    my $result = $options{custom}->get_attributes(request => $request);

    my $ds = {};
    foreach my $mbean (keys %{$result}) {
        $mbean =~ /(?:[:,])(?:data-source|name|xa-data-source)=(.*?)(?:,|$)/;
        my $name = $1;
        $name =~ s/^"(.*)"$/$1/;

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $name . "': no matching filter.", debug => 1);
            next;
        }

        $ds->{$name} = { name => $name };
    }

    return $ds;
}

sub run {
    my ($self, %options) = @_;
  
    my $ds = $self->manage_selection(%options);
    foreach my $instance (sort keys %$ds) { 
        $self->{output}->output_add(long_msg => '[name = ' . $self->{ds}->{$instance}->{name} . "]");
    }
    
    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List data sources:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['name']);
}

sub disco_show {
    my ($self, %options) = @_;

    my $ds = $self->manage_selection(%options);
    foreach my $instance (sort keys %$ds) {             
        $self->{output}->add_disco_entry(
            %{$self->{ds}->{$instance}}
        );
    }
}

1;

__END__

=head1 MODE

List data sources.

=over 8

=item B<--filter-name>

Filter by name (can be a regexp).

=back

=cut
