#
# Copyright 2021 Centreon (http://www.centreon.com/)
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

package database::informix::sql::mode::lockoverflow;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::statefile;
use centreon::plugins::misc;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                  "warning:s"          => { name => 'warning', },
                                  "critical:s"         => { name => 'critical', },
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
    
    $self->{sql}->query(query => q{SELECT name, value FROM sysprofile
WHERE name IN
( 'ovlock' )
});
    my $new_datas = {ovlock => undef};
    my $result = $self->{sql}->fetchall_arrayref();
    foreach my $row (@{$result}) {
        $new_datas->{centreon::plugins::misc::trim($$row[0])} = $$row[1];
    }
    foreach (keys %$new_datas) {
        if (!defined($new_datas->{$_})) {
            $self->{output}->add_option_msg(short_msg => "Cannot get '$_' variable.");
            $self->{output}->option_exit();
        }
    }

    $self->{statefile_cache}->read(statefile => 'informix_' . $self->{mode} . '_' . $self->{sql}->get_unique_id4save());
    my $old_timestamp = $self->{statefile_cache}->get(name => 'last_timestamp');
    $new_datas->{last_timestamp} = time();

    if (defined($old_timestamp)) {
        my $old_ovlock = $self->{statefile_cache}->get(name => 'ovlock');
        
        $old_ovlock = 0 if ($old_ovlock > $new_datas->{ovlock});     
        my $diff_ovlock = $new_datas->{ovlock} - $old_ovlock;
        
        my $exit_code = $self->{perfdata}->threshold_check(value => $diff_ovlock, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
        $self->{output}->output_add(severity => $exit_code,
                                    short_msg => sprintf("Lock Overflow: %d", $diff_ovlock)
                                    );
        $self->{output}->perfdata_add(label => 'ovlock',
                                      value => $diff_ovlock,
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                      min => 0);
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

Check the number of times Informix attempted to exceed the maximum number of locks.

=over 8

=item B<--warning>

Threshold warning in absolute.

=item B<--critical>

Threshold critical in absolute.

=back

=cut
