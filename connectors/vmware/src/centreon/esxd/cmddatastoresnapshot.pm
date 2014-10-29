
package centreon::esxd::cmddatastoresnapshot;

use strict;
use warnings;
use centreon::esxd::common;

sub new {
    my $class = shift;
    my $self  = {};
    $self->{logger} = shift;
    $self->{commandName} = 'datastoresnapshot';
    
    bless $self, $class;
    return $self;
}

sub getCommandName {
    my $self = shift;
    return $self->{commandName};
}

sub checkArgs {
    my ($self, %options) = @_;

    if (defined($options{arguments}->{datastore_name}) && $options{arguments}->{datastore_name} eq "") {
        $options{manager}->{output}->output_add(severity => 'UNKNOWN',
                                                short_msg => "Argument error: datastore name cannot be null");
        return 1;
    }
    if (defined($options{arguments}->{disconnect_status}) && 
        $options{manager}->{output}->is_litteral_status(status => $options{arguments}->{disconnect_status}) == 0) {
        $options{manager}->{output}->output_add(severity => 'UNKNOWN',
                                                short_msg => "Argument error: wrong value for disconnect status '" . $options{arguments}->{disconnect_status} . "'");
        return 1;
    }
    foreach my $label (('warning_total', 'critical_total', 'warning_snapshot', 'critical_snapshot')) {
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
    foreach my $label (('warning_total', 'critical_total', 'warning_snapshot', 'critical_snapshot')) {
        $self->{manager}->{perfdata}->threshold_validate(label => $label, value => $options{arguments}->{$label});
    }
}

sub set_connector {
    my ($self, %options) = @_;
    
    $self->{obj_esxd} = $options{connector};
}

sub run {
    my $self = shift;

    my %filters = ();
    my $multiple = 0;
    if (defined($self->{datastore_name}) && !defined($self->{filter})) {
        $filters{name} = qr/^\Q$self->{datastore_name}\E$/;
    } elsif (!defined($self->{datastore_name})) {
        $filters{name} = qr/.*/;
    } else {
        $filters{name} = qr/$self->{datastore_name}/;
    }
    my @properties = ('summary.accessible', 'summary.name', 'browser');
    my $result = centreon::esxd::common::get_entities_host($self->{obj_esxd}, 'Datastore', \%filters, \@properties);
    return if (!defined($result));

    if (scalar(@$result) > 1) {
        $multiple = 1;
    }
    
    my @ds_array = ();
    my %ds_names = ();
    foreach my $entity_view (@$result) {
        next if (centreon::esxd::common::datastore_state(connector => $self->{obj_esxd},
                                                         name => $entity_view->{'summary.name'}, 
                                                         state => $entity_view->{'summary.accessible'},
                                                         status => $self->{disconnect_status},
                                                         multiple => $multiple) == 0);
        if (defined($entity_view->browser)) {
            push @ds_array, $entity_view->browser;
            $ds_names{$entity_view->{mo_ref}->{value}} = $entity_view->{'summary.name'};
        }
    }
    
    @properties = ();
    my $result2;
    return if (!($result2 = centreon::esxd::common::get_views($self->{obj_esxd}, \@ds_array, \@properties)));

    $self->{manager}->{output}->output_add(severity => 'OK',
                                          short_msg => sprintf("All snapshot sizes are ok"));
    foreach my $browse_ds (@$result2) {
        my $dsName; 
        my $tmp_name = $browse_ds->{mo_ref}->{value};
        $tmp_name =~ s/^datastoreBrowser-//i;
        $dsName = $ds_names{$tmp_name};

        $self->{manager}->{output}->output_add(long_msg => "Checking datastore '$dsName':");
        my ($snapshots, $msg) = centreon::esxd::common::search_in_datastore($self->{obj_esxd}, $browse_ds, '[' . $dsName . ']', [VmSnapshotFileQuery->new()], 1);
        if (!defined($snapshots)) {
            $msg =~ s/\n/ /g;
            if ($msg =~ /NoPermissionFault/i) {
                $msg = "Not enough permissions";
            }
            if ($multiple == 0) {
                $self->{manager}->{output}->output_add(severity => 'UNKNOWN',
                                                       short_msg => sprintf("Datastore '%s' %s", $dsName, $msg));
            }
            next;
        }

        my $total_size = 0;
        my $lwarn = '';
        my $lcrit = '';
        foreach (@$snapshots) {
            if (defined($_->file)) {
                foreach my $x (@{$_->file}) {
                    my $exit = $self->{manager}->{perfdata}->threshold_check(value => $x->fileSize, threshold => [ { label => 'critical_snapshot', exit_litteral => 'critical' }, { label => 'warning_snapshot', exit_litteral => 'warning' } ]);                    
                    $self->{manager}->{output}->set_status(exit_litteral => $exit);
                    my ($size_value, $size_unit) = $self->{manager}->{perfdata}->change_bytes(value => $x->fileSize);
                    $self->{manager}->{output}->output_add(long_msg => sprintf("    %s: snapshot [%s]=>[%s] [size = %s]", 
                                                        $exit, $_->folderPath, $x->path, $size_value . ' ' . $size_unit));
                    $total_size += $x->fileSize;
                }
            }
        }
        
        my $exit = $self->{manager}->{perfdata}->threshold_check(value => $total_size, threshold => [ { label => 'critical_total', exit_litteral => 'critical' }, { label => 'warning_total', exit_litteral => 'warning' } ]);        
        my ($size_value, $size_unit) = $self->{manager}->{perfdata}->change_bytes(value => $total_size);
        $self->{manager}->{output}->set_status(exit_litteral => $exit);
        $self->{manager}->{output}->output_add(long_msg => sprintf("    %s: total snapshots [size = %s]", 
                                                        $exit, $size_value . ' ' . $size_unit));
        
        my $extra_label = '';
        $extra_label = '_' . $dsName if ($multiple == 1);
        $self->{manager}->{output}->perfdata_add(label => 'total_size' . $extra_label, unit => 'B',
                                                 value => $total_size,
                                                 warning => $self->{manager}->{perfdata}->get_perfdata_for_output(label => 'warning_total'),
                                                 critical => $self->{manager}->{perfdata}->get_perfdata_for_output(label => 'critical_total'),
                                                 min => 0);
    }
    
    if (!$self->{manager}->{output}->is_status(compare => 'ok', litteral => 1)) {
        $self->{manager}->{output}->output_add(severity => $self->{manager}->{output}->get_litteral_status(),
                                               short_msg => sprintf("Snapshot sizes exceed limits"));
    }
}

1;
