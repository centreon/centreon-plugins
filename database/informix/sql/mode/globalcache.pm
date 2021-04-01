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

package database::informix::sql::mode::globalcache;

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
                                  "warning-read:s"          => { name => 'warning_read', },
                                  "critical-read:s"         => { name => 'critical_read', },
                                  "warning-write:s"         => { name => 'warning_write', },
                                  "critical-write:s"        => { name => 'critical_write', },
                                  "lookback"                => { name => 'lookback', },
                                });
    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning_read', value => $self->{option_results}->{warning_read})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning-read threshold '" . $self->{option_results}->{warning_read} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical_read', value => $self->{option_results}->{critical_read})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical-read threshold '" . $self->{option_results}->{critical_read} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warning_write', value => $self->{option_results}->{warning_write})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning-read threshold '" . $self->{option_results}->{warning_write} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical_write', value => $self->{option_results}->{critical_write})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical-write threshold '" . $self->{option_results}->{critical_write} . "'.");
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
( 'dskreads', 'bufreads', 'bufwrites', 'dskwrites' )
});
    my $new_datas = {dskreads => undef, bufreads => undef, bufwrites => undef, dskwrites => undef};
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
        my $old_dskreads = $self->{statefile_cache}->get(name => 'dskreads');
        my $old_bufreads = $self->{statefile_cache}->get(name => 'bufreads');
        my $old_bufwrites = $self->{statefile_cache}->get(name => 'bufwrites');
        my $old_dskwrites = $self->{statefile_cache}->get(name => 'dskwrites');
        
        $old_dskreads = 0 if ($old_dskreads > $new_datas->{dskreads});
        $old_bufreads = 0 if ($old_bufreads > $new_datas->{bufreads});
        $old_bufwrites = 0 if ($old_bufwrites > $new_datas->{bufwrites});
        $old_dskwrites = 0 if ($old_dskwrites > $new_datas->{dskwrites});
        
        my $diff_bufreads = $new_datas->{bufreads} - $old_bufreads;
        my $diff_dskreads = $new_datas->{dskreads} - $old_dskreads;
        my $diff_bufwrites = $new_datas->{bufwrites} - $old_bufwrites;
        my $diff_dskwrites = $new_datas->{dskwrites} - $old_dskwrites;

        # 100 * (bufreads - dskreads) / bufreads
        # 100 * (bufwrits - dskwrits) / bufwrits
        my %prcts = ();
        $prcts{readcached_now} = ($diff_bufreads == 0) ? 0 : 100 * ($diff_bufreads - $diff_dskreads) / $diff_bufreads;
        $prcts{readcached} = ($new_datas->{bufreads} == 0) ? 0 : 100 * ($new_datas->{bufreads} - $new_datas->{dskreads}) / $new_datas->{bufreads};
        $prcts{readcached_now} = 0 if ($prcts{readcached_now} < 0);
        $prcts{readcached} = 0 if ($prcts{readcached} < 0);
        
        $prcts{writecached_now} = ($diff_bufwrites == 0) ? 0 : 100 * ($diff_bufwrites - $diff_dskwrites) / $diff_bufwrites;
        $prcts{writecached} = ($new_datas->{bufwrites} == 0) ? 0 : 100 * ($new_datas->{bufwrites} - $new_datas->{dskwrites}) / $new_datas->{bufwrites};
        $prcts{writecached_now} = 0 if ($prcts{writecached_now} < 0);
        $prcts{writecached} = 0 if ($prcts{writecached} < 0);
        
        my $exit_code = $self->{perfdata}->threshold_check(value => $prcts{'readcached' . ((defined($self->{option_results}->{lookback})) ? '' : '_now' )}, threshold => [ { label => 'critical_read', 'exit_litteral' => 'critical' }, { label => 'warning_read', exit_litteral => 'warning' } ]);
        $self->{output}->output_add(severity => $exit_code,
                                    short_msg => sprintf("Read Cached hitrate at %.2f%%", $prcts{'readcached' . ((defined($self->{option_results}->{lookback})) ? '' : '_now')})
                                    );
        $self->{output}->perfdata_add(label => 'readcached' . ((defined($self->{option_results}->{lookback})) ? '' : '_now'), unit => '%',
                                      value => sprintf("%.2f", $prcts{'readcached' . ((defined($self->{option_results}->{lookback})) ? '' : '_now')}),
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning_read'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical_read'),
                                      min => 0, max => 100);
        $self->{output}->perfdata_add(label => 'readcached' . ((defined($self->{option_results}->{lookback})) ? '_now' : ''), unit => '%',
                                      value => sprintf("%.2f", $prcts{'readcached' . ((defined($self->{option_results}->{lookback})) ? '_now' : '')}),
                                      min => 0, max => 100);
        
        $exit_code = $self->{perfdata}->threshold_check(value => $prcts{'writecached' . ((defined($self->{option_results}->{lookback})) ? '' : '_now' )}, threshold => [ { label => 'critical_write', 'exit_litteral' => 'critical' }, { label => 'warning_write', exit_litteral => 'warning' } ]);
        $self->{output}->output_add(severity => $exit_code,
                                    short_msg => sprintf("Write Cached hitrate at %.2f%%", $prcts{'writecached' . ((defined($self->{option_results}->{lookback})) ? '' : '_now')})
                                    );
        $self->{output}->perfdata_add(label => 'writecached' . ((defined($self->{option_results}->{lookback})) ? '' : '_now'), unit => '%',
                                      value => sprintf("%.2f", $prcts{'writecached' . ((defined($self->{option_results}->{lookback})) ? '' : '_now')}),
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning_write'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical_write'),
                                      min => 0, max => 100);
        $self->{output}->perfdata_add(label => 'writecached' . ((defined($self->{option_results}->{lookback})) ? '_now' : ''), unit => '%',
                                      value => sprintf("%.2f", $prcts{'writecached' . ((defined($self->{option_results}->{lookback})) ? '_now' : '')}),
                                      min => 0, max => 100);
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

Check write/read cached.

=over 8

=item B<--warning-read>

Threshold read cached warning in percent.

=item B<--critical-read>

Threshold read cached critical in percent.

=item B<--warning-write>

Threshold write cached warning in percent.

=item B<--critical-write>

Threshold write cached critical in percent.

=item B<--lookback>

Threshold isn't on the percent calculated from the difference ('xxxcached_now').

=back

=cut
