#
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
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

package database::firebird::mode::memory;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use DBD::Firebird;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "warning:s"               => { name => 'warning', },
                                  "critical:s"              => { name => 'critical', },
                                  "seconds"                 => { name => 'seconds', },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{sql} = sqlmode object
    $self->{sql} = $options{sql};

    $self->{sql}->connect();
   
    if (!($self->{sql}->is_version_minimum(version => '1'))) {
        $self->{output}->add_option_msg(short_msg => "Firebird version '" . $self->{sql}->{version} . "' is not supported (need version >= '1.x').");
        $self->{output}->option_exit();
    }

    $self->{sql}->query(query => q{SELECT MON$STAT_GROUP,MON$MEMORY_ALLOCATED,MON$MEMORY_USED FROM MON$MEMORY_USAGE});
    my  $result = $self->{sql}->fetchall_arrayref();
    if(!defined($result)) {
        $self->{output}->add_option_msg(short_msg => "Cannot get memory.");
        $self->{output}->opion_exit();
    }


    my $mem_allocated;
    my $attach_used=0;
    my $prct_attach=0;
    my $trans_used=0;
    my $prct_trans;
    my $stat_used=0;
    my $prct_stat=0;
    my $call_used=0;
    my $prct_call=0;
    my ($total_value, $total_unit)=(0,0);
    my ($attach_value, $attach_unit)=(0,0);
    my ($trans_value, $trans_unit)=(0,0);
    my ($stat_value, $stat_unit)=(0,0);
    my ($call_value, $call_unit)= (0,'B');

    foreach my $row (@$result) {
        next if (defined($self->{option_results}->{filter}) &&
                 $$row[0] !~ /$self->{option_results}->{filter}/);
        

        
        if ($$row[0] == 0) {
            $mem_allocated = $$row[1];
            ($total_value, $total_unit) =  $self->{perfdata}->change_bytes(value => $mem_allocated);

        } elsif ($$row[0] ==1) {
             $attach_used = $attach_used + $$row[2];
             $prct_attach = $attach_used * 100 / $mem_allocated;
             ($attach_value, $attach_unit) = $self->{perfdata}->change_bytes(value => $attach_used);

        } elsif ($$row[0] == 2) {
             $trans_used = $trans_used + $$row[2];
             $prct_trans = $trans_used * 100 / $mem_allocated;
             ($trans_value, $trans_unit) = $self->{perfdata}->change_bytes(value => $trans_used);


        } elsif ($$row[0] == 3) {
             $stat_used = $stat_used + $$row[2];
             $prct_stat = $stat_used * 100 / $mem_allocated;
             ($stat_value, $stat_unit) = $self->{perfdata}->change_bytes(value => $stat_used);

        } elsif ($$row[0] ==4) {
             $call_used = $call_used + $$row[2];
             $prct_call = $call_used * 100 / $mem_allocated;
             ($call_value, $call_unit) = $self->{perfdata}->change_bytes(value => $call_used);

        }
    }
    my $mem_used = $attach_used + $trans_used + $stat_used + $call_used;
    my $prct_used = $mem_used * 100 / $mem_allocated;
    my ($used_value, $used_unit)=$self->{perfdata}->change_bytes(value => $mem_used);

    my $exit = $self->{perfdata}->threshold_check(value => $prct_used, threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
    $self->{output}->perfdata_add(label => "used", unit => 'B',
                                  value => $mem_used,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning', total => $mem_allocated, cast_int => 1),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical', total => $mem_allocated, cast_int => 1),
                                  min => 0, max => $mem_allocated);
    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("Memory Allocated %s, Total Used %s (%.2f%%)",
                                             $total_value . " " . $total_unit,
                                             $used_value . " " . $used_unit, $prct_used));
    $self->{output}->output_add(long_msg => sprintf("Attachement Used %s (%.2f%%)",
                                $attach_value . " " . $attach_unit, $prct_attach));
    $self->{output}->perfdata_add(label => "attachement", unit => 'B',
                                  value => $attach_used);
    $self->{output}->output_add(long_msg => sprintf("Transaction Used %s (%.2f%%)",
                                $trans_value . " " . $trans_unit, $prct_trans));
    $self->{output}->perfdata_add(label => "transaction", unit => 'B',
                                  value => $trans_used);
    $self->{output}->output_add(long_msg => sprintf("Statement Used %s (%.2f%%)",
                                $stat_value . " " . $stat_unit, $prct_stat));
    $self->{output}->perfdata_add(label => "statement", unit => 'B',
                                  value => $stat_used);
    $self->{output}->output_add(long_msg => sprintf("Call Used %s (%.2f%%)",
                                $call_value . " " . $call_unit, $prct_call));
    $self->{output}->perfdata_add(label => "call", unit => 'B',
                                  value => $call_used);

    $self->{output}->display();
    $self->{output}->exit();

 
}

1;

__END__

=head1 MODE

Check MySQL uptime.

=over 8

=item B<--warning>

Threshold warning.

=item B<--critical>

Threshold critical.

=item B<--seconds>

Display uptime in seconds.

=back

=cut
