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

package centreon::common::fortinet::fortigate::mode::vdomstate;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

my $instance_mode;

sub custom_status_threshold {
    my ($self, %options) = @_;
    my $status = 'ok';
    my $message;

    eval {
        local $SIG{__WARN__} = sub { $message = $_[0]; };
        local $SIG{__DIE__} = sub { $message = $_[0]; };

        if (defined($instance_mode->{option_results}->{critical_status}) && $instance_mode->{option_results}->{critical_status} ne '' &&
            eval "$instance_mode->{option_results}->{critical_status}") {
            $status = 'critical';
        } elsif (defined($instance_mode->{option_results}->{warning_status}) && $instance_mode->{option_results}->{warning_status} ne '' &&
            eval "$instance_mode->{option_results}->{warning_status}") {
            $status = 'warning';
        }
    };
    if (defined($message)) {
        $self->{output}->output_add(long_msg => 'filter status issue: ' . $message);
    }

    return $status;
}

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf("Operation mode is '%s', HA cluster member state is '%s'",
        $self->{result_values}->{op_mode}, $self->{result_values}->{ha_state});
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{op_mode} = $options{new_datas}->{$self->{instance} . '_fgVdEntOpMode'};
    $self->{result_values}->{ha_state} = $options{new_datas}->{$self->{instance} . '_fgVdEntHaState'};
    return 0;
}

sub prefix_vdom_output {
    my ($self, %options) = @_;
    
    return "Virtual domain '" . $options{instance_value}->{fgVdEntName} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'vdoms', type => 1, cb_prefix_output => 'prefix_vdom_output', message_multiple => 'All states are ok' },
    ];
    $self->{maps_counters}->{vdoms} = [
        { label => 'status', threshold => 0,  set => {
                key_values => [ { name => 'fgVdEntOpMode' }, { name => 'fgVdEntHaState' }, { name => 'fgVdEntName' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_status_threshold'),
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
                                    "warning-status:s"          => { name => 'warning_status', default => '' },
                                    "critical-status:s"         => { name => 'critical_status', default => '' },
                                });
    return $self;
}

sub change_macros {
    my ($self, %options) = @_;

    foreach (('warning_status', 'critical_status')) {
        if (defined($self->{option_results}->{$_})) {
            $self->{option_results}->{$_} =~ s/%\{(.*?)\}/\$self->{result_values}->{$1}/g;
        }
    }
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros();
    $instance_mode = $self;
}

my %map_op_mode = (
    1 => 'nat',
    2 => 'transparent',
);
my %map_ha_state = (
    1 => 'master',
    2 => 'backup',
    3 => 'standalone',
);

my $mapping = {
    fgVdEntName => { oid => '.1.3.6.1.4.1.12356.101.3.2.1.1.2' },
    fgVdEntOpMode => { oid => '.1.3.6.1.4.1.12356.101.3.2.1.1.3', map => \%map_op_mode },
    fgVdEntHaState => { oid => '.1.3.6.1.4.1.12356.101.3.2.1.1.4', map => \%map_ha_state },
};

my $oid_fgVdInfo = '.1.3.6.1.4.1.12356.101.3.2';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{vdoms} = {};

    my $results = $options{snmp}->get_table(oid => $oid_fgVdInfo , nothing_quit => 1);

    foreach my $oid (keys %{$results}) {
        next if ($oid !~ /^$mapping->{fgVdEntHaState}->{oid}\.(\d+)/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $results, instance => $instance);

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{fgVdEntName} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $name . "': no matching filter name.", debug => 1);
            next;
        }
        
        $self->{vdoms}->{$result->{fgVdEntName}} = {
            fgVdEntName => $result->{fgVdEntName},
            fgVdEntOpMode => $result->{fgVdEntOpMode},
            fgVdEntHaState => $result->{fgVdEntHaState},
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

Check virtual domains operation mode and HA cluster member state.

=over 8

=item B<--filter-name>

Filter by virtual domain name (can be a regexp).

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{op_mode}, %{ha_state}

=item B<--critical-status>

Set critical threshold for status (Default: '').
Can used special variables like: %{op_mode}, %{ha_state}

=back

=cut
