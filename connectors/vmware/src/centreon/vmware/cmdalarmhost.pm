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
#    http://www.apache.org/licenses/LICENSE-2.0  
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

package centreon::vmware::cmdalarmhost;

use strict;
use warnings;
use centreon::vmware::common;
use centreon::plugins::statefile;
use Digest::MD5 qw(md5_hex);

sub new {
    my $class = shift;
    my $self  = {};
    $self->{logger} = shift;
    $self->{commandName} = 'alarmhost';
    
    bless $self, $class;
    return $self;
}

sub getCommandName {
    my $self = shift;
    return $self->{commandName};
}

sub checkArgs {
    my ($self, %options) = @_;

    if (defined($options{arguments}->{esx_hostname}) && $options{arguments}->{esx_hostname} eq "") {
        $options{manager}->{output}->output_add(severity => 'UNKNOWN',
                                                short_msg => "Argument error: esx hostname cannot be null");
        return 1;
    }
    return 0;
}

sub initArgs {
    my ($self, %options) = @_;
    
    foreach (keys %{$options{arguments}}) {
        $self->{$_} = $options{arguments}->{$_};
    }
    $self->{manager} = centreon::vmware::common::init_response();
    $self->{manager}->{output}->{plugin} = $options{arguments}->{identity};
    $self->{manager}->{perfdata}->threshold_validate(label => 'warning', value => 0);
    $self->{manager}->{perfdata}->threshold_validate(label => 'critical', value => 0);
}

sub set_connector {
    my ($self, %options) = @_;
    
    $self->{connector} = $options{connector};
}

sub run {
    my $self = shift;
    
    if (defined($self->{memory})) {
        $self->{statefile_cache} = centreon::plugins::statefile->new(output => $self->{manager}->{output});
        $self->{statefile_cache}->read(statefile_dir => $self->{connector}->{retention_dir},
                                       statefile => "cache_vmware_connector_" . $self->{connector}->{whoaim} . "_" . (defined($self->{esx_hostname}) ? md5_hex($self->{esx_hostname}) : md5_hex('.*')),
                                       statefile_suffix => '',
                                       no_quit => 1);
        return if ($self->{statefile_cache}->error() == 1);
    }

    my %filters = ();
    my $multiple = 0;

    if (defined($self->{filter_time}) && $self->{filter_time} ne '' && $self->{connector}->{module_date_parse_loaded} == 0) {
        $self->{manager}->{output}->output_add(severity => 'UNKNOWN',
                                               short_msg => "Need to install Date::Parse CPAN Module");
        return ;
    }
    
    if (defined($self->{esx_hostname}) && !defined($self->{filter})) {
        $filters{name} = qr/^\Q$self->{esx_hostname}\E$/;
    } elsif (!defined($self->{esx_hostname})) {
        $filters{name} = qr/.*/;
    } else {
        $filters{name} = qr/$self->{esx_hostname}/;
    }
    
    my @properties = ('name', 'triggeredAlarmState');
    my $result = centreon::vmware::common::search_entities(command => $self, view_type => 'HostSystem', properties => \@properties, filter => \%filters);
    return if (!defined($result));
    
    if (scalar(@$result) > 1) {
        $multiple = 1;
    }
    $self->{manager}->{output}->output_add(severity => 'OK',
                                          short_msg => sprintf("No current alarms on host(s)"));
    
    my $alarmMgr = centreon::vmware::common::get_view($self->{connector}, $self->{connector}->{session1}->get_service_content()->alarmManager, undef);
    my $total_alarms = { red => 0, yellow => 0 };
    my $host_alarms = {};
    my $new_datas = {};
    foreach my $host_view (@$result) {
        $host_alarms->{$host_view->name} = { red => 0, yellow => 0, alarms => {} };
        next if (!defined($host_view->triggeredAlarmState));
        foreach(@{$host_view->triggeredAlarmState}) {
            next if ($_->overallStatus->val !~ /(red|yellow)/i);
            if (defined($self->{filter_time}) && $self->{filter_time} ne '') {
                my $time_sec = Date::Parse::str2time($_->time);
                next if (time() - $time_sec > $self->{filter_time});
            }
            $new_datas->{$_->key} = 1;
            next if (defined($self->{memory}) && defined($self->{statefile_cache}->get(name => $_->key)));

            my $entity = centreon::vmware::common::get_view($self->{connector}, $_->entity, ['name']);
            my $alarm = centreon::vmware::common::get_view($self->{connector}, $_->alarm, ['info']);
            
            $host_alarms->{$host_view->name}->{alarms}->{$_->key} = { type => $_->entity->type, name => $entity->name, 
                                                                          time => $_->time, name => $alarm->info->name, 
                                                                          description => $alarm->info->description, 
                                                                          status => $_->overallStatus->val};
            $host_alarms->{$host_view->name}->{$_->overallStatus->val}++;
            $total_alarms->{$_->overallStatus->val}++;
        }
    }

    my $exit = $self->{manager}->{perfdata}->threshold_check(value => $total_alarms->{yellow}, 
                                                             threshold => [ { label => 'warning', exit_litteral => 'warning' } ]);
    if (!$self->{manager}->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{manager}->{output}->output_add(severity => $exit,
                                               short_msg => sprintf("%s alarm(s) found(s)", $total_alarms->{yellow}));
    }
    $exit = $self->{manager}->{perfdata}->threshold_check(value => $total_alarms->{red}, threshold => [ { label => 'critical', exit_litteral => 'critical' } ]);
    if (!$self->{manager}->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{manager}->{output}->output_add(severity => $exit,
                                               short_msg => sprintf("%s alarm(s) found(s)", $total_alarms->{red}));
    }    
    
    foreach my $host_name (keys %{$host_alarms}) {
        $self->{manager}->{output}->output_add(long_msg => sprintf("Checking host %s", $host_name));
        $self->{manager}->{output}->output_add(long_msg => sprintf("    %s warn alarm(s) found(s) - %s critical alarm(s) found(s)", 
                                                    $host_alarms->{$host_name}->{yellow},  $host_alarms->{$host_name}->{red}));
        foreach my $alert (keys %{$host_alarms->{$host_name}->{alarms}}) {
            $self->{manager}->{output}->output_add(long_msg => sprintf("    [%s] [%s] [%s] [%s] %s", 
                                                               $host_alarms->{$host_name}->{alarms}->{$alert}->{status},
                                                               $host_alarms->{$host_name}->{alarms}->{$alert}->{name},
                                                               $host_alarms->{$host_name}->{alarms}->{$alert}->{time},
                                                               $host_alarms->{$host_name}->{alarms}->{$alert}->{type},
                                                               $host_alarms->{$host_name}->{alarms}->{$alert}->{description}
                                                               ));
        }
        
        my $extra_label = '';
        $extra_label = '_' . $host_name if ($multiple == 1);
        $self->{manager}->{output}->perfdata_add(label => 'alarm_warning' . $extra_label,
                                                 value => $host_alarms->{$host_name}->{yellow},
                                                 min => 0);
        $self->{manager}->{output}->perfdata_add(label => 'alarm_critical' . $extra_label,
                                                 value => $host_alarms->{$host_name}->{red},
                                                 min => 0);
    }

    if (defined($self->{memory})) {
        $self->{statefile_cache}->write(data => $new_datas);
    }
}

1;
