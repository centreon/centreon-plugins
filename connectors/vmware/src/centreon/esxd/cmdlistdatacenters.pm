
package centreon::esxd::cmdlistdatacenters;

use strict;
use warnings;
use centreon::esxd::common;

sub new {
    my $class = shift;
    my $self  = {};
    $self->{logger} = shift;
    $self->{commandName} = 'listdatacenters';
    
    bless $self, $class;
    return $self;
}

sub getCommandName {
    my $self = shift;
    return $self->{commandName};
}

sub checkArgs {
    my ($self, %options) = @_;

    if (defined($options{arguments}->{datacenter}) && $options{arguments}->{datacenter} eq "") {
        $options{manager}->{output}->output_add(severity => 'UNKNOWN',
                                                short_msg => "Argument error: datacenter cannot be null");
        return 1;
    }
    return 0;
}

sub initArgs {
     my ($self, %options) = @_;
    
    foreach (keys %{$options{arguments}}) {
        $self->{$_} = $options{arguments}->{$_};
    }
    $self->{manager} = centreon::esxd::common::init_response();
    $self->{manager}->{output}->{plugin} = $options{arguments}->{identity};
}

sub set_connector {
    my ($self, %options) = @_;
    
    $self->{connector} = $options{connector};
}

sub run {
    my $self = shift;

    my %filters = ();
    my $multiple = 0;

    if (defined($self->{datacenter}) && !defined($self->{filter})) {
        $filters{name} = qr/^\Q$self->{datacenter}\E$/;
    } elsif (!defined($self->{datacenter})) {
        $filters{name} = qr/.*/;
    } else {
        $filters{name} = qr/$self->{datacenter}/;
    }
    my @properties = ('name');

    my $result = centreon::esxd::common::search_entities(command => $self, view_type => 'Datacenter', properties => \@properties, filter => \%filters);
    return if (!defined($result));

    if (!defined($self->{disco_show})) {
        $self->{manager}->{output}->output_add(severity => 'OK',
                                               short_msg => 'List datacenter(s):');
    }
    foreach my $datacenter (@$result) {
        if (defined($self->{disco_show})) {
            $self->{manager}->{output}->add_disco_entry(name => $datacenter->name);
        } else {
            $self->{manager}->{output}->output_add(long_msg => sprintf("  %s", 
                                                                        $datacenter->name));
        }
    }
    
    if (defined($self->{disco_show})) {
        my $stdout;
        {
            local *STDOUT;
            $self->{manager}->{output}->{option_results}->{output_xml} = 1;
            open STDOUT, '>', \$stdout;
            $self->{manager}->{output}->display_disco_show();
            delete $self->{manager}->{output}->{option_results}->{output_xml};
            $self->{manager}->{output}->output_add(severity => 'OK',
                                                   short_msg => $stdout);
        }
    }
}

1;
