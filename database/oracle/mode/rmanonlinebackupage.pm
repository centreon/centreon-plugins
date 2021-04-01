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

package database::oracle::mode::rmanonlinebackupage;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use DateTime;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        "warning:s"               => { name => 'warning', },
        "critical:s"              => { name => 'critical', },
        "timezone:s"              => { name => 'timezone', },
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
    
    if (defined($self->{option_results}->{timezone}) && $self->{option_results}->{timezone} ne '') {
        $ENV{TZ} = $self->{option_results}->{timezone};
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{sql} = sqlmode object
    $self->{sql} = $options{sql};

    $self->{sql}->connect();
    my $query = q{SELECT min(((time - date '1970-01-01') * 86400)) as last_time
                  FROM v$backup
                  WHERE STATUS='ACTIVE'
    };
    $self->{sql}->query(query => $query);
    my $result = $self->{sql}->fetchall_arrayref();
    $self->{sql}->disconnect();

    $self->{output}->output_add(severity => 'OK',
                                short_msg => sprintf("Backup online modes are ok."));

    foreach my $row (@$result) {
        next if (!defined($$row[0]));
        my $last_time = $$row[0];
        
        my @values = localtime($last_time);
        my $dt = DateTime->new(
                        year       => $values[5] + 1900,
                        month      => $values[4] + 1,
                        day        => $values[3],
                        hour       => $values[2],
                        minute     => $values[1],
                        second     => $values[0],
                        time_zone  => 'UTC',
        );
        my $offset = $last_time - $dt->epoch;
        $last_time = $last_time + $offset;
        
        my $launched = time() - $last_time;
        my $launched_convert = centreon::plugins::misc::change_seconds(value => $launched);
        $self->{output}->output_add(long_msg => sprintf("backup online mode since %s (%s)", $launched_convert, locatime($last_time)));
        my $exit_code = $self->{perfdata}->threshold_check(value => $launched, threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
        if (!$self->{output}->is_status(value => $exit_code, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit_code,
                                        short_msg => sprintf("backup online mode since %s (%s)", $launched_convert, locatime($last_time)));
        }
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Oracle backup online mode.

=over 8

=item B<--warning>

Threshold warning in seconds.

=item B<--critical>

Threshold critical in seconds.

=item B<--timezone>

Timezone of oracle server (If not set, we use current server execution timezone)

=back

=cut
