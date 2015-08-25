#
# Copyright 2015 Centreon (http://www.centreon.com/)
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

package apps::vmware::connector::mode::listdatacenters;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "datacenter:s"            => { name => 'datacenter' },
                                  "filter"                  => { name => 'filter' },
                                });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}


sub run {
    my ($self, %options) = @_;
    $self->{connector} = $options{custom};

    $self->{connector}->set_discovery();
    $self->{connector}->add_params(params => $self->{option_results},
                                   command => 'listdatacenters');
    $self->{connector}->run();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name']);
}

sub disco_show {
    my ($self, %options) = @_;
    $self->{connector} = $options{custom};

    # We ask to use XML output from the connector
    $self->{connector}->add_params(params => { disco_show => 1 });
    $self->run(custom => $self->{connector});
}

1;

__END__

=head1 MODE

List datacenters.

=over 8

=item B<--datacenter>

Datacenter to check.
If not set, we check all datacenters.

=item B<--filter>

Datacenter is a regexp.

=back

=cut
