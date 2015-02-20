
package centreon::esxd::cmdvmoperationcluster;

use strict;
use warnings;
use centreon::esxd::common;
use centreon::plugins::statefile;
use Digest::MD5 qw(md5_hex);

sub new {
    my $class = shift;
    my $self  = {};
    $self->{logger} = shift;
    $self->{commandName} = 'vmoperationcluster';
    
    bless $self, $class;
    return $self;
}

sub getCommandName {
    my $self = shift;
    return $self->{commandName};
}

sub checkArgs {
    my ($self, %options) = @_;

    if (defined($options{arguments}->{cluster}) && $options{arguments}->{cluster} eq "") {
        $options{manager}->{output}->output_add(severity => 'UNKNOWN',
                                                short_msg => "Argument error: cluster cannot be null");
        return 1;
    }
    foreach my $label (('warning_svmotion', 'critical_svmotion', 'warning_vmotion', 'critical_vmotion',
                        'warning_clone', 'critical_clone')) {
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
    foreach my $label (('warning_svmotion', 'critical_svmotion', 'warning_vmotion', 'critical_vmotion',
                        'warning_clone', 'critical_clone')) {
        $self->{manager}->{perfdata}->threshold_validate(label => $label, value => $options{arguments}->{$label});
    }
}

sub set_connector {
    my ($self, %options) = @_;
    
    $self->{obj_esxd} = $options{connector};
}

sub run {
    my $self = shift;
    
    $self->{statefile_cache} = centreon::plugins::statefile->new(output => $self->{manager}->{output});
    $self->{statefile_cache}->read(statefile_dir => $self->{obj_esxd}->{retention_dir},
                                   statefile => "cache_vmware_connector_" . $self->{obj_esxd}->{whoaim} . "_" . $self->{commandName} . "_" . (defined($self->{cluster}) ? md5_hex($self->{cluster}) : md5_hex('.*')),
                                   statefile_suffix => '',
                                   no_quit => 1);
    return if ($self->{statefile_cache}->error() == 1);

    if (!($self->{obj_esxd}->{perfcounter_speriod} > 0)) {
        $self->{manager}->{output}->output_add(severity => 'UNKNOWN',
                                               short_msg => "Can't retrieve perf counters");
        return ;
    }

    my %filters = ();
    my $multiple = 0;
    if (defined($self->{cluster}) && !defined($self->{cluster})) {
        $filters{name} = qr/^\Q$self->{cluster}\E$/;
    } elsif (!defined($self->{cluster})) {
        $filters{name} = qr/.*/;
    } else {
        $filters{name} = qr/$self->{cluster}/;
    }
    my @properties = ('name');
    my $result = centreon::esxd::common::get_entities_host($self->{obj_esxd}, 'ClusterComputeResource', \%filters, \@properties);
    return if (!defined($result));
    
    if (scalar(@$result) > 1) {
        $multiple = 1;
    }
    my $values = centreon::esxd::common::generic_performance_values_historic($self->{obj_esxd},
                        $result, 
                        [{'label' => 'vmop.numVMotion.latest', 'instances' => ['']},
                         {'label' => 'vmop.numSVMotion.latest', 'instances' => ['']},
                         {'label' => 'vmop.numClone.latest', 'instances' => ['']}],
                        $self->{obj_esxd}->{perfcounter_speriod},
                        skip_undef_counter => 1, multiples => 1, multiples_result_by_entity => 1);
    return if (centreon::esxd::common::performance_errors($self->{obj_esxd}, $values) == 1);
    
    if ($multiple == 1) {
        $self->{manager}->{output}->output_add(severity => 'OK',
                                               short_msg => sprintf("All virtual machine operations are ok"));
    }
    
    my $new_datas = {};
    my $old_datas = {};
    my $checked = 0;
    foreach my $entity_view (@$result) {
        my $entity_value = $entity_view->{mo_ref}->{value};
        my $name = centreon::esxd::common::substitute_name(value => $entity_view->{name});
        my %values = ();
        my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
        my @exits;
        
        foreach my $label (('Clone', 'VMotion', 'SVMotion')) {
            $new_datas->{$label . '_' . $entity_value} = $values->{$entity_value}->{$self->{obj_esxd}->{perfcounter_cache}->{'vmop.num' . $label . '.latest'}->{key} . ":"}[0];
            $old_datas->{$label . '_' . $entity_value} = $self->{statefile_cache}->get(name => $label . '_' . $entity_value);
        
            next if (!defined($old_datas->{$label . '_' . $entity_value}));
            $checked = 1;
            
            if ($old_datas->{$label . '_' . $entity_value} > $new_datas->{$label . '_' . $entity_value}) {
                $old_datas->{$label . '_' . $entity_value} = 0;
            }
                       
            my $diff = $new_datas->{$label . '_' . $entity_value} - $old_datas->{$label . '_' . $entity_value};
            $long_msg .= $long_msg_append . $label . ' ' . $diff;
            $long_msg_append = ', ';

            my $exit2 = $self->{manager}->{perfdata}->threshold_check(value => $diff, threshold => [ { label => 'critical_' . lc($label), exit_litteral => 'critical' }, { label => 'warning_' . lc($label), exit_litteral => 'warning' } ]);
            push @exits, $exit2;
            if ($multiple == 0 || !$self->{manager}->{output}->is_status(litteral => 1, value => $exit2, compare => 'ok')) {
                $short_msg .= $short_msg_append . $label . ' ' . $diff;
                $short_msg_append = ', ';
            }
            
            my $extra_label = '';
            $extra_label = '_' . $name if ($multiple == 1);
            $self->{manager}->{output}->perfdata_add(label => lc($label) . $extra_label,
                                                     value => $diff,
                                                     warning => $self->{manager}->{perfdata}->get_perfdata_for_output(label => 'warning_' . lc($label)),
                                                     critical => $self->{manager}->{perfdata}->get_perfdata_for_output(label => 'critical_' . lc($label)),
                                                     min => 0);
        }
        
        $self->{manager}->{output}->output_add(long_msg => "Cluster '" . $name . "' vm operations: $long_msg");
        my $exit = $self->{manager}->{output}->get_most_critical(status => [ @exits ]);
        if (!$self->{manager}->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
            $self->{manager}->{output}->output_add(severity => $exit,
                                        short_msg => "Cluster '" . $name . "' vm operations: $short_msg"
                                        );
        }
        
        if ($multiple == 0) {
            $self->{manager}->{output}->output_add(short_msg => "Cluster '" . $name . "' vm operations: $long_msg");
        }
    }
    
    if ($checked == 0) {
        $self->{manager}->{output}->output_add(severity => 'OK',
                                               short_msg => sprintf("Buffer creation"));
    }
    $self->{statefile_cache}->write(data => $new_datas);
}

1;
