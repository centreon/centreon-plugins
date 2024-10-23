# Copyright 2024 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets 
# the needs in IT infrastructure and application monitoring for 
# service performance.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0  
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

package centreon::vmware::script;

use strict;
use warnings;
use FindBin;
use Getopt::Long;
use Pod::Usage;
use centreon::vmware::logger;

$SIG{__DIE__} = sub {
    return unless defined $^S and $^S == 0; # Ignore errors in eval
    my $error = shift;
    print "Error: $error";
    exit 1;
};

sub new {
    my ($class, $name, %options) = @_;
    my %defaults = 
      (
       log_file => undef,
       severity => "info",
       noroot => 0,
      );
    my $self = {%defaults, %options};

    bless $self, $class;
    $self->{name} = $name;
    $self->{logger} = centreon::vmware::logger->new();
    $self->{options} = {
        "logfile=s"  => \$self->{log_file},
        "severity=s" => \$self->{severity},
        "help|?"     => \$self->{help}
    };
    return $self;
}

sub init {
    my $self = shift;

    if (defined $self->{log_file}) {
        $self->{logger}->file_mode($self->{log_file});
    }
    $self->{logger}->severity($self->{severity});

    if ($self->{noroot} == 1) {
        # Stop exec if root
        if ($< == 0) {
            $self->{logger}->writeLogError("Can't execute script as root.");
            die("Quit");
        }
    }
}

sub add_options {
    my ($self, %options) = @_;

    $self->{options} = {%{$self->{options}}, %options};
}

sub parse_options {
    my $self = shift;

    Getopt::Long::Configure('bundling');
    die "Command line error" if !GetOptions(%{$self->{options}});
    pod2usage(-exitval => 1, -input => $FindBin::Bin . "/" . $FindBin::Script) if $self->{help};
}

sub run {
    my $self = shift;

    $self->parse_options();
    $self->init();
}

1;
