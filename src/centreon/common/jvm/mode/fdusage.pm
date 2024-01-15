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

package centreon::common::jvm::mode::fdusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_usage_output {
    my ($self, %options) = @_;

    return sprintf(
        "File descriptor usage total: %s used: %s (%.2f%%) free: %s (%.2f%%)",
        $self->{result_values}->{total},
        $self->{result_values}->{used}, $self->{result_values}->{prct_used},
        $self->{result_values}->{free}, $self->{result_values}->{prct_free}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'usage', nlabel => 'fd.opened.usage.count', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', cast_int => 1 },
                ]
            }
        },
        { label => 'usage-free', display_ok => 0, nlabel => 'fd.opened.free.count', set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', cast_int => 1 }
                ]
            }
        },
        { label => 'usage-prct', display_ok => 0, nlabel => 'fd.opened.usage.percentage', set => {
                key_values => [ { name => 'prct_used' }, { name => 'used' }, { name => 'free' }, { name => 'prct_free' }, { name => 'total' } ],
                output_template => 'Used : %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
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
         { mbean => 'java.lang:type=OperatingSystem', attributes => [ { name => 'MaxFileDescriptorCount' }, { name => 'OpenFileDescriptorCount' } ] }
    ];
    my $result = $options{custom}->get_attributes(request => $self->{request}, nothing_quit => 1);
    
    $self->{global} = {
        used => $result->{'java.lang:type=OperatingSystem'}->{OpenFileDescriptorCount},
        free => $result->{'java.lang:type=OperatingSystem'}->{MaxFileDescriptorCount} - $result->{'java.lang:type=OperatingSystem'}->{OpenFileDescriptorCount},
        total => $result->{'java.lang:type=OperatingSystem'}->{MaxFileDescriptorCount}
    };
    $self->{global}->{prct_used} = $self->{global}->{used} / $self->{global}->{total} * 100;
    $self->{global}->{prct_free} = 100 - $self->{global}->{prct_used};

}

1;

__END__

=head1 MODE

Check number/percentage of file descriptors

Example:
perl centreon_plugins.pl --plugin=apps::tomcat::jmx::plugin --custommode=jolokia --url=http://10.30.2.22:8080/jolokia-war --mode=fd-usage --warning 60 --critical 75

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'usage', 'usage-free', 'usage-prct' (%).

=back

=cut
