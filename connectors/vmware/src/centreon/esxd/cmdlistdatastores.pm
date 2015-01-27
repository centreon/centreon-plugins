
package centreon::esxd::cmdlistdatastores;

use strict;
use warnings;
use centreon::esxd::common;

sub new {
    my $class = shift;
    my $self  = {};
    $self->{logger} = shift;
    $self->{commandName} = 'listdatastores';
    
    bless $self, $class;
    return $self;
}

sub getCommandName {
    my $self = shift;
    return $self->{commandName};
}

sub checkArgs {
    my ($self, %options) = @_;

    if (defined($options{arguments}->{esx_hostname}) && $options{arguments}->{esx_hostname} eq "") {
        $options{manager}->{output}->output_add(severity => 'UNKNOWN',
                                                short_msg => "Argument error: esx hostname cannot be null");
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
    
    $self->{obj_esxd} = $options{connector};
}

sub run {
    my $self = shift;

    my %filters = ();
    my $multiple = 0;

    if (defined($self->{datastore_name}) && !defined($self->{filter})) {
        $filters{name} = qr/^\Q$self->{datastore_name}\E$/;
    } elsif (!defined($self->{datastore_name})) {
        $filters{name} = qr/.*/;
    } else {
        $filters{name} = qr/$self->{datastore_name}/;
    }
    my @properties = ('summary');

    my $result = centreon::esxd::common::get_entities_host($self->{obj_esxd}, 'Datastore', \%filters, \@properties);
    return if (!defined($result));

    if (!defined($self->{disco_show})) {
        $self->{manager}->{output}->output_add(severity => 'OK',
                                               short_msg => 'List datastore(s):');
    }
    foreach my $datastore (@$result) {
        if (defined($self->{disco_show})) {
            $self->{manager}->{output}->add_disco_entry(name => $datastore->summary->name,
                                                        accessible => $datastore->summary->accessible,
                                                        type => $datastore->summary->type);
        } else {
            $self->{manager}->{output}->output_add(long_msg => sprintf("  %s [%s] [%s]", 
                                                                        $datastore->summary->name, 
                                                                        $datastore->summary->accessible,
                                                                        $datastore->summary->type));
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
