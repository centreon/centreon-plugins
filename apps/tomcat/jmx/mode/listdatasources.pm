#
# Copyright 2018 Centreon (http://www.centreon.com/)
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

package apps::tomcat::jmx::mode::listdatasources;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "filter-host:s"   => { name => 'filter_host' },
                                  "filter-path:s"   => { name => 'filter_path' },
                                });
    $self->{ds} = {};
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{request} = [
         { mbean => "*:type=DataSource,class=*,context=*,host=*,name=*", attributes => 
             [ { name => 'numActive' } ] },
    ];
    my $result = $options{custom}->get_attributes(request => $self->{request});

    foreach my $mbean (keys %{$result}) {
        $mbean =~ /(?:[:,])host=(.*?)(?:,|$)/;
        my $host = $1;
        $mbean =~ /(?:[:,])(?:path|context)=(.*?)(?:,|$)/;
        my $path = $1;
        $mbean =~ /(?:[:,])name=(.*?)(?:,|$)/;
        my $name = $1;
        $name =~ s/^"(.*)"$/$1/;
        
        if (defined($self->{option_results}->{filter_host}) && $self->{option_results}->{filter_host} ne '' &&
            $host !~ /$self->{option_results}->{filter_host}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $host . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_path}) && $self->{option_results}->{filter_path} ne '' &&
            $path !~ /$self->{option_results}->{filter_path}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $path . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{ds}->{$host . '.' . $path} = { 
            host => $host, path => $path, name => $name,
        };
    }
}

sub run {
    my ($self, %options) = @_;
  
    $self->manage_selection(%options);
    foreach my $instance (sort keys %{$self->{ds}}) { 
        $self->{output}->output_add(long_msg => '[host = ' . $self->{ds}->{$instance}->{host} . "]" .
            " [path = '" . $self->{ds}->{$instance}->{path} . "']" .
            " [name = '" . $self->{ds}->{$instance}->{name} . "']"
        );
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List data sources:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['host', 'path', 'name']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $instance (sort keys %{$self->{ds}}) {             
        $self->{output}->add_disco_entry(
            %{$self->{ds}->{$instance}}
        );
    }
}

1;

__END__

=head1 MODE

List data sources.

=over 8

=item B<--filter-host>

Filter by virtual host name (can be a regexp).

=item B<--filter-path>

Filter by application name (can be a regexp).

=back

=cut
    
