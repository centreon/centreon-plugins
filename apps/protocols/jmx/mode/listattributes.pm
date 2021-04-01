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

package apps::protocols::jmx::mode::listattributes;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                  "max-depth:s"             => { name => 'max_depth', default => 6 },
                                  "max-objects:s"           => { name => 'max_objects', default => 10000 },
                                  "max-collection-size:s"   => { name => 'max_collection_size', default => 150 },
                                  "mbean-pattern:s"         => { name => 'mbean_pattern', default => '*:*' },
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

    $self->{connector}->list_attributes(%{$self->{option_results}});
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

List JMX attributes.

=over 8

=item B<--max-depth>

Maximum nesting level of the returned JSON structure for a certain MBean (Default: 6)

=item B<--max-collection-size>

Maximum size of a collection after which it gets truncated (default: 150)

=item B<--max-objects>

Maximum overall objects to fetch for a mbean (default: 10000)

=item B<--mbean-pattern>

Pattern matching (Default: '*:*').
For details: http://docs.oracle.com/javase/1.5.0/docs/api/javax/management/ObjectName.html

=back

=cut
