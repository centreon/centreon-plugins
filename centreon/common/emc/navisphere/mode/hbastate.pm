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

package centreon::common::emc::navisphere::mode::hbastate;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                  "filter-server:s"     => { name => 'filter_server' },
                                  "filter-uid:s"        => { name => 'filter_uid' },
                                  "path-status:s@"      => { name => 'path_status' },
                                });
    $self->{total_hba} = 0;
    $self->{total_hba_noskip} = 0;
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{path_status}) || scalar(@{$self->{option_results}->{path_status}}) == 0) {
       $self->{output}->add_option_msg(short_msg => "Need to set --path-status option.");
       $self->{output}->option_exit();
    }
    my $i = 0;
    foreach (@{$self->{option_results}->{path_status}}) {
        my ($warning, $critical, $filter_uid, $filter_server) = split /,/;
        
        if (!defined($filter_uid) && !defined($filter_server)) {
            $self->{output}->add_option_msg(short_msg => "Need to set a filter in --path-status '" . $_ . "' option.");
            $self->{output}->option_exit();
        }
        if (($self->{perfdata}->threshold_validate(label => 'warning-' . $i, value => $warning)) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $warning . "'.");
            $self->{output}->option_exit();
        }
        if (($self->{perfdata}->threshold_validate(label => 'critical-' . $i, value => $critical)) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $critical . "'.");
            $self->{output}->option_exit();
        }
        $i++;
    }
}

sub check_hba {
    my ($self, %options) = @_;
    
    my @result = split /Information about each HBA/i, $self->{response};
    foreach (@result) {
        my $hba_infos = $_;
        
        # Not in hba section. we move.
        next if ($hba_infos !~ /^HBA UID:\s*(\S*)/mi);
        my $hba_uid = $1;
        $hba_infos =~ /^Server Name:\s*(.*?)\s*$/mi;
        my $server_name = $1;
        
        $self->{total_hba}++;
        if (defined($self->{option_results}->{filter_server}) && $self->{option_results}->{filter_server} ne '' && $server_name !~ /$self->{option_results}->{filter_server}/) {
            $self->{output}->output_add(long_msg => "Skipping hba '$hba_uid' server '$server_name'");
            next;
        }
        if (defined($self->{option_results}->{filter_uid}) && $self->{option_results}->{filter_uid} ne '' && $hba_uid !~ /$self->{option_results}->{filter_uid}/) {
            $self->{output}->output_add(long_msg => "Skipping hba '$hba_uid' server '$server_name'");
            next;
        }
        $self->{total_hba_noskip}++;
        
        $self->{output}->output_add(long_msg => "Checking hba '$hba_uid' server '$server_name'");
        
        my $not_logged = 0;
        my $logged = 0;
        while ($hba_infos =~ /(SP Name:.*?)(\n\n|\Z)/msig) {
            my $port_infos = $1;
            
            # Not in good section
            next if ($port_infos !~ /HBA Devicename:/mi);
            $port_infos =~ /SP Name:\s*(.*?)\s*$/mi;
            my $port_name = $1;
            $port_infos =~ /SP Port ID:\s*(.*?)\s*$/mi;
            my $port_id = $1;
            $port_infos =~ /Logged In:\s*(.*?)\s*$/mi;
            my $logged_in = $1;
            if ($logged_in !~ /YES/i) {
                $not_logged++;
            } else {
                $logged++;
            }
            $self->{output}->output_add(long_msg => "  port [sp name: $port_name] [sp port id: $port_id] logged is $logged_in");
        }
        
        # Do the checking
        my $i = -1;
        foreach (@{$self->{option_results}->{path_status}}) {
            my ($warning, $critical, $filter_uid, $filter_server) = split /,/;
            $i++;
        
            next if (defined($filter_uid) && $filter_uid ne '' && $hba_uid !~ /$filter_uid/);
            next if (defined($filter_server) && $filter_server ne '' && $server_name !~ /$filter_server/);
        
        
            my $exit = $self->{perfdata}->threshold_check(value => $logged,
                                                          threshold => [ { label => 'critical-' . $i, 'exit_litteral' => 'critical' }, { label => 'warning-' . $i, exit_litteral => 'warning' } ]);
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                 $self->{output}->output_add(severity => $exit,
                                             short_msg => "Path connection problem for hba '$hba_uid' server '$server_name'");
            }
        
            last;
        }
    }
}

sub run {
    my ($self, %options) = @_;
    my $clariion = $options{custom};
    
    $self->{response} = $clariion->execute_command(cmd => 'getall -hba');
    chomp $self->{response};

    $self->check_hba();
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => sprintf("All hba states (%s/%s) are ok.", 
                                                     $self->{total_hba_noskip}, $self->{total_hba})
                                );

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check connection state of servers.

=over 8

=item B<--filter-server>

Set server to check (not set, means 'all').

=item B<--filter-uid>

Set hba uid to check (not set, means 'all').

=item B<--path-status>

Set how much path must be connected (Can be multiple).
Syntax: [WARNING],[CRITICAL],filter_uid,filter_server
Example: ,@0:1,.*,.* - Means all server must have at least two paths connected.

=back

=cut