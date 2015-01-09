
package centreon::esxd::cmdsnapshotvm;

use strict;
use warnings;
use centreon::esxd::common;

sub new {
    my $class = shift;
    my $self  = {};
    $self->{logger} = shift;
    $self->{commandName} = 'snapshotvm';
    
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
    foreach my $label (('warning', 'critical')) {
        if (($options{manager}->{perfdata}->threshold_validate(label => $label, value => $options{arguments}->{$label})) == 0) {
            $options{manager}->{output}->output_add(severity => 'UNKNOWN',
                                                    short_msg => "Argument error: wrong value for $label value '" . $options{arguments}->{$label} . "'.");
            return 1;
        }
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
    foreach my $label (('warning', 'critical')) {
        $self->{manager}->{perfdata}->threshold_validate(label => $label, value => $options{arguments}->{$label});
    }
}

sub set_connector {
    my ($self, %options) = @_;
    
    $self->{obj_esxd} = $options{connector};
}

sub run {
    my $self = shift;

    if ($self->{obj_esxd}->{module_date_parse_loaded} == 0) {
        $self->{manager}->{output}->output_add(severity => 'UNKNOWN',
                                               short_msg => "Need to install Date::Parse CPAN Module");
        return ;
    }

    my %filters = ();
    my $multiple = 0;
    if (defined($self->{vm_hostname}) && !defined($self->{filter})) {
        $filters{name} = qr/^\Q$self->{vm_hostname}\E$/;
    } elsif (!defined($self->{vm_hostname})) {
        $filters{name} = qr/.*/;
    } else {
        $filters{name} = qr/$self->{vm_hostname}/;
    }
    my @properties = ('snapshot.rootSnapshotList', 'name', 'runtime.connectionState', 'runtime.powerState');
    if (defined($self->{check_consolidation}) == 1) {
        push @properties, 'runtime.consolidationNeeded';
    }
    if (defined($self->{display_description})) {
        push @properties, 'config.annotation';
    }

    my $result = centreon::esxd::common::get_entities_host($self->{obj_esxd}, 'VirtualMachine', \%filters, \@properties);
    return if (!defined($result));

    my %vm_consolidate = ();
    my %vm_errors = (warning => {}, critical => {});    
    if (scalar(@$result) > 1) {
        $multiple = 1;
    }
    if ($multiple == 1) {
        $self->{manager}->{output}->output_add(severity => 'OK',
                                               short_msg => sprintf("All snapshots are ok"));
    } else {
        $self->{manager}->{output}->output_add(severity => 'OK',
                                               short_msg => sprintf("Snapshot(s) OK"));
    }
    foreach my $entity_view (@$result) {
        next if (centreon::esxd::common::vm_state(connector => $self->{obj_esxd},
                                                  hostname => $entity_view->{name}, 
                                                  state => $entity_view->{'runtime.connectionState'}->val,
                                                  status => $self->{disconnect_status},
                                                  nocheck_ps => 1,
                                                  multiple => $multiple) == 0);
    
        next if (defined($self->{nopoweredon_skip}) && 
                 !centreon::esxd::common::is_running(power => $entity_view->{'runtime.powerState'}->val) == 0);
    
        if (defined($self->{check_consolidation}) && defined($entity_view->{'runtime.consolidationNeeded'}) && $entity_view->{'runtime.consolidationNeeded'} =~ /^true|1$/i) {
            $vm_consolidate{$entity_view->{name}} = 1;
        }

        next if (!defined($entity_view->{'snapshot.rootSnapshotList'}));
    
        foreach my $snapshot (@{$entity_view->{'snapshot.rootSnapshotList'}}) {
            # 2012-09-21T14:16:17.540469Z
            my $create_time = Date::Parse::str2time($snapshot->createTime);
            if (!defined($create_time)) {
                $self->{manager}->{output}->output_add(severity => 'UNKNOWN',
                                                       short_msg => "Can't Parse date '" . $snapshot->createTime . "' for vm '" . $entity_view->{name} . "'");
                next;
            }
            
            my $diff_time = time() - $create_time;
            my $days = int($diff_time / 60 / 60 / 24);
            my $exit = $self->{manager}->{perfdata}->threshold_check(value => $diff_time, threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
            
            my $prefix_msg = "'$entity_view->{name}'";
            if (defined($self->{display_description}) && defined($entity_view->{'config.annotation'}) &&
                $entity_view->{'config.annotation'} ne '') {
                $prefix_msg .= ' [' . centreon::esxd::common::strip_cr(value => $entity_view->{'config.annotation'}) . ']';
            }
            if (!$self->{manager}->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $vm_errors{$exit}->{$entity_view->{name}} = 1;
                $self->{manager}->{output}->output_add(long_msg => "$prefix_msg snapshot create time: " . $snapshot->createTime);
            }
        }
    }

    $self->{manager}->{output}->perfdata_add(label => 'num_warning',
                                             value => scalar(keys %{$vm_errors{warning}}),
                                             min => 0);
    $self->{manager}->{output}->perfdata_add(label => 'num_critical',
                                             value => scalar(keys %{$vm_errors{critical}}),
                                             min => 0);
    if (scalar(keys %{$vm_errors{warning}}) > 0) {
        $self->{manager}->{output}->output_add(severity => 'WARNING',
                                               short_msg => sprintf('Snapshots for VM older than %d days: [%s]', ($self->{warning} / 86400), 
                                                                    join('] [', sort keys %{$vm_errors{warning}})));
    }
    if (scalar(keys %{$vm_errors{critical}}) > 0) {
        $self->{manager}->{output}->output_add(severity => 'CRITICAL',
                                               short_msg => sprintf('Snapshots for VM older than %d days: [%s]', ($self->{critical} / 86400), 
                                                                    join('] [', sort keys %{$vm_errors{critical}})));
    }
    if (scalar(keys %vm_consolidate) > 0) {
         $self->{manager}->{output}->output_add(severity => 'CRITICAL',
                                                short_msg => sprintf('VMs need consolidation: [%s]',
                                                                     join('] [', sort keys %vm_consolidate)));
    }
}

1;
