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

package storage::purestorage::restapi::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_numeric_check_section_option} = '^(temperature)$';

    $self->{cb_hook2} = 'restapi_execute';

    $self->{thresholds} = {
        entity => [
            ['ok', 'OK'],
            ['critical', 'CRITICAL'],
            ['degraded', 'WARNING'],
            ['device_off', 'WARNING'],
            ['identifying', 'OK'],
            ['not_installed', 'OK'],
            ['unknown', 'UNKNOWN'],
        ],
    };
    
    $self->{components_path} = 'storage::purestorage::restapi::mode::components';
    $self->{components_module} = ['entity'];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_absent => 1, no_load_components => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { });

    return $self;
}

sub restapi_execute {
    my ($self, %options) = @_;
    
    $self->{results} = $options{custom}->get_object(path => '/hardware');
}

1;

=head1 MODE

Check hardware.

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'entity'.

=item B<--filter>

Exclude some parts (comma seperated list)
Can also exclude specific instance: --filter=entity,CT1.FC0

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='entity,OK,device_off'

=item B<--warning>

Set warning threshold for 'temperature' (syntax: type,regexp,threshold)
Example: --warning='temperature,.*,40'

=item B<--critical>

Set critical threshold for 'temperature' (syntax: type,regexp,threshold)
Example: --critical='temperature,.*,50'

=back

=cut

package storage::purestorage::restapi::mode::components::entity;

use strict;
use warnings;

sub load { }

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking entity");
    $self->{components}->{entity} = {name => 'entity', total => 0, skip => 0};
    return if ($self->check_filter(section => 'entity'));

    # [
    #    {"status": "ok", "slot": null, "name": "CH0", "index": 0, "identify": "off", "voltage": null, "details": null, "speed": null, "temperature": null},
    #    ...
    # ]

    foreach my $entry (@{$self->{results}}) {
        my $instance = $entry->{name};
                
        next if ($self->check_filter(section => 'entity', instance => $instance));

        $self->{components}->{entity}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("entity '%s' status is '%s' [instance = %s]",
                                                        $entry->{name}, $entry->{status}, $instance));
        my $exit = $self->get_severity(section => 'entity', value => $entry->{status});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("entity '%s' status is '%s'", $entry->{name}, $entry->{status}));
        }
        
        if (defined($entry->{temperature}) && $entry->{temperature} =~ /[0-9]/) {
            my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $entry->{temperature});            
            if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit2,
                                            short_msg => sprintf("entity '%s' temperature is %s C", $entry->{name}, $entry->{temperature}));
            }
            $self->{output}->perfdata_add(
                label => 'temperature', unit => 'C',
                nlabel => 'hardware.entity.temperature.celsius',
                instances => $entry->{name},
                value => $entry->{temperature},
                warning => $warn,
                critical => $crit, min => 0
            );
        }
    }
}

1;
