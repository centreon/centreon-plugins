#
# Copyright 2017 Centreon (http://www.centreon.com/)
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

package centreon::plugins::statefile;

use strict;
use warnings;
use Data::Dumper;
use vars qw($datas);
use centreon::plugins::misc;

my $default_dir = '/var/lib/centreon/centplugins';

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    if (defined($options{options})) {
        $options{options}->add_options(arguments =>
                                {
                                  "memcached:s"           => { name => 'memcached' },
                                  "statefile-dir:s"       => { name => 'statefile_dir', default => $default_dir },
                                  "statefile-suffix:s"    => { name => 'statefile_suffix', default => '' },
                                  "statefile-concat-cwd"  => { name => 'statefile_concat_cwd' },
                                  "statefile-storable"    => { name => 'statefile_storable' },
                                });
        $options{options}->add_help(package => __PACKAGE__, sections => 'RETENTION OPTIONS', once => 1);
    }
    
    $self->{error} = 0;
    $self->{output} = $options{output};
    $self->{datas} = {};
    $self->{storable} = 0;
    $self->{memcached_ok} = 0;
    $self->{memcached} = undef;
    
    $self->{statefile_dir} = undef;
    $self->{statefile_suffix} = undef;
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;

    if (defined($options{option_results}) && defined($options{option_results}->{memcached})) {
        centreon::plugins::misc::mymodule_load(output => $self->{output}, module => 'Memcached::libmemcached',
                                               error_msg => "Cannot load module 'Memcached::libmemcached'.");
        $self->{memcached} = Memcached::libmemcached->new();
        Memcached::libmemcached::memcached_server_add($self->{memcached}, $options{option_results}->{memcached});
    }
    $self->{statefile_dir} = $options{option_results}->{statefile_dir};
    if ($self->{statefile_dir} ne $default_dir && defined($options{option_results}->{statefile_concat_cwd})) {
        centreon::plugins::misc::mymodule_load(output => $self->{output}, module => 'Cwd',
                                               error_msg => "Cannot load module 'Cwd'.");
        $self->{statefile_dir} = Cwd::cwd() . '/' . $self->{statefile_dir};
    }
    if (defined($options{option_results}->{statefile_storable})) {
        centreon::plugins::misc::mymodule_load(output => $self->{output}, module => 'Storable',
                                               error_msg => "Cannot load module 'Storable'.");
        $self->{storable} = 1;
    }
    $self->{statefile_suffix} = $options{option_results}->{statefile_suffix};
}

sub error {
    my ($self) = shift;
     
    if (@_) {
        $self->{error} = $_[0];
    }
    return $self->{error};
}

sub read {
    my ($self, %options) = @_;
    $self->{statefile_suffix} = defined($options{statefile_suffix}) ? $options{statefile_suffix} : $self->{statefile_suffix};
    $self->{statefile_dir} = defined($options{statefile_dir}) ? $options{statefile_dir} : $self->{statefile_dir};
    $self->{statefile} = defined($options{statefile}) ? $options{statefile} . $self->{statefile_suffix} : 
                            $self->{statefile};
    $self->{no_quit} = defined($options{no_quit}) && $options{no_quit} == 1 ? 1 : 0;

    if (defined($self->{memcached})) {
        # if "SUCCESS" or "NOT FOUND" is ok. Other with use the file
        my $val = Memcached::libmemcached::memcached_get($self->{memcached}, $self->{statefile_dir} . "/" . $self->{statefile});
        if (defined($self->{memcached}->errstr) && $self->{memcached}->errstr =~ /^SUCCESS|NOT FOUND$/i) {
            $self->{memcached_ok} = 1;
            if (defined($val)) {
                eval( $val );
                $self->{datas} = $datas;
                $datas = {};
                return 1;
            }
            return 0;
        }
    }
    
    if (! -e $self->{statefile_dir} . "/" . $self->{statefile}) {
        if (! -w $self->{statefile_dir}) {
            $self->error(1);
            $self->{output}->add_option_msg(short_msg =>  "Cannot write statefile '" . $self->{statefile_dir} . "/" . $self->{statefile} . "'. Need write permissions on directory.");
            if ($self->{no_quit} == 0) {
                $self->{output}->option_exit();
            }
        }
        return 0;
    } elsif (! -w $self->{statefile_dir} . "/" . $self->{statefile}) {
        $self->error(1);
        $self->{output}->add_option_msg(short_msg => "Cannot write statefile '" . $self->{statefile_dir} . "/" . $self->{statefile} . "'. Need write permissions on file.");
        if ($self->{no_quit} == 0) {
            $self->{output}->option_exit();
        }
        return 1;
    } elsif (! -s $self->{statefile_dir} . "/" . $self->{statefile}) {
        # Empty file. Not a problem. Maybe plugin not manage not values
        return 0;
    }
    
    if ($self->{storable} == 1) {
        open FILE, $self->{statefile_dir} . "/" . $self->{statefile};
        eval {
            $self->{datas} = Storable::fd_retrieve(*FILE);
        };
        # File is corrupted surely. We'll reset it
        if ($@) {
            close FILE;
            return 0;
        }
        close FILE;
    } else {
        unless (my $return = do $self->{statefile_dir} . "/" . $self->{statefile}) {
            # File is corrupted surely. We'll reset it
            return 0;
            #if ($@) {
            #    $self->{output}->add_option_msg(short_msg => "Couldn't parse '" . $self->{statefile_dir} . "/" . $self->{statefile} . "': $@");
            #    $self->{output}->option_exit();
            #}
            #unless (defined($return)) {
            #    $self->{output}->add_option_msg(short_msg => "Couldn't do '" . $self->{statefile_dir} . "/" . $self->{statefile} . "': $!");
            #    $self->{output}->option_exit();
            #}
            #unless ($return) {
            #    $self->{output}->add_option_msg(short_msg => "Couldn't run '" . $self->{statefile_dir} . "/" . $self->{statefile} . "': $!");
            #    $self->{output}->option_exit();
        }
        $self->{datas} = $datas;
        $datas = {};
    }

    return 1;
}

sub get_string_content {
    my ($self, %options) = @_;

    return Data::Dumper::Dumper($self->{datas});
}

sub get {
    my ($self, %options) = @_;

    if (defined($self->{datas}->{$options{name}})) {
        return $self->{datas}->{$options{name}};
    }
    return undef;
}

sub write {
    my ($self, %options) = @_;

    if ($self->{memcached_ok} == 1) {
        Memcached::libmemcached::memcached_set($self->{memcached}, $self->{statefile_dir} . "/" . $self->{statefile}, 
                                               Data::Dumper->Dump([$options{data}], ["datas"]));
        if (defined($self->{memcached}->errstr) && $self->{memcached}->errstr =~ /^SUCCESS$/i) {
            return ;
        }
    }
    open FILE, ">", $self->{statefile_dir} . "/" . $self->{statefile};
    if ($self->{storable} == 1) {
        Storable::store_fd($options{data}, *FILE);
    } else {
        print FILE Data::Dumper->Dump([$options{data}], ["datas"]);
    }
    close FILE;
}

1;

__END__

=head1 NAME

Statefile class

=head1 SYNOPSIS

-

=head1 RETENTION OPTIONS

=over 8

=item B<--memcached>

Memcached server to use (only one server).

=item B<--statefile-dir>

Directory for statefile (Default: '/var/lib/centreon/centplugins').

=item B<--statefile-suffix>

Add a suffix for the statefile name (Default: '').

=item B<--statefile-concat-cwd>

Concat current working directory with option '--statefile-dir'.
Useful on Windows when plugin is compiled.

=item B<--statefile-storable>

Use Perl Module 'Storable' (instead Data::Dumper) to store datas.

=back

=head1 DESCRIPTION

B<statefile>.

=cut
