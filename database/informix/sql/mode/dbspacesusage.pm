#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package database::informix::sql::mode::dbspacesusage;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                  "warning:s"               => { name => 'warning', },
                                  "critical:s"              => { name => 'critical', },
                                  "name:s"                  => { name => 'name', },
                                  "regexp"                  => { name => 'use_regexp' },
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

    my $query = q{
SELECT  name dbspace,              
        sum(chksize) pages_size,    -- sum of all chunks size pages
        sum(nfree) pages_free       -- sum of all chunks free pages
FROM    sysdbspaces d, syschunks c
WHERE   d.dbsnum = c.dbsnum
GROUP BY d.name
ORDER BY d.name
};
    
    $self->{sql}->query(query => $query);

    if (!defined($self->{option_results}->{name}) || defined($self->{option_results}->{use_regexp})) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'All dbspaces usage are ok');
    }
    
    my $count = 0;
    while ((my $row = $self->{sql}->fetchrow_hashref())) {
        my $name = centreon::plugins::misc::trim($row->{dbspace});
        next if (defined($self->{option_results}->{name}) && !defined($self->{option_results}->{use_regexp}) && $name ne $self->{option_results}->{name});
        next if (defined($self->{option_results}->{name}) && defined($self->{option_results}->{use_regexp}) && $name !~ /$self->{option_results}->{name}/);

        my $prct_used;
        if ($row->{pages_free} == 0) {
            $prct_used = 100;
        } else {
            $prct_used = ($row->{pages_size} - $row->{pages_free}) * 100 / $row->{pages_size};
        }
        
        $count++;
        $self->{output}->output_add(long_msg => sprintf("Dbspace '%s': Used: %.2f%% Free: %.2f%%",
                                                         $name, $prct_used, 100 - $prct_used));
        my $exit_code = $self->{perfdata}->threshold_check(value => $prct_used, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
        
        if (!$self->{output}->is_status(value => $exit_code, compare => 'ok', litteral => 1) || 
            (defined($self->{option_results}->{name}) && !defined($self->{option_results}->{use_regexp}))) {
            $self->{output}->output_add(severity => $exit_code,
                                        short_msg => sprintf("Dbspace '%s': Used: %.2f%% Free: %.2f%%",
                                                             $name, $prct_used, 100 - $prct_used));
        }
        
        my $extra_label = '';
        $extra_label = '_' . $name if (!defined($self->{option_results}->{name}) || defined($self->{option_results}->{use_regexp}));
        $self->{output}->perfdata_add(label => 'used' . $extra_label, unit => '%',
                                      value => sprintf("%.2f", $prct_used),
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                      min => 0, max => 100);
    }

    if ($count == 0) {
        $self->{output}->output_add(severity => 'UNKNOWN',
                                    short_msg => "Cannot find a dbspace (maybe the filter).");
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check usage for one or more dbspaces.

=over 8

=item B<--warning>

Threshold warning in percent.

=item B<--critical>

Threshold critical in percent.

=item B<--name>

Set the dbspace (empty means 'check all dbspaces').

=item B<--regexp>

Allows to use regexp to filter dbspaces (with option --name).

=back

=cut
