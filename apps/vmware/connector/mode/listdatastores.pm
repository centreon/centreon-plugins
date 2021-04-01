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

package apps::vmware::connector::mode::listdatastores;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'datastore-name:s'   => { name => 'datastore_name' },
        'filter'             => { name => 'filter' },
        'scope-datacenter:s' => { name => 'scope_datacenter' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}


sub run {
    my ($self, %options) = @_;

    my $response = $options{custom}->execute(params => $self->{option_results},
        command => 'listdatastores');
    foreach (keys %{$response->{data}}) {
        $self->{output}->output_add(long_msg => sprintf("  %s [%s] [%s]", 
                                                        $response->{data}->{$_}->{name}, 
                                                        $response->{data}->{$_}->{accessible},
                                                        $response->{data}->{$_}->{type}));
    }

    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List datastore(s):');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'accessible', 'type']);
}

sub disco_show {
    my ($self, %options) = @_;
    
    my $response = $options{custom}->execute(params => $self->{option_results},
        command => 'listdatastores');
    foreach (keys %{$response->{data}}) {
        $self->{output}->add_disco_entry(name => $response->{data}->{$_}->{name},
            accessible => $response->{data}->{$_}->{accessible}, type => $response->{data}->{$_}->{type}
        );
    }
}

1;

__END__

=head1 MODE

List datastores.

=over 8

=item B<--datastore-name>

datastore name to list.

=item B<--filter>

Datastore name is a regexp.

=item B<--scope-datacenter>

Search in following datacenter(s) (can be a regexp).

=back

=cut
