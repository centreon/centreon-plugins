
package centreon::esxd::cmddatastoreio;

use strict;
use warnings;
use centreon::esxd::common;

sub new {
    my $class = shift;
    my $self  = {};
    $self->{logger} = shift;
    $self->{obj_esxd} = shift;
    $self->{commandName} = 'datastore-io';
    
    bless $self, $class;
    return $self;
}

sub getCommandName {
    my $self = shift;
    return $self->{commandName};
}

sub checkArgs {
    my $self = shift;
    my ($ds, $warn, $crit) = @_;

    if (!defined($ds) || $ds eq "") {
        $self->{logger}->writeLogError("ARGS error: need datastore name");
        return 1;
    }
    if (defined($warn) && $warn ne "" && $warn !~ /^-?(?:\d+\.?|\.\d)\d*\z/) {
        $self->{logger}->writeLogError("ARGS error: warn threshold must be a positive number");
        return 1;
    }
    if (defined($crit) && $crit ne "" && $crit !~ /^-?(?:\d+\.?|\.\d)\d*\z/) {
        $self->{logger}->writeLogError("ARGS error: crit threshold must be a positive number");
        return 1;
    }
    if (defined($warn) && defined($crit) && $warn ne "" && $crit ne "" && $warn > $crit) {
        $self->{logger}->writeLogError("ARGS error: warn threshold must be lower than crit threshold");
        return 1;
    }
    return 0;
}

sub initArgs {
    my $self = shift;
    $self->{ds} = $_[0];
    $self->{warn} = (defined($_[1]) ? $_[1] : '');
    $self->{crit} = (defined($_[2]) ? $_[2] : '');
}

sub run {
    my $self = shift;

    if (!($self->{obj_esxd}->{perfcounter_speriod} > 0)) {
        my $status = centreon::esxd::common::errors_mask(0, 'UNKNOWN');
        $self->{obj_esxd}->print_response(centreon::esxd::common::get_status($status) . "|Can't retrieve perf counters.\n");
        return ;
    }

    my %filters = ('summary.name' => $self->{ds});
    my @properties = ('summary.name');
    my $result = centreon::esxd::common::get_entities_host($self->{obj_esxd}, 'Datastore', \%filters, \@properties);
    if (!defined($result)) {
        return ;
    }

    my $values = centreon::esxd::common::generic_performance_values_historic($self->{obj_esxd},
                        $$result[0], 
                        [{'label' => 'datastore.read.average', 'instances' => ['']},
                         {'label' => 'datastore.write.average', 'instances' => ['']}],
                        $self->{obj_esxd}->{perfcounter_speriod});

    my $read_counter = centreon::esxd::common::simplify_number(centreon::esxd::common::convert_number($values->{$self->{obj_esxd}->{perfcounter_cache}->{'datastore.read.average'}->{'key'} . ":"}[0]));    
    my $write_counter = centreon::esxd::common::simplify_number(centreon::esxd::common::convert_number($values->{$self->{obj_esxd}->{perfcounter_cache}->{'datastore.write.average'}->{'key'} . ":"}[0]));

    my $status = 0; # OK
    my $output = '';
    
    if ((defined($self->{warn}) && $self->{warn} ne "") && 
        ($read_counter >= $self->{warn} || $write_counter >= $self->{warn})) {
        $status = centreon::esxd::common::errors_mask($status, 'WARNING');
    }
    if ((defined($self->{crit}) && $self->{crit} ne "") && 
        ($read_counter >= $self->{crit} || $write_counter >= $self->{crit})) {
        $status = centreon::esxd::common::errors_mask($status, 'CRITICAL');
    }

    $output = "Rate of reading data : " . centreon::esxd::common::simplify_number($read_counter / 1024 * 8) . " Mb/s,  Rate of writing data : " . centreon::esxd::common::simplify_number($write_counter / 1024 * 8) . " Mb/s";
    $output .= "|read_rate=" . ($read_counter * 1024 * 8) . "b/s write_rate=" . (($write_counter * 1024 * 8)) . "b/s";

    $self->{obj_esxd}->print_response(centreon::esxd::common::get_status($status) . "|$output\n");
}

1;
