package cloud::aws::elasticache::mode::discovery;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use JSON::XS;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "prettify"  => { name => 'prettify' },
    });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub run {
    my ($self, %options) = @_;
    my @disco_data;
    my $disco_stats;

    $disco_stats->{start_time} = time();
   
    my $instances = $options{custom}->discovery(
        service => 'elasticache',
        command => 'describe-cache-clusters'
    );

    foreach my $ecc_instance (@{$instances->{CacheClusters}}) {
        next if (!defined($ecc_instance->{CacheClusterId}));
            my %ecc;
            $ecc{type}= "elasticache";
            $ecc{id} = $ecc_instance->{CacheClusterId};
            $ecc{engine} = $ecc_instance->{Engine};
            $ecc{engine_version} = $ecc_instance->{EngineVersion};
            $ecc{replication_group_log_delivery_enabled} = $ecc_instance->{ReplicationGroupLogDeliveryEnabled};
           
        foreach my $secureGroups (@{$ecc_instance->{SecurityGroups}}) {
            push @{$ecc{security_groups}}, { status => $secureGroups->{Status}, security_group_id => $secureGroups->{SecurityGroupId} };
        }
        push @disco_data, \%ecc;       
    }

    $disco_stats->{end_time} = time();
    $disco_stats->{duration} = $disco_stats->{end_time} - $disco_stats->{start_time};
    $disco_stats->{discovered_items} = @disco_data;
    $disco_stats->{results} = \@disco_data;
    
    my $encoded_data;
    eval {
        if (defined($self->{option_results}->{prettify})) {
            $encoded_data = JSON::XS->new->utf8->pretty->encode($disco_stats);
        } else {
            $encoded_data = JSON::XS->new->utf8->encode($disco_stats);
        }
    };
    
    if ($@) {
        $encoded_data = '{"code":"encode_error","message":"Cannot encode discovered data into JSON format"}';
    }

    return @disco_data if (defined($options{discover}));

    $self->{output}->output_add(short_msg => $encoded_data);
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1);
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

ELASTICACHE discovery.

=over 8

=item A<--prettify>

Prettify JSON output.

=back

=cut

