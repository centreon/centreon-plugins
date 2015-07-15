package Paws::API::SigninEndpointCaller {
  use Moose::Role;

  sub endpoint_host {
    my $self = shift;
    return 'signin.aws.amazon.com';
  }

  sub _api_endpoint {
    my $self = shift;
    return sprintf '%s://%s/federation', 'https', $self->endpoint_host;
  }
}

1;
