#
# Copyright 2018 Centreon (http://www.centreon.com/)
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

package centreon::common::fortinet::fortigate::mode::vdomsession;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_vdom_output {
    my ($self, %options) = @_;
    
    return "Virtual domain '" . $options{instance_value}->{fgVdEntName} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'vdoms', type => 1, cb_prefix_output => 'prefix_vdom_output', message_multiple => 'All session metrics are ok' },
    ];
    $self->{maps_counters}->{vdoms} = [
        { label => 'active-session', set => {
                key_values => [ { name => 'fgVdEntSesCount' }, { name => 'fgVdEntName' } ],
                output_template => 'Active sessions: %d',
                perfdatas => [
                    { label => 'active_sessions', value => 'fgVdEntSesCount_absolute', template => '%d',
                      min => 0, unit => 'sessions', label_extra_instance => 1, instance_use => 'fgVdEntName_absolute' },
                ],
            }
        },
        { label => 'session-rate', set => {
                key_values => [ { name => 'fgVdEntSesRate' }, { name => 'fgVdEntName' } ],
                output_template => 'Session setup rate: %d sessions/s',
                perfdatas => [
                    { label => 'session_rate', value => 'fgVdEntSesRate_absolute', template => '%d',
                      min => 0, unit => 'sessions/s', label_extra_instance => 1, instance_use => 'fgVdEntName_absolute' },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                    "filter-name:s"             => { name => 'filter_name' },
                                });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

my $mapping = {
    fgVdEntName => { oid => '.1.3.6.1.4.1.12356.101.3.2.1.1.2' },
    fgVdEntSesCount => { oid => '.1.3.6.1.4.1.12356.101.3.2.1.1.7' },
    fgVdEntSesRate => { oid => '.1.3.6.1.4.1.12356.101.3.2.1.1.8' },
};

my $oid_fgVdInfo = '.1.3.6.1.4.1.12356.101.3.2';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{vdoms} = {};

    my $results = $options{snmp}->get_table(oid => $oid_fgVdInfo , nothing_quit => 1);

    foreach my $oid (keys %{$results}) {
        next if ($oid !~ /^$mapping->{fgVdEntSesCount}->{oid}\.(\d+)/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $results, instance => $instance);

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{fgVdEntName} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $name . "': no matching filter name.", debug => 1);
            next;
        }
        
        $self->{vdoms}->{$result->{fgVdEntName}} = {
            fgVdEntName => $result->{fgVdEntName},
            fgVdEntSesCount => $result->{fgVdEntSesCount},
            fgVdEntSesRate => $result->{fgVdEntSesRate},
        }
    }
    
    if (scalar(keys %{$self->{vdoms}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No entry found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check virtual domains active sessions count and session setup rate.

=over 8

=item B<--filter-name>

Filter by virtual domain name (can be a regexp).

=item B<--warning-*>

Threshold warning.
Can be: 'active-session', 'session-rate'.

=item B<--critical-*>

Threshold critical.
Can be: 'active-session', 'session-rate'.

=back

=cut
