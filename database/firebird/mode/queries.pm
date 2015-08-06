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

package database::firebird::mode::queries;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::statefile;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "warning:s"               => { name => 'warning', },
                                  "critical:s"              => { name => 'critical', },
                                });
    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);

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
    
    $self->{statefile_cache}->check_options(%options);
}

sub run {
    my ($self, %options) = @_;
    # $options{sql} = sqlmode object
    $self->{sql} = $options{sql};

    $self->{sql}->connect();
    $self->{sql}->query(query => q{
        SELECT MON$RECORD_SEQ_READS,MON$RECORD_INSERTS,MON$RECORD_UPDATES,MON$RECORD_DELETES,MON$RECORD_BACKOUTS,MON$RECORD_PURGES,MON$RECORD_EXPUNGES from MON$RECORD_STATS WHERE MON$STAT_GROUP=0 
    });
    my $result = $self->{sql}->fetchall_arrayref();
    
    if (!($self->{sql}->is_version_minimum(version => '1'))) {
        $self->{output}->add_option_msg(short_msg => "Firebird version '" . $self->{sql}->{version} . "' is not supported (need version >= '1').");
        $self->{output}->option_exit();
    }
    
    my $new_datas = {};
    $self->{statefile_cache}->read(statefile => 'firebird_' . $self->{mode} . '_' . $self->{sql}->get_unique_id4save());
    my $old_timestamp = $self->{statefile_cache}->get(name => 'last_timestamp');
    $new_datas->{last_timestamp} = time();
    
    if (defined($old_timestamp) && $new_datas->{last_timestamp} - $old_timestamp == 0) {
        $self->{output}->add_option_msg(short_msg => "Need at least one second between two checks.");
        $self->{output}->option_exit();
    }
    
    my @field = ("seq_reads","inserts","updates","deletes","backouts","purges","expunges");
    my $i=0;
    foreach my $name (@field) {
    
        $new_datas->{$name} = $$result[0][$i];
        my $old_val = $self->{statefile_cache}->get(name => $name);
        next if (!defined($old_val) || $$result[0][$i] < $old_val);
        
        my $value = int(($$result[0][$i] - $old_val) / ($new_datas->{last_timestamp} - $old_timestamp));
        if ($name ne 'seq_reads') {
            $self->{output}->perfdata_add(label => $name . '_requests',
                                      value => $value,
                                      min => 0);
            $i++;
            next;
        }
        
        my $exit_code = $self->{perfdata}->threshold_check(value => $value, threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
        $self->{output}->output_add(severity => $exit_code,
                                    short_msg => sprintf("Total requests = %s", $value));
        $self->{output}->perfdata_add(label => 'total_requests',
                                      value => $value,
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                      min => 0);
    $i++
    }
    
    $self->{statefile_cache}->write(data => $new_datas); 
    if (!defined($old_timestamp)) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => "Buffer creation...");
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check average number of queries executed.

=over 8

=item B<--warning>

Threshold warning.

=item B<--critical>

Threshold critical.

=back

=cut
