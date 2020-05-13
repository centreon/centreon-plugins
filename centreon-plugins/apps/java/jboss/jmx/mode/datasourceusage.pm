#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package apps::java::jboss::jmx::mode::datasourceusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'datasource', type => 1, cb_prefix_output => 'prefix_ds_output', message_multiple => 'All datasources are ok' },
    ];

    $self->{maps_counters}->{datasource} = [
        { label => 'active-con', set => {
                key_values => [ { name => 'ActiveCount' }, { name => 'display' } ],
                output_template => 'Current Active Connections : %s',
                perfdatas => [
                    { label => 'active_con', value => 'ActiveCount', template => '%s', min => 0,
                      label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'available-con', set => {
                key_values => [ { name => 'AvailableCount' }, { name => 'display' } ],
                output_template => 'Current Available Connections : %s',
                perfdatas => [
                    { label => 'available_con', value => 'AvailableCount', template => '%s', min => 0,
                      label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'in-use-con', set => {
                key_values => [ { name => 'InUseCount' }, { name => 'display' } ],
                output_template => 'Current In Use Connections : %s',
                perfdatas => [
                    { label => 'in_use_con', value => 'InUseCount', template => '%s', min => 0,
                      label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'created-con', set => {
                key_values => [ { name => 'CreatedCount', diff => 1 }, { name => 'display' } ],
                output_template => 'Created Connections : %s',
                perfdatas => [
                    { label => 'created_con', value => 'CreatedCount', template => '%s', min => 0,
                      label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub prefix_ds_output {
    my ($self, %options) = @_;

    return "Datasource '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-name:s' => { name => 'filter_name' },
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $request = [
        { mbean => "jboss.jca:name=*,service=ManagedConnectionPool", attributes => 
             [ { name => 'AvailableConnectionCount' }, { name => 'ConnectionCount' }, { name => 'ConnectionCreatedCount' }, { name => 'InUseConnectionCount' } ] },
        { mbean => "jboss.as:data-source=*,statistics=pool,subsystem=datasources", attributes => 
             [ { name => 'AvailableCount' }, { name => 'ActiveCount' }, { name => 'CreatedCount' }, { name => 'InUseCount' } ] },
    ];
    
    my $result = $options{custom}->get_attributes(request => $request, nothing_quit => 1);

    $self->{datasource} = {};
    foreach my $key (keys %$result) {
        $key =~ /(?:[:,])(?:name|data-source)=(.*?)(?:,|$)/;
        my $ds_name = $1;
        $ds_name =~ s/^"(.*)"$/$1/;
        
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $ds_name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $ds_name . "': no matching filter.", debug => 1);
            next;
        }
     
        $self->{datasource}->{$ds_name} = {
            display => $ds_name,
            AvailableCount => defined($result->{$key}->{AvailableConnectionCount}) ? $result->{$key}->{AvailableConnectionCount} : $result->{$key}->{AvailableCount},
            ActiveCount => defined($result->{$key}->{ConnectionCount}) ? $result->{$key}->{ConnectionCount} : $result->{$key}->{ActiveCount},
            CreatedCount => defined($result->{$key}->{ConnectionCreatedCount}) ? $result->{$key}->{ConnectionCreatedCount} : $result->{$key}->{CreatedCount},
            InUseCount => defined($result->{$key}->{InUseConnectionCount}) ? $result->{$key}->{InUseConnectionCount} : $result->{$key}->{InUseCount},
        };
    }
    
    $self->{cache_name} = "jboss_" . $self->{mode} . '_' . md5_hex($options{custom}->get_connection_info()) . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check data sources usage.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='num-active'

=item B<--filter-name>

Filter datasource name (can be a regexp).

=item B<--warning-*>

Threshold warning.
Can be: 'active-con', 'available-con', 'created-con', 'in-use-con'.

=item B<--critical-*>

Threshold critical.
Can be: 'active-con', 'available-con', 'created-con', 'in-use-con'.

=back

=cut
