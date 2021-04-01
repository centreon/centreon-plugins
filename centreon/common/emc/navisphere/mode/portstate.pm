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

package centreon::common::emc::navisphere::mode::portstate;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                  "filter-name:s"     => { name => 'filter_name' },
                                  "filter-id:s"       => { name => 'filter_id' },
                                });
    $self->{total_port} = 0;
    $self->{total_port_noskip} = 0;
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub check_port {
    my ($self, %options) = @_;
    
    if ($self->{response} =~ /Information about each SPPORT:(.*)/msi) {
        my $port_infos = $1;
        
        while ($port_infos =~ /(SP Name:.*?)(\n\n|\Z)/msig) {
            my $port_infos = $1;
            
            # Not in good section
            next if ($port_infos !~ /Switch Present:/mi);
            $port_infos =~ /SP Name:\s*(.*?)\s*$/mi;
            my $port_name = $1;
            $port_infos =~ /SP Port ID:\s*(.*?)\s*$/mi;
            my $port_id = $1;
            $port_infos =~ /Link Status:\s*(.*?)\s*$/mi;
            my $link_status = $1;
            $port_infos =~ /Port Status:\s*(.*?)\s*$/mi;
            my $port_status = $1;
            
            $self->{total_port}++;
            if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' && $port_name !~ /$self->{option_results}->{filter_name}/) {
                $self->{output}->output_add(long_msg => "Skipping SP $port_name port $port_id [link status: $link_status] [port status: $port_status]");
                next;
            }
            if (defined($self->{option_results}->{filter_id}) && $self->{option_results}->{filter_id} ne '' && $port_id !~ /$self->{option_results}->{filter_id}/) {
                $self->{output}->output_add(long_msg => "Skipping SP $port_name port $port_id [link status: $link_status] [port status: $port_status]");
                next;
            }
            $self->{total_port_noskip}++;
            
            $self->{output}->output_add(long_msg => "Checking SP $port_name port $port_id [link status: $link_status] [port status: $port_status]");
            my ($error, $error_append) = ('', ''); 
            if ($port_status !~ /Online|Enabled/i) {
                $error = "port status is '" . $port_status . "'";
                $error_append = ', ';
            }
            if ($link_status !~ /Up/i) {
                $error .= $error_append . "link status is '" . $link_status . "'";
            }
            if ($error ne '') {
                $self->{output}->output_add(severity => 'CRITICAL',
                                            short_msg => sprintf("SP %s port %s: %s.", 
                                                                 $port_name, $port_id, $error)
                                            );
            }
        }
    }
}

sub run {
    my ($self, %options) = @_;
    my $clariion = $options{custom};
    
    $self->{response} = $clariion->execute_command(cmd => 'getall -hba');
    chomp $self->{response};

    $self->check_port();
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => sprintf("All ports (%s/%s) are ok.", 
                                                     $self->{total_port_noskip}, $self->{total_port})
                                );

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check SP port states.

=over 8

=item B<--filter-name>

Set SP Name to check (not set, means 'all').

=item B<--filter-id>

Set SP port ID to check (not set, means 'all').

=back

=cut