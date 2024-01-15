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

package centreon::common::jvm::mode::loadaverage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'load1', nlabel => 'system.load.1m.count', set => {
                key_values => [ { name => 'load' } ],
                output_template => 'System load average: %.2f (1m)',
                perfdatas => [
                    { template => '%.2f', min => 0 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {});

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{request} = [
         { mbean => "java.lang:type=OperatingSystem", attributes => [ { name => 'SystemLoadAverage' } ] }
    ];

    my $result = $options{custom}->get_attributes(request => $self->{request}, nothing_quit => 1);
    my $load = $result->{'java.lang:type=OperatingSystem'}->{SystemLoadAverage};
    if ($load == -1) {
        $self->{output}->add_option_msg(short_msg => 'System load average is not set');
        $self->{output}->option_exit();
    }

    $self->{global} = { load => $load };
}

1;

__END__

=head1 MODE

Check system load average

Example:
perl centreon_plugins.pl --plugin=apps::tomcat::jmx::plugin --custommode=jolokia --url=http://10.30.2.22:8080/jolokia-war --mode=load-average --warning 2 --critical 3

=over 8

=item B<--warning-load1>

Warning threshold for loadaverage

=item B<--critical-load1>

Critical threshold for loadaverage

=back

=cut
