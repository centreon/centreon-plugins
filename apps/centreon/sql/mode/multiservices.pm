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

package apps::centreon::sql::mode::multiservices;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use JSON;

my $config_data;

sub custom_hosts_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{total_up} = $options{new_datas}->{$self->{instance} . '_up'};
    $self->{result_values}->{total_down} = $options{new_datas}->{$self->{instance} . '_down'};
    $self->{result_values}->{total_unreachable} = $options{new_datas}->{$self->{instance} . '_unreachable'};

    return 0
}

sub custom_hosts_output {
    my ($self, %options) = @_;
    my $msg = '';
    $msg .= "[up:".$self->{result_values}->{total_up}."][down:".$self->{result_values}->{total_down}."][unreachable:".$self->{result_values}->{total_unreachable}."]";
    return $msg
}

sub custom_hosts_perfdata {
    my ($self, %options) = @_;

    foreach my $hstate ('up', 'down', 'unreachable') {
        $self->{output}->perfdata_add(
            label => 'total_host_' . $hstate,
            value => $self->{result_values}->{'total_' . $hstate},
            min => 0
        );
    }

}

sub custom_hosts_threshold {
    my ($self, %options) = @_;

    my $message;
    my $status = 'ok';
    eval {
        local $SIG{__WARN__} = sub { $message = $_[0]; };
        local $SIG{__DIE__} = sub { $message = $_[0]; };

        if (defined($self->{instance_mode}->{option_results}->{critical_total}) && $self->{instance_mode}->{option_results}->{critical_total} ne '' &&
            eval "$self->{instance_mode}->{option_results}->{critical_total}") {
            $status = 'critical';
        } elsif (defined($self->{instance_mode}->{option_results}->{warning_total}) && $self->{instance_mode}->{option_results}->{warning_total} ne '' &&
            eval "$self->{instance_mode}->{option_results}->{warning_total}") {
            $status = 'warning';
        }
    };
    if (defined($message)) {
        $self->{output}->output_add(long_msg => 'filter status issue: ' . $message);
    }

    return $status;

}

sub custom_services_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{ok_total} = $options{new_datas}->{$self->{instance} . '_ok'};
    $self->{result_values}->{warning_total} = $options{new_datas}->{$self->{instance} . '_warning'};
    $self->{result_values}->{critical_total} = $options{new_datas}->{$self->{instance} . '_critical'};
    $self->{result_values}->{unknown_total} = $options{new_datas}->{$self->{instance} . '_unknown'};
    return 0
}

sub custom_services_output {
    my ($self, %options) = @_;
    my $msg = '';
    $msg .= "[ok:$self->{result_values}->{ok_total}][warning:$self->{result_values}->{warning_total}][critical:$self->{result_values}->{critical_total}][unknown:$self->{result_values}->{unknown_total}]\n";
    return $msg
}

sub custom_services_perfdata {
    my ($self, %options) = @_;

    foreach my $sstate ('ok', 'warning', 'critical', 'unknown') {
        $self->{output}->perfdata_add(
            label => 'total_service_' . $sstate,
            value => $self->{result_values}->{$sstate . '_total'},
            min => 0
        );
    }
}

sub custom_services_threshold {
    my ($self, %options) = @_;

    my $message;
    my $status = 'ok';

    eval {
        local $SIG{__WARN__} = sub { $message = $_[0]; };
        local $SIG{__DIE__} = sub { $message = $_[0]; };

        if (defined($self->{instance_mode}->{option_results}->{critical_total}) && $self->{instance_mode}->{option_results}->{critical_total} ne '' &&
            eval "$self->{instance_mode}->{option_results}->{critical_total}") {
            $status = 'critical';
        } elsif (defined($self->{instance_mode}->{option_results}->{warning_total}) && $self->{instance_mode}->{option_results}->{warning_total} ne '' &&
            eval "$self->{instance_mode}->{option_results}->{warning_total}") {
            $status = 'warning';
        }
    };
    if (defined($message)) {
        $self->{output}->output_add(long_msg => 'filter status issue: ' . $message);
    }

    return $status;

}

sub custom_groups_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{instance} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{ok} = $options{new_datas}->{$self->{instance} . '_ok'};
    $self->{result_values}->{warning} = $options{new_datas}->{$self->{instance} . '_warning'};
    $self->{result_values}->{critical} = $options{new_datas}->{$self->{instance} . '_critical'};
    $self->{result_values}->{unknown} = $options{new_datas}->{$self->{instance} . '_unknown'};
    $self->{result_values}->{up} = $options{new_datas}->{$self->{instance} . '_up'};
    $self->{result_values}->{down} = $options{new_datas}->{$self->{instance} . '_down'};
    $self->{result_values}->{unreachable} = $options{new_datas}->{$self->{instance} . '_unreachable'};

    return 0
}

sub custom_groups_output {
    my ($self, %options) = @_;

    my $msg_host = '';
    my $msg_svc = '';

    if ($config_data->{formatting}->{display_details} eq 'true') {
        $msg_host .= (defined($self->{instance_mode}->{inventory}->{groups}->{$self->{result_values}->{instance}}->{list_up}))
                        ? "HOSTS: [up: $self->{result_values}->{up} (" . join(' - ', @{$self->{instance_mode}->{inventory}->{groups}->{$self->{result_values}->{instance}}->{list_up}}) . ")]"
                        : "HOSTS: [up: $self->{result_values}->{up}]";
        $msg_host .= (defined($self->{instance_mode}->{inventory}->{groups}->{$self->{result_values}->{instance}}->{list_down}))
                        ? "[down: $self->{result_values}->{down} (" . join(' - ', @{$self->{instance_mode}->{inventory}->{groups}->{$self->{result_values}->{instance}}->{list_down}}) . ")]"
                        : "[down: $self->{result_values}->{down}]";
        $msg_host .= (defined($self->{instance_mode}->{inventory}->{groups}->{unreachable}->{$self->{result_values}->{instance}}->{list_unreachable}))
                        ? "[unreachable: $self->{result_values}->{unreachable} (" . join('-', @{$self->{instance_mode}->{inventory}->{groups}->{$self->{result_values}->{instance}}->{list_unreachable}}) . ")"
                        : "[unreachable: $self->{result_values}->{unreachable}]";

        $msg_svc .= (defined($self->{instance_mode}->{inventory}->{groups}->{$self->{result_values}->{instance}}->{list_ok}))
                        ? "SERVICES: [ok: $self->{result_values}->{ok} (" . join(' - ', @{$self->{instance_mode}->{inventory}->{groups}->{$self->{result_values}->{instance}}->{list_ok}}) .")]"
                        : "SERVICES: [ok: $self->{result_values}->{ok}]";
        $msg_svc .= (defined($self->{instance_mode}->{inventory}->{groups}->{$self->{result_values}->{instance}}->{list_warning}))
                        ? "[warning: $self->{result_values}->{warning} (" . join(' - ', @{$self->{instance_mode}->{inventory}->{groups}->{$self->{result_values}->{instance}}->{list_warning}}) .")]"
                        : "[warning: $self->{result_values}->{warning}]";
        $msg_svc .= (defined($self->{instance_mode}->{inventory}->{groups}->{$self->{result_values}->{instance}}->{list_critical}) > 0)
                        ? "[critical: $self->{result_values}->{critical} (" . join(' - ', @{$self->{instance_mode}->{inventory}->{groups}->{$self->{result_values}->{instance}}->{list_critical}}) .")]"
                        : "[critical: $self->{result_values}->{critical}]";
        $msg_svc .= (defined($self->{instance_mode}->{inventory}->{groups}->{$self->{result_values}->{instance}}->{list_unknown}) > 0)
                        ? "[unknown: $self->{result_values}->{unknown} (" . join(' - ', @{$self->{instance_mode}->{inventory}->{groups}->{$self->{result_values}->{instance}}->{list_unknown}}) .")]"
                        : "[unknown: $self->{result_values}->{unknown}]";


    } else {
        $msg_host .= "HOSTS [up:$self->{result_values}->{up}][down:$self->{result_values}->{down}][critical:$self->{result_values}->{critical}]";
        $msg_svc .= "SERVICES [ok:$self->{result_values}->{ok}][warning:$self->{result_values}->{warning}][critical:$self->{result_values}->{critical}][unknown:$self->{result_values}->{unknown}]";
    }
    return $msg_host . ' - ' . $msg_svc . " \n";
}

sub custom_groups_perfdata {
    my ($self, %options) = @_;

    foreach my $hstate ('up', 'down', 'unreachable') {
        my $warning = $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $hstate);
        my $critical = $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $hstate);
        $self->{output}->perfdata_add(
            label => 'host_' . $hstate . '_' . $self->{result_values}->{instance},
            value => $self->{result_values}->{$hstate},
            warning => $warning,
            critical => $critical,
            min => 0
        );
    }
    foreach my $sstate ('ok', 'warning', 'critical', 'unknown') {
        my $warning = $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $sstate);
        my $critical = $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $sstate);
        $self->{output}->perfdata_add(
            label => 'service_' . $sstate . '_' . $self->{result_values}->{instance},
            value => $self->{result_values}->{$sstate},
            warning => $warning,
            critical => $critical,
            min => 0
        );
    }

}

sub custom_groups_threshold {
    my ($self, %options) = @_;
    my $status = 'ok';
    my $message;

    eval {
        local $SIG{__WARN__} = sub { $message = $_[0]; };
        local $SIG{__DIE__} = sub { $message = $_[0]; };

        if (defined($self->{instance_mode}->{option_results}->{critical_groups}) && $self->{instance_mode}->{option_results}->{critical_groups} ne '' &&
            eval "$self->{instance_mode}->{option_results}->{critical_groups}") {
            $status = 'critical';
        } elsif (defined($self->{instance_mode}->{option_results}->{warning_groups}) && $self->{instance_mode}->{option_results}->{warning_groups} ne '' &&
                 eval "$self->{instance_mode}->{option_results}->{warning_groups}") {
            $status = 'warning';
        }
    };
    if (defined($message)) {
        $self->{output}->output_add(long_msg => 'filter status issue: ' . $message);
    }

    return $status;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
    ];

    $self->{maps_counters}->{totalservice} = [
        { label => 'total-service', threshold => 0, set => {
                key_values => [ { name => 'ok' }, { name => 'warning' }, { name => 'critical' }, { name => 'unknown' } ],
                closure_custom_calc => $self->can('custom_services_calc'),
                closure_custom_output => $self->can('custom_services_output'),
                closure_custom_threshold_check => $self->can('custom_services_threshold'),
                closure_custom_perfdata => $self->can('custom_services_perfdata')
            }
        },
    ];

    $self->{maps_counters}->{totalhost} = [
        { label => 'total-host', threshold => 0, set => {
                key_values => [ { name => 'up' }, { name => 'down' }, { name => 'unreachable' } ],
                closure_custom_calc => $self->can('custom_hosts_calc'),
                closure_custom_output => $self->can('custom_hosts_output'),
                closure_custom_threshold_check => $self->can('custom_hosts_threshold'),
                closure_custom_perfdata => $self->can('custom_hosts_perfdata')
            }
        }
    ];

    $self->{maps_counters}->{logicalgroups} = [
        { label => 'group-svc-global', threshold => 0, set => {
                key_values => [ { name => 'ok' }, { name => 'unknown' }, { name => 'critical' }, { name => 'warning' },
                                { name => 'up' }, { name => 'down' }, { name => 'unreachable' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_groups_calc'),
                closure_custom_output => $self->can('custom_groups_output'),
                closure_custom_threshold_check => $self->can('custom_groups_threshold'),
                closure_custom_perfdata => $self->can('custom_groups_perfdata')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'config:s'          => { name => 'config' },
        'json-data:s'       => { name => 'json_data' },
        'warning-groups:s'  => { name => 'warning_groups' },
        'critical-groups:s' => { name => 'critical_groups' },
        'warning-total:s'   => { name => 'warning_total' },
        'critical-total:s'  => { name => 'critical_total' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{config}) || $self->{option_results}->{config} eq '') {
        $self->{output}->add_option_msg(short_msg => "Please define --config option");
        $self->{output}->option_exit();
    }

    $config_data = $self->parse_json_config(config => $self->{option_results}->{config});

    if (!exists($config_data->{mode})) {
        $config_data->{mode} = 'sqlmatching';
    }
    if (!exists($config_data->{formatting}->{display_details})) {
        $config_data->{formatting}->{display_details} = 'true';
    }
    if (!exists(${config_data}->{formatting}->{host_service_separator})) {
        ${config_data}->{formatting}->{host_service_separator} = '/';
    }
    if (!exists($config_data->{counters}->{totalhosts})) {
        $config_data->{counters}->{totalhosts} = 'true';
    }
    if (!exists($config_data->{counters}->{totalservices})) {
        $config_data->{counters}->{totalservices} = 'true';
    }
    if (!exists($config_data->{counters}->{groups})) {
        $config_data->{counters}->{groups} = 'false';
    }
    if (!exists($config_data->{selection}) || scalar(keys(%{$config_data->{selection}})) <= 0) {
        $self->{output}->add_option_msg(short_msg => "Check config file: selection is not present or empty");
        $self->{output}->option_exit();
    }
    
    $self->change_macros(macros => ['warning_groups', 'critical_groups', 'warning_total', 'critical_total']);
}

sub prefix_totalh_output {
    my ($self, %options) = @_;

    return "Hosts state summary ";
}

sub prefix_totals_output {
    my ($self, %options) = @_;

    return "Services state summary ";
}

sub prefix_groups_output {
    my ($self, %options) = @_;

    return "Group '" . $options{instance_value}->{display} . "': ";
}

sub parse_json_config {
    my ($self, %options) = @_;
    my ($data, $json_text);

    if (-f $options{config} and -r $options{config}) {
        $json_text = do {
            local $/;
            my $fh;
            if (!open($fh, "<:encoding(UTF-8)", $options{config})) {
                $self->{output}->add_option_msg(short_msg => "Can't open file $options{config}: $!");
                $self->{output}->option_exit();
            }
            <$fh>;
        };
    } else {
        $json_text = $options{config};
    }

    eval {
        $data = decode_json($json_text);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json config file: $@");
        $self->{output}->option_exit();
    }
    return $data
}

my %map_host_state = (
    0 => 'up',
    1 => 'down',
    2 => 'unreachable'
);

my %map_service_state = (
    0 => 'ok',
    1 => 'warning',
    2 => 'critical',
    3 => 'unknown',
);

sub manage_selection {
    my ($self, %options) = @_;
    # $options{sql} = sqlmode object
    $self->{sql} = $options{sql};
    $self->{sql}->connect();

    $self->{groups} = {};

    if ($config_data->{counters}->{totalhosts} eq 'true') {
        push @{$self->{maps_counters_type}}, {
            name => 'totalhost', type => 0, cb_prefix_output => 'prefix_totalh_output',
        };
        $self->{totalhost} = { up => 0, down => 0, unreachable => 0 };
    }
    if ($config_data->{counters}->{totalservices} eq 'true') {
        push @{$self->{maps_counters_type}}, {
            name => 'totalservice', type => 0, cb_prefix_output => 'prefix_totals_output',
        };
        $self->{totalservice} = { ok => 0, warning => 0, critical => 0, unknown => 0 };
    }
    if ($config_data->{counters}->{groups} eq 'true') {
        push @{$self->{maps_counters_type}}, {
            name => 'logicalgroups', type => 1, cb_prefix_output => 'prefix_groups_output', message_multiple => $config_data->{formatting}->{groups_global_msg}
        };
    }

    if ($config_data->{mode} eq 'sqlmatching') {
        foreach my $group (keys %{$config_data->{selection}}) {
            if (!exists($config_data->{selection}->{$group}->{host_name_filter})) {
                $self->{output}->add_option_msg(short_msg => "Cannot find host_name_filter nor service_name_filter in config file");
                $self->{output}->option_exit();
            }
            $self->{logicalgroups}->{$group} = {
                display => $group,
                up => 0, down => 0, unreachable => 0,
                ok => 0, warning => 0, critical => 0, unknown => 0
            };

            my $query = "SELECT hosts.name, services.description, hosts.state as hstate, services.state as sstate, services.output as soutput
                         FROM centreon_storage.hosts, centreon_storage.services WHERE hosts.host_id=services.host_id
                         AND hosts.name NOT LIKE 'Module%' AND hosts.enabled=1 AND services.enabled=1
                         AND hosts.name LIKE '" . $config_data->{selection}->{$group}->{'host_name_filter'} . "'
                         AND services.description LIKE '" . $config_data->{selection}->{$group}->{'service_name_filter'} . "'";

            $self->{sql}->query(query => $query);
            while ((my $row = $self->{sql}->fetchrow_hashref())) {
                if (!exists($self->{instance_mode}->{inventory}->{hosts}->{$group}->{$row->{name}})) {
                    push @{$self->{instance_mode}->{inventory}->{groups}->{$group}->{'list_'.$map_host_state{$row->{hstate}}}} ,$row->{name};
                    $self->{totalhost}->{$map_host_state{$row->{hstate}}}++;
                    $self->{logicalgroups}->{$group}->{$map_host_state{$row->{hstate}}}++;
                }
                push @{$self->{instance_mode}->{inventory}->{groups}->{$group}->{'list_'.$map_service_state{$row->{sstate}}}}, $row->{name} . ${config_data}->{formatting}->{host_service_separator} . $row->{description};

                $self->{instance_mode}->{inventory}->{hosts}->{$group}->{$row->{name}} = $row->{hstate};
                $self->{instance_mode}->{inventory}->{services}{ $row->{name} . ${config_data}->{formatting}->{host_service_separator} . $row->{description} } = { state => $row->{sstate}, output => $row->{soutput} } ;
                $self->{instance_mode}->{inventory}->{groups}->{$group}->{$row->{name} . ${config_data}->{formatting}->{host_service_separator} . $row->{description}} = { state => $row->{sstate}, output => $row->{soutput} };

                $self->{totalservice}->{$map_service_state{$row->{sstate}}}++;
                $self->{logicalgroups}->{$group}->{$map_service_state{$row->{sstate}}}++;
            }
        }
    } elsif ($config_data->{mode} eq 'exactmatch') {
        foreach my $group (keys %{$config_data->{selection}}) {
            $self->{logicalgroups}->{$group} = {
                display => $group,
                up => 0, down => 0, unreachable => 0,
                ok => 0, warning => 0, critical => 0, unknown => 0
            };
            foreach my $tuple (keys %{$config_data->{selection}->{$group}}) {
                my $query = "SELECT hosts.name, services.description, hosts.state as hstate, services.state as sstate, services.output as soutput
                             FROM centreon_storage.hosts, centreon_storage.services WHERE hosts.host_id=services.host_id
                             AND hosts.name NOT LIKE 'Module%' AND hosts.enabled=1 AND services.enabled=1
                             AND hosts.name = '" . $tuple . "'
                             AND services.description = '" . $config_data->{selection}->{$group}->{$tuple} . "'";
                $self->{sql}->query(query => $query);
                while ((my $row = $self->{sql}->fetchrow_hashref())) {
                    if (!exists($self->{instance_mode}->{inventory}->{hosts}->{$group}->{$row->{name}})) {
                        push @{$self->{instance_mode}->{inventory}->{groups}->{$group}->{'list_'.$map_host_state{$row->{hstate}}}} ,$row->{name};
                        $self->{totalhost}->{$map_host_state{$row->{hstate}}}++;
                        $self->{logicalgroups}->{$group}->{$map_host_state{$row->{hstate}}}++;
                    }
                    push @{$self->{instance_mode}->{inventory}->{groups}->{$group}->{'list_'.$map_service_state{$row->{sstate}}}}, $row->{name} . ${config_data}->{formatting}->{host_service_separator} . $row->{description};

                    $self->{instance_mode}->{inventory}->{hosts}->{$group}->{$row->{name}} = $row->{hstate};
                    $self->{instance_mode}->{inventory}->{services}{ $row->{name} . ${config_data}->{formatting}->{host_service_separator} . $row->{description} } = { state => $row->{sstate}, output => $row->{soutput} } ;
                    $self->{instance_mode}->{inventory}->{groups}->{$group}->{$row->{name} . ${config_data}->{formatting}->{host_service_separator} . $row->{description}} = { state => $row->{sstate}, output => $row->{soutput} };
                    $self->{totalservice}->{$map_service_state{$row->{sstate}}}++;
                    $self->{logicalgroups}->{$group}->{$map_service_state{$row->{sstate}}}++;
                }
            }
        }
    }
}

1;

__END__

=head1 MODE


=over 8

=item B<--config>

Specify the config (can be a file or a json string directly).

=item B<--filter-counters>

Can be 'totalhost','totalservice','groups'. Better to manage it in config file

=item B<--warning-*>

Can be 'total' for host and service, 'groups' for groups
e.g --warning-total '%{total_unreachable} > 4' --warning-groups '%{instance} eq 'ESX' && %{total_down} > 2 && %{critical_total} > 4'

=item B<--critical-*>

Can be 'total' for host and service, 'groups' for groups

=back

=cut
