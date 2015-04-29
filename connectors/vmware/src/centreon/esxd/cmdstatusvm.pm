
package centreon::esxd::cmdstatusvm;

use strict;
use warnings;
use centreon::esxd::common;

sub new {
    my $class = shift;
    my $self  = {};
    $self->{logger} = shift;
    $self->{commandName} = 'statusvm';
    
    bless $self, $class;
    return $self;
}

sub getCommandName {
    my $self = shift;
    return $self->{commandName};
}

sub checkArgs {
    my ($self, %options) = @_;

    if (defined($options{arguments}->{vm_hostname}) && $options{arguments}->{vm_hostname} eq "") {
        $options{manager}->{output}->output_add(severity => 'UNKNOWN',
                                                short_msg => "Argument error: vm hostname cannot be null");
        return 1;
    }
    if (defined($options{arguments}->{disconnect_status}) && 
        $options{manager}->{output}->is_litteral_status(status => $options{arguments}->{disconnect_status}) == 0) {
        $options{manager}->{output}->output_add(severity => 'UNKNOWN',
                                                short_msg => "Argument error: wrong value for disconnect status '" . $options{arguments}->{disconnect_status} . "'");
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
    
    if (defined($self->{vm_hostname}) && !defined($self->{filter})) {
        $filters{name} = qr/^\Q$self->{vm_hostname}\E$/;
    } elsif (!defined($self->{vm_hostname})) {
        $filters{name} = qr/.*/;
    } else {
        $filters{name} = qr/$self->{vm_hostname}/;
    }
    if (defined($self->{filter_description}) && $self->{filter_description} ne '') {
        $filters{'config.annotation'} = qr/$self->{filter_description}/;
    }
    if (defined($self->{display_description})) {
        push @properties, 'config.annotation';
    }
    my @properties = ('name', 'summary.overallStatus', 'runtime.connectionState');
    my $result = centreon::esxd::common::search_entities(command => $self, view_type => 'VirtualMachine', properties => \@properties, filter => \%filters);
    return if (!defined($result));

    if (scalar(@$result) > 1) {
        $multiple = 1;
    }
    my %overallStatus = (
        'gray'      => 'status is unknown',
        'green'     => 'is OK',
        'red'       => 'has a problem',
        'yellow'    => 'might have a problem',
    );
    my %overallStatusReturn = (
        'gray'      => 'UNKNOWN',
        'green'     => 'OK',
        'red'       => 'CRITICAL',
        'yellow'    => 'WARNING'
    );

    if ($multiple == 1) {
        $self->{manager}->{output}->output_add(severity => 'OK',
                                               short_msg => sprintf("All virtual machines are ok"));
    }
    
    foreach my $entity_view (@$result) {
        next if (centreon::esxd::common::vm_state(connector => $self->{connector},
                                                  hostname => $entity_view->{name}, 
                                                  state => $entity_view->{'runtime.connectionState'}->val,
                                                  status => $self->{disconnect_status},
                                                  multiple => $multiple) == 0);
        
        my $status_vm = $entity_view->{'summary.overallStatus'}->val;
        $self->{manager}->{output}->output_add(long_msg => sprintf("'%s' %s", $entity_view->{name}, $overallStatus{$status_vm}));
        
        if ($multiple == 0 || 
            !$self->{manager}->{output}->is_status(value => $overallStatusReturn{$status_vm}, compare => 'ok', litteral => 1)) {
            $self->{manager}->{output}->output_add(severity => $overallStatusReturn{$status_vm},
                                                   short_msg => sprintf("'%s' %s", $entity_view->{name}, $overallStatus{$status_vm}));
        }
    }
}

1;
