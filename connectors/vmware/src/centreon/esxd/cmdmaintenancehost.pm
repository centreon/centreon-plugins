
package centreon::esxd::cmdmaintenancehost;

use strict;
use warnings;
use centreon::esxd::common;

sub new {
    my $class = shift;
    my $self  = {};
    $self->{logger} = shift;
    $self->{commandName} = 'maintenancehost';
    
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
    if (defined($options{arguments}->{disconnect_status}) && 
        $options{manager}->{output}->is_litteral_status(status => $options{arguments}->{disconnect_status}) == 0) {
        $options{manager}->{output}->output_add(severity => 'UNKNOWN',
                                                short_msg => "Argument error: wrong value for disconnect status '" . $options{arguments}->{disconnect_status} . "'");
        return 1;
    }
    if (defined($options{arguments}->{maintenance_status}) && 
        $options{manager}->{output}->is_litteral_status(status => $options{arguments}->{maintenance_status}) == 0) {
        $options{manager}->{output}->output_add(severity => 'UNKNOWN',
                                                short_msg => "Argument error: wrong value for maintenance status '" . $options{arguments}->{maintenance_status} . "'");
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
}

sub set_connector {
    my ($self, %options) = @_;
    
    $self->{connector} = $options{connector};
}

sub run {
    my $self = shift;

    my %filters = ();
    my $multiple = 0;

    if (defined($self->{esx_hostname}) && !defined($self->{filter})) {
        $filters{name} =  qr/^\Q$self->{esx_hostname}\E$/;
    } elsif (!defined($self->{esx_hostname})) {
        $filters{name} = qr/.*/;
    } else {
        $filters{name} = qr/$self->{esx_hostname}/;
    }
    
    my @properties = ('name', 'runtime.inMaintenanceMode', 'runtime.connectionState');
    my $result = centreon::esxd::common::search_entities(command => $self, view_type => 'HostSystem', properties => \@properties, filter => \%filters);
    return if (!defined($result));

    if (scalar(@$result) > 1) {
        $multiple = 1;
    }
    if ($multiple == 1) {
        $self->{manager}->{output}->output_add(severity => 'OK',
                                               short_msg => sprintf("All ESX maintenance mode are ok"));
    }

    foreach my $entity_view (@$result) {
        next if (centreon::esxd::common::host_state(connector => $self->{connector},
                                                    hostname => $entity_view->{name}, 
                                                    state => $entity_view->{'runtime.connectionState'}->val,
                                                    status => $self->{disconnect_status},
                                                    multiple => $multiple) == 0);
    
        $self->{manager}->{output}->output_add(long_msg => sprintf("'%s' maintenance mode is %s", 
                                                                   $entity_view->{name}, $entity_view->{'runtime.inMaintenanceMode'}));
        
        if ($entity_view->{'runtime.inMaintenanceMode'} =~ /$self->{maintenance_alert}/ && 
            !$self->{manager}->{output}->is_status(value => $self->{maintenance_status}, compare => 'ok', litteral => 1)) {
            $self->{manager}->{output}->output_add(severity => $self->{maintenance_status},
                                                   short_msg => sprintf("'%s' maintenance mode is %s", 
                                                                        $entity_view->{name}, $entity_view->{'runtime.inMaintenanceMode'}))
        } elsif ($multiple == 0) {
            $self->{manager}->{output}->output_add(severity => 'OK',
                                                   short_msg => sprintf("'%s' maintenance mode is %s", 
                                                                        $entity_view->{name}, $entity_view->{'runtime.inMaintenanceMode'}))
        }
    }
}

1;
