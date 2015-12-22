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

package network::f5::bigip::mode::failover;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::values;

my $instance_mode;

my $maps_counters = {
    global => [
        { label => 'sync-status', threshold => 0, set => {
                key_values => [ { name => 'syncstatus' } ],
                closure_custom_calc => \&custom_syncstatus_calc,
                closure_custom_output => \&custom_syncstatus_output,
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&custom_syncstatus_threshold,
            }
        },
        { label => 'failover-status', threshold => 0, set => {
                key_values => [ { name => 'failoverstatus' } ],
                closure_custom_calc => \&custom_failoverstatus_calc,
                closure_custom_output => \&custom_failoverstatus_output,
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&custom_failoverstatus_threshold,
            }
        },
    ]
};

sub custom_syncstatus_threshold {
    my ($self, %options) = @_; 
    my $status = 'ok';
    my $message;
    
    eval {
        local $SIG{__WARN__} = sub { $message = $_[0]; };
        local $SIG{__DIE__} = sub { $message = $_[0]; };
        
        if (defined($instance_mode->{option_results}->{critical_sync_status}) && $instance_mode->{option_results}->{critical_sync_status} ne '' &&
            eval "$instance_mode->{option_results}->{critical_sync_status}") {
            $status = 'critical';
        } elsif (defined($instance_mode->{option_results}->{critical_sync_status}) && $instance_mode->{option_results}->{critical_sync_status} ne '' &&
                 eval "$instance_mode->{option_results}->{critical_sync_status}") {
            $status = 'warning';
        }
    };
    if (defined($message)) {
        $self->{output}->output_add(long_msg => 'filter status issue: ' . $message);
    }

    return $status;
}

sub custom_syncstatus_output {
    my ($self, %options) = @_;
    my $msg = "Sync status is '" . $self->{result_values}->{syncstatus} . "'";

    return $msg;
}

sub custom_syncstatus_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{syncstatus} = $options{new_datas}->{$self->{instance} . '_syncstatus'};
    return 0;
}

sub custom_failoverstatus_threshold {
    my ($self, %options) = @_; 
    my $status = 'ok';
    my $message;
    
    eval {
        local $SIG{__WARN__} = sub { $message = $_[0]; };
        local $SIG{__DIE__} = sub { $message = $_[0]; };
        
        if (defined($instance_mode->{option_results}->{critical_failover_status}) && $instance_mode->{option_results}->{critical_failover_status} ne '' &&
            eval "$instance_mode->{option_results}->{critical_failover_status}") {
            $status = 'critical';
        } elsif (defined($instance_mode->{option_results}->{critical_failover_status}) && $instance_mode->{option_results}->{critical_failover_status} ne '' &&
                 eval "$instance_mode->{option_results}->{critical_failover_status}") {
            $status = 'warning';
        }
    };
    if (defined($message)) {
        $self->{output}->output_add(long_msg => 'filter status issue: ' . $message);
    }

    return $status;
}

sub custom_failoverstatus_output {
    my ($self, %options) = @_;
    my $msg = "Failover status is '" . $self->{result_values}->{failoverstatus} . "'";

    return $msg;
}

sub custom_failoverstatus_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{failoverstatus} = $options{new_datas}->{$self->{instance} . '_failoverstatus'};
    return 0;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                "filter-counters:s" => { name => 'filter_counters' },
                                "warning-sync-status:s"        => { name => 'warning_sync_status', default => '' },
                                "critical-sync-status:s"       => { name => 'critical_sync_status', default => '%{syncstatus} =~ /unknown|syncFailed|syncDisconnected|incompatibleVersion/' },
                                "warning-failover-status:s"        => { name => 'warning_failover_status', default => '' },
                                "critical-failover-status:s"       => { name => 'critical_failover_status', default => '%{failoverstatus} =~ /unknown/' },
                                });

    foreach my $key (('global')) {
        foreach (@{$maps_counters->{$key}}) {
            if (!defined($_->{threshold}) || $_->{threshold} != 0) {
                $options{options}->add_options(arguments => {
                                                            'warning-' . $_->{label} . ':s'    => { name => 'warning-' . $_->{label} },
                                                            'critical-' . $_->{label} . ':s'    => { name => 'critical-' . $_->{label} },
                                               });
            }
            $_->{obj} = centreon::plugins::values->new(statefile => $self->{statefile_value},
                                                       output => $self->{output}, perfdata => $self->{perfdata},
                                                       label => $_->{label});
            $_->{obj}->set(%{$_->{set}});
        }
    }
                                
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    foreach my $key (('global')) {
        foreach (@{$maps_counters->{$key}}) {
            $_->{obj}->init(option_results => $self->{option_results});
        }
    }
    
    $instance_mode = $self;
    $self->change_macros();
}

sub run_global {
    my ($self, %options) = @_;
    
    my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
    my @exits;
    foreach (@{$maps_counters->{global}}) {
        my $obj = $_->{obj};

        next if (defined($self->{option_results}->{filter_counters}) && $self->{option_results}->{filter_counters} ne '' &&
            $_->{name} !~ /$self->{option_results}->{filter_counters}/);
        
        $obj->set(instance => 'global');
    
        my ($value_check) = $obj->execute(values => $self->{global});

        if ($value_check != 0) {
            $long_msg .= $long_msg_append . $obj->output_error();
            $long_msg_append = ' - ';
            next;
        }
        my $exit2 = $obj->threshold_check();
        push @exits, $exit2;

        my $output = $obj->output();
        $long_msg .= $long_msg_append . $output;
        $long_msg_append = ' - ';
        
        if (!$self->{output}->is_status(litteral => 1, value => $exit2, compare => 'ok')) {
            $short_msg .= $short_msg_append . $output;
            $short_msg_append = ' - ';
        }
        
        $obj->perfdata();
    }

    my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
    if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => "$short_msg"
                                    );
    } else {
        $self->{output}->output_add(short_msg => "$long_msg");
    }
}

sub run {
    my ($self, %options) = @_;
    
    $self->manage_selection(%options);
    
    $self->run_global();

    $self->{output}->display();
    $self->{output}->exit();
}

sub change_macros {
    my ($self, %options) = @_;
    
    foreach (('warning_sync_status', 'critical_sync_status', 'warning_failover_status', 'critical_failover_status')) {
        if (defined($self->{option_results}->{$_})) {
            $self->{option_results}->{$_} =~ s/%\{(.*?)\}/\$self->{result_values}->{$1}/g;
        }
    }
}

my %map_boolean = (
    0 => 'false',
    1 => 'true',
);
my %map_sync_status = (
    0 => 'unknown',
    1 => 'syncing',
    2 => 'needManualSync',
    3 => 'inSync',
    4 => 'syncFailed',
    5 => 'syncDisconnected',
    6 => 'standalone',
    7 => 'awaitingInitialSync',
    8 => 'incompatibleVersion',
    9 => 'partialSync',
);
my %map_failover_status = (
    0 => 'unknown',
    1 => 'offline',
    2 => 'forcedOffline',
    3 => 'standby',
    4 => 'active',
);

my $mapping = {
    sysAttrFailoverIsRedundant  => { oid => '.1.3.6.1.4.1.3375.2.1.1.1.1.13', map => \%map_boolean },
    sysAttrModeMaint            => { oid => '.1.3.6.1.4.1.3375.2.1.1.1.1.21', map => \%map_boolean },
    sysCmSyncStatusId           => { oid => '.1.3.6.1.4.1.3375.2.1.14.1.1', map => \%map_sync_status },
    sysCmFailoverStatusId       => { oid => '.1.3.6.1.4.1.3375.2.1.14.3.1', map => \%map_failover_status },
};

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{snmp}->get_leef(oids => [$mapping->{sysAttrFailoverIsRedundant}->{oid} . '.0',
                                                   $mapping->{sysAttrModeMaint}->{oid} . '.0',
                                                   $mapping->{sysCmSyncStatusId}->{oid} . '.0',
                                                   $mapping->{sysCmFailoverStatusId}->{oid} . '.0'],
                                         nothing_quit => 1);
    my $result2 = $options{snmp}->map_instance(mapping => $mapping, results => $result, instance => '0');
    
    if ($result2->{sysAttrModeMaint} eq 'true') {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'maintenance mode is active');
        $self->{output}->display();
        $self->{output}->exit();
    }
    if ($result2->{sysAttrFailoverIsRedundant} eq 'false') {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'failover mode is disable');
        $self->{output}->display();
        $self->{output}->exit();
    }
    
    $self->{global} = { 
        syncstatus => $result2->{sysCmSyncStatusId},
        failoverstatus => $result2->{sysCmFailoverStatusId},
    };
}
    
1;

__END__

=head1 MODE

Check failover status.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).

=item B<--warning-sync-status>

Set warning threshold for sync status
Can used special variables like: %{syncstatus}

=item B<--critical-sync-status>

Set critical threshold for sync status (Default: '%{syncstatus} =~ /unknown|syncFailed|syncDisconnected|incompatibleVersion/').
Can used special variables like: %{syncstatus}

=item B<--warning-failover-status>

Set warning threshold for failover status
Can used special variables like: %{failoverstatus}

=item B<--critical-failover-status>

Set critical threshold for failover status (Default: '%{failoverstatus} =~ /unknown/').
Can used special variables like: %{failoverstatus}

=back

=cut