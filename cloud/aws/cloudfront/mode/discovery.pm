package cloud::aws::cloudfront::mode::discovery;

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
        service => 'cloudfront',
        command => 'list-distributions'
    );

    foreach my $cft_instance (@{$instances->{DistributionList}->{Items}}) {   
        next if (!defined($cft_instance->{Id}));
            my %cft;    
            
              # $cft{type}= "cloudfront";
            $cft{id} = $cft_instance->{Id};
            $cft{status} = $cft_instance->{Status};
            $cft{domain_name} = $cft_instance->{DomainName};
            $cft{aliases} = $cft_instance->{Aliases}->{Items};
        #  foreach my $aliases (@{$cft_instance->{Items}}) {

        #     push @{$cft{security_groups}}, { status => $aliases->{Status}, security_group_id => $aliases->{SecurityGroupId} };
        # }
        push @disco_data, \%cft;       
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

=over 8

=item B<--id>

Set the instance id (Required) (Can be multiple).

=item B<--filter-metric>

Filter metrics (Can be: 'TotalErrorRate', '4xxErrorRate', '5xxErrorRate') 
(Can be a regexp).

=item B<--warning-*>

Thresholds warning (Can be: 'errorrate-total',
'errorrate-4xx', 'errorrate-5xx').

=item B<--critical-*>

Thresholds critical (Can be: 'errorrate-total',
'errorrate-4xx', 'errorrate-5xx').

=back

=cut

