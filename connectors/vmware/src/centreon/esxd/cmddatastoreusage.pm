
package centreon::esxd::cmddatastoreusage;

use strict;
use warnings;
use centreon::esxd::common;

sub new {
    my $class = shift;
    my $self  = {};
    $self->{logger} = shift;
    $self->{commandName} = 'datastoreusage';
    
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
     if (!defined($options{arguments}->{units}) || $options{arguments}->{units} !~ /^(%|B)$/) {
        $self->{output}->add_option_msg(short_msg => "Wrong units option '" . (defined($options{arguments}->{units}) ? $options{arguments}->{units} : 'null') . "'.");
        $self->{output}->option_exit();
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

    my %filters = ();
    my $multiple = 0;
    if (defined($self->{datastore_name}) && !defined($self->{filter})) {
        $filters{name} = qr/^\Q$self->{datastore_name}\E$/;
    } elsif (!defined($self->{datastore_name})) {
        $filters{name} = qr/.*/;
    } else {
        $filters{name} = qr/$self->{datastore_name}/;
    }
    my @properties = ('summary');

    my $result = centreon::esxd::common::get_entities_host($self->{obj_esxd}, 'Datastore', \%filters, \@properties);
    return if (!defined($result));
    
    if (scalar(@$result) > 1) {
        $multiple = 1;
    }
    if ($multiple == 1) {
        $self->{manager}->{output}->output_add(severity => 'OK',
                                               short_msg => sprintf("All Datastore usages are ok"));
    }
    
    foreach my $entity_view (@$result) {
        next if (centreon::esxd::common::datastore_state(connector => $self->{obj_esxd},
                                                         name => $entity_view->summary->name, 
                                                         state => $entity_view->summary->accessible,
                                                         status => $self->{disconnect_status},
                                                         multiple => $multiple) == 0);
        
        # capacity 0...
        if ($entity_view->summary->capacity <= 0) {
            if ($multiple == 0) {
                $self->{manager}->{output}->output_add(severity => 'OK',
                                               short_msg => sprintf("datastore size is 0"));
            }
            next;
        }

        # in Bytes
        my $name_storage = $entity_view->summary->name;        
        my $total_size = $entity_view->summary->capacity;
        my $total_free = $entity_view->summary->freeSpace;
        my $total_used = $total_size - $total_free;
        my $prct_used = $total_used * 100 / $total_size;
        my $prct_free = 100 - $prct_used;
        
        my ($exit, $threshold_value);
        $threshold_value = $total_used;
        $threshold_value = $total_free if (defined($self->{free}));
        if ($self->{units} eq '%') {
            $threshold_value = $prct_used;
            $threshold_value = $prct_free if (defined($self->{free}));
        } 
        $exit = $self->{manager}->{perfdata}->threshold_check(value => $threshold_value, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

        my ($total_size_value, $total_size_unit) = $self->{manager}->{perfdata}->change_bytes(value => $total_size);
        my ($total_used_value, $total_used_unit) = $self->{manager}->{perfdata}->change_bytes(value => $total_used);
        my ($total_free_value, $total_free_unit) = $self->{manager}->{perfdata}->change_bytes(value => $total_free);

        $self->{manager}->{output}->output_add(long_msg => sprintf("Datastore '%s' Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)", $name_storage,
                                            $total_size_value . " " . $total_size_unit,
                                            $total_used_value . " " . $total_used_unit, $prct_used,
                                            $total_free_value . " " . $total_free_unit, $prct_free));
        if (!$self->{manager}->{output}->is_status(value => $exit, compare => 'ok', litteral => 1) || $multiple == 0) {
            $self->{manager}->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Datastore '%s' Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)", $name_storage,
                                            $total_size_value . " " . $total_size_unit,
                                            $total_used_value . " " . $total_used_unit, $prct_used,
                                            $total_free_value . " " . $total_free_unit, $prct_free));
        }    

        my $label = 'used';
        my $value_perf = $total_used;
        if (defined($self->{free})) {
            $label = 'free';
            $value_perf = $total_free;
        }
        my $extra_label = '';
        $extra_label = '_' . $name_storage if ($multiple == 1);
        my %total_options = ();
        if ($self->{units} eq '%') {
            $total_options{total} = $total_size;
            $total_options{cast_int} = 1; 
        }
        $self->{manager}->{output}->perfdata_add(label => $label . $extra_label, unit => 'B',
                                                 value => $value_perf,
                                                 warning => $self->{manager}->{perfdata}->get_perfdata_for_output(label => 'warning', %total_options),
                                                 critical => $self->{manager}->{perfdata}->get_perfdata_for_output(label => 'critical', %total_options),
                                                 min => 0, max => $total_size);
    }
}

1;
