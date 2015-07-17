
package centreon::esxd::cmdtoolsvm;

use strict;
use warnings;
use centreon::esxd::common;

sub new {
    my $class = shift;
    my $self  = {};
    $self->{logger} = shift;
    $self->{commandName} = 'toolsvm';
    
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
    if (defined($options{arguments}->{tools_notinstalled_status}) && 
        $options{manager}->{output}->is_litteral_status(status => $options{arguments}->{tools_notinstalled_status}) == 0) {
        $options{manager}->{output}->output_add(severity => 'UNKNOWN',
                                                short_msg => "Argument error: wrong value for tools notinstalled status '" . $options{arguments}->{tools_notinstalled_status} . "'");
        return 1;
    }
    if (defined($options{arguments}->{tools_notrunning_status}) && 
        $options{manager}->{output}->is_litteral_status(status => $options{arguments}->{tools_notrunning_status}) == 0) {
        $options{manager}->{output}->output_add(severity => 'UNKNOWN',
                                                short_msg => "Argument error: wrong value for tools notrunning status '" . $options{arguments}->{tools_notrunning_status} . "'");
        return 1;
    }
    if (defined($options{arguments}->{tools_notupd2date_status}) && 
        $options{manager}->{output}->is_litteral_status(status => $options{arguments}->{tools_notupd2date_status}) == 0) {
        $options{manager}->{output}->output_add(severity => 'UNKNOWN',
                                                short_msg => "Argument error: wrong value for tools notupd2date status '" . $options{arguments}->{tools_notupd2date_status} . "'");
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

sub display_verbose {
    my ($self, %options) = @_;
    
    $self->{manager}->{output}->output_add(long_msg => $options{label});
    foreach my $vm (sort keys %{$options{vms}}) {
        my $prefix = $vm;
        if ($options{vms}->{$vm} ne '') {
            $prefix .= ' [' . centreon::esxd::common::strip_cr(value => $options{vms}->{$vm}) . ']';
        }
        $self->{manager}->{output}->output_add(long_msg => '    ' . $prefix);
    }
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
    
    my @properties = ('name', 'summary.guest.toolsStatus', 'runtime.connectionState', 'runtime.powerState');
    if (defined($self->{display_description})) {
        push @properties, 'config.annotation';
    }
    
    my $result = centreon::esxd::common::search_entities(command => $self, view_type => 'VirtualMachine', properties => \@properties, filter => \%filters);
    return if (!defined($result));

    if (scalar(@$result) > 1) {
        $multiple = 1;
    }
    if ($multiple == 1) {
        $self->{manager}->{output}->output_add(severity => 'OK',
                                               short_msg => sprintf("All VMTools are OK"));
    } else {
        $self->{manager}->{output}->output_add(severity => 'OK',
                                               short_msg => sprintf("VMTools are OK"));
    }
    my %not_installed = ();
    my %not_running = ();
    my %not_up2date = ();
    foreach my $entity_view (@$result) {
        next if (centreon::esxd::common::vm_state(connector => $self->{connector},
                                                  hostname => $entity_view->{name}, 
                                                  state => $entity_view->{'runtime.connectionState'}->val,
                                                  status => $self->{disconnect_status},
                                                  nocheck_ps => 1,
                                                  multiple => $multiple) == 0);
    
        next if (defined($self->{nopoweredon_skip}) && 
                 centreon::esxd::common::is_running(power => $entity_view->{'runtime.powerState'}->val) == 0);
    
        my $tools_status = lc($entity_view->{'summary.guest.toolsStatus'}->val);
        if ($tools_status eq 'toolsnotinstalled') {
            $not_installed{$entity_view->{name}} = defined($entity_view->{'config.annotation'}) ? $entity_view->{'config.annotation'} : '';
        } elsif ($tools_status eq 'toolsnotrunning') {
            $not_running{$entity_view->{name}} = defined($entity_view->{'config.annotation'}) ? $entity_view->{'config.annotation'} : '';
        } elsif ($tools_status eq 'toolsold') {
            $not_up2date{$entity_view->{name}} = defined($entity_view->{'config.annotation'}) ? $entity_view->{'config.annotation'} : '';
        }
    }
    
    if (scalar(keys %not_up2date) > 0 && 
        !$self->{manager}->{output}->is_status(value => $self->{tools_notupd2date_status}, compare => 'ok', litteral => 1)) {
        $self->{manager}->{output}->output_add(severity => $self->{tools_notupd2date_status},
                                               short_msg => sprintf('%d VM with VMTools not up-to-date', scalar(keys %not_up2date)));
        $self->display_verbose(label => 'vmtools not up-to-date:', vms => \%not_up2date);
    }
    if (scalar(keys %not_running) > 0 &&
        !$self->{manager}->{output}->is_status(value => $self->{tools_notrunning_status}, compare => 'ok', litteral => 1)) {
        $self->{manager}->{output}->output_add(severity => $self->{tools_notrunning_status},
                                               short_msg => sprintf('%d VM with VMTools not running', scalar(keys %not_running)));
        $self->display_verbose(label => 'vmtools not running:', vms => \%not_running);
    }
    if (scalar(keys %not_installed) > 0 &&
        !$self->{manager}->{output}->is_status(value => $self->{tools_notupd2date_status}, compare => 'ok', litteral => 1)) {
        $self->{manager}->{output}->output_add(severity => $self->{tools_notupd2date_status},
                                               short_msg => sprintf('%d VM with VMTools not installed', scalar(keys %not_installed)));
        $self->display_verbose(label => 'vmtools not installed:', vms => \%not_installed);
    }
    
    if ($multiple == 1) {
        my $total = scalar(keys %not_up2date) + scalar(keys %not_running) + scalar(keys %not_installed);
        $self->{manager}->{output}->perfdata_add(label => 'not_updated',
                                                 value => scalar(keys %not_up2date),
                                                 min => 0, max => $total);
        $self->{manager}->{output}->perfdata_add(label => 'not_running',
                                                 value => scalar(keys %not_running),
                                                 min => 0, max => $total);
        $self->{manager}->{output}->perfdata_add(label => 'not_installed',
                                                 value => scalar(keys %not_installed),
                                                 min => 0, max => $total);
    }
}

1;
