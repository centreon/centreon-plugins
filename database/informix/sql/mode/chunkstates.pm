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

package database::informix::sql::mode::chunkstates;

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
                                  "warning:s"             => { name => 'warning', },
                                  "critical:s"            => { name => 'critical', },
                                  "chunk-state:s"         => { name => 'chunk_state', },
                                  "name:s"                => { name => 'name', },
                                  "regexp"                => { name => 'use_regexp' },
                                  "global-ok-msg:s"       => { name => 'global_ok_msg', default => 'All chunks are ok' },
                                  "ok-msg:s"              => { name => 'ok_msg', default => 'Chunk %s is ok' },
                                  "error-msg:s"           => { name => 'error_msg', default => 'Chunk %s has a problem' },
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
    if (!defined($self->{option_results}->{chunk_state})) {
       $self->{output}->add_option_msg(short_msg => "Need to specify a chunk-state argument.");
       $self->{output}->option_exit();
    }
    if ($self->{option_results}->{chunk_state} !~ /^(is_offline|is_recovering|is_blobchunk|is_inconsistent)$/ ) {
       $self->{output}->add_option_msg(short_msg => "Need to specify a valid chunk-state argument.");
       $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{sql} = sqlmode object
    $self->{sql} = $options{sql};

    $self->{sql}->connect();

    my $query = "
SELECT name, chknum, $self->{option_results}->{chunk_state} FROM sysdbspaces, syschunks WHERE sysdbspaces.dbsnum = syschunks.dbsnum
";
    
    $self->{sql}->query(query => $query);

    if (!defined($self->{option_results}->{name}) || defined($self->{option_results}->{use_regexp})) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => $self->{option_results}->{global_ok_msg});
    }
    
    my $count = 0;
    while ((my $row = $self->{sql}->fetchrow_hashref())) {
        my $name = centreon::plugins::misc::trim($row->{name});
        next if (defined($self->{option_results}->{name}) && !defined($self->{option_results}->{use_regexp}) && $name ne $self->{option_results}->{name});
        next if (defined($self->{option_results}->{name}) && defined($self->{option_results}->{use_regexp}) && $name !~ /$self->{option_results}->{name}/);
        
        $count++;
        $self->{output}->output_add(long_msg => sprintf("Chunk %s state '%s' is %s",
                                                         $name . " " . $row->{chknum}, $self->{option_results}->{chunk_state}, $row->{$self->{option_results}->{chunk_state}}));
        my $exit_code = $self->{perfdata}->threshold_check(value => $row->{$self->{option_results}->{chunk_state}}, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
        
        if (!$self->{output}->is_status(value => $exit_code, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit_code,
                                        short_msg => sprintf($self->{option_results}->{error_msg},
                                                             $name . " " . $row->{chknum}));
        } elsif (defined($self->{option_results}->{name}) && !defined($self->{option_results}->{use_regexp})) {
            $self->{output}->output_add(severity => $exit_code,
                                        short_msg => sprintf($self->{option_results}->{ok_msg},
                                                             $name . " " . $row->{chknum}));
        }
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

Check state (is_offline, is_recovering, is_blobchunk, is_inconsistent) chunks.
Options example:
xxxx --chunk-state="is_offline" --warning="@1:1" --error-msg="Chunk %s is down"

=over 8

=item B<--warning>

Threshold warning (can check 1 or 0).

=item B<--critical>

Threshold critical (can check 1 or 0).

=item B<--chunk-state>

State to check (Can be: is_offline, is_recovering, is_blobchunk, is_inconsistent).

=item B<--error-msg>

Display message when you have an error. (Default: 'Chunk %s has a problem')

=item B<--ok-msg>

Display message when chunk is ok. (Default: 'Chunk %s is ok')

=item B<--global-ok-msg>

Display global message when you have no errors. (Default: 'All chunks are ok')

=item B<--name>

Set the dbspace (empty means 'check all dbspaces').

=item B<--regexp>

Allows to use regexp to filter dbspaces (with option --name).

=back

=cut
