package Paws::API::RegionalEndpointCaller {
  use Moose::Role;
  use Paws::Net::Regions;

  has region => (is => 'rw', isa => 'Str|Undef');
  requires 'service';

  has _endpoint_info => (
    is => 'ro',
    init_arg => undef,
    lazy => 1,
    default => sub {
      my $self = shift;
      my $resolver = Paws::Net::Regions->new();
      my $endpoint = $resolver->construct_endpoint($self->service, $self->region);
      return $endpoint;
    }
  );

  has _region_for_signature => (
    is => 'rw', 
    isa => 'Str', 
    lazy => 1,
    init_arg => undef, 
    default => sub {
      my $self = shift;
      $self->_endpoint_info->{ credentialScope }->{ region } or $self->region;
    }
  );


  has endpoint_host => (
    is => 'ro',
    isa => 'Str',
    lazy => 1,
    default => sub {
      shift->_endpoint_info->{ url }->host;
    }
  ); 

  has _api_endpoint => (
    is => 'ro',
    isa => 'Str',
    lazy => 1,
    default => sub {
      shift->_endpoint_info->{ url }->as_string;
    }
  ); 
}

1;
