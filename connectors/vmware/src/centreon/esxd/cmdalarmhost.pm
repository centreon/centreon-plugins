
package centreon::esxd::cmdalarmhost;

use strict;
use warnings;
use centreon::esxd::common;

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
    $self->{manager} = centreon::esxd::common::init_response();
    $self->{manager}->{output}->{plugin} = $options{arguments}->{identity};
    $self->{manager}->{perfdata}->threshold_validate(label => 'warning', value => 0);
    $self->{manager}->{perfdata}->threshold_validate(label => 'critical', value => 0);
}

sub set_connector {
    my ($self, %options) = @_;
    
    $self->{obj_esxd} = $options{connector};
}

sub run {
    my $self = shift;

    my %filters = ();
    my $multiple = 0;

    if (defined($self->{filter_time}) && $self->{filter_time} ne '' && $self->{obj_esxd}->{module_date_parse_loaded} == 0) {
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
    my $result = centreon::esxd::common::get_entities_host($self->{obj_esxd}, 'HostSystem', \%filters, \@properties);
    return if (!defined($result));
    
    if (scalar(@$result) > 1) {
        $multiple = 1;
    }
    $self->{manager}->{output}->output_add(severity => 'OK',
                                          short_msg => sprintf("No current alarms on host(s)"));
    
    my $alarmMgr = centreon::esxd::common::get_view($self->{obj_esxd}, $self->{obj_esxd}->{session1}->get_service_content()->alarmManager, undef);
    my $total_alarms = { red => 0, yellow => 0 };
    my $dc_alarms = {};
    foreach my $datacenter_view (@$result) {
        $dc_alarms->{$datacenter_view->name} = { red => 0, yellow => 0, alarms => {} };
        next if (!defined($datacenter_view->triggeredAlarmState));
        foreach(@{$datacenter_view->triggeredAlarmState}) {
            next if ($_->overallStatus->val !~ /(red|yellow)/i);
            if (defined($self->{filter_time}) && $self->{filter_time} ne '') {
                my $time_sec = Date::Parse::str2time($_->time);
                next if (time() - $time_sec > $self->{filter_time});
            }
            my $entity = centreon::esxd::common::get_view($self->{obj_esxd}, $_->entity, ['name']);
            my $alarm = centreon::esxd::common::get_view($self->{obj_esxd}, $_->alarm, ['info']);
            
            $dc_alarms->{$datacenter_view->name}->{alarms}->{$_->key} = { type => $_->entity->type, name => $entity->name, 
                                                                          time => $_->time, name => $alarm->info->name, 
                                                                          description => $alarm->info->description, 
                                                                          status => $_->overallStatus->val};
            $dc_alarms->{$datacenter_view->name}->{$_->overallStatus->val}++;
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
    
    foreach my $dc_name (keys %{$dc_alarms}) {
        $self->{manager}->{output}->output_add(long_msg => sprintf("Checking host %s", $dc_name));
        $self->{manager}->{output}->output_add(long_msg => sprintf("    %s warn alarm(s) found(s) - %s critical alarm(s) found(s)", 
                                                    $dc_alarms->{$dc_name}->{yellow},  $dc_alarms->{$dc_name}->{red}));
        foreach my $alert (keys %{$dc_alarms->{$dc_name}->{alarms}}) {
            $self->{manager}->{output}->output_add(long_msg => sprintf("    [%s] [%s] [%s] [%s] %s", 
                                                               $dc_alarms->{$dc_name}->{alarms}->{$alert}->{status},
                                                               $dc_alarms->{$dc_name}->{alarms}->{$alert}->{name},
                                                               $dc_alarms->{$dc_name}->{alarms}->{$alert}->{time},
                                                               $dc_alarms->{$dc_name}->{alarms}->{$alert}->{type},
                                                               $dc_alarms->{$dc_name}->{alarms}->{$alert}->{description}
                                                               ));
        }
        
        my $extra_label = '';
        $extra_label = '_' . $dc_name if ($multiple == 1);
        $self->{manager}->{output}->perfdata_add(label => 'alarm_warning' . $extra_label,
                                                 value => $dc_alarms->{$dc_name}->{yellow},
                                                 min => 0);
        $self->{manager}->{output}->perfdata_add(label => 'alarm_critical' . $extra_label,
                                                 value => $dc_alarms->{$dc_name}->{red},
                                                 min => 0);
    }
}

1;
