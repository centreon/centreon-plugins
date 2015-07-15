package Paws::Net::Caller {
  use Moose;
  use Carp qw(croak);
  with 'Paws::Net::CallerRole';

  has debug              => ( is => 'rw', required => 0, default => sub { 0 } );
  has ua => (is => 'rw', required => 1, lazy => 1,
    default     => sub {
        use HTTP::Tiny;
        HTTP::Tiny->new(
            'agent' => 'AWS Perl SDK ' . $Paws::VERSION,
        );
    }
  );

  sub do_call {
    my ($self, $service, $call_object) = @_;

    my $requestObj = $service->prepare_request_for_call($call_object); 

    my $headers = $requestObj->header_hash;
    # HTTP::Tiny derives the Host header from the URL. It's an error to set it.
    delete $headers->{Host};

    my $response = $self->ua->request(
      $requestObj->method,
      $requestObj->url,
      {
        headers => $headers,
        (defined $requestObj->content)?(content => $requestObj->content):(),
      }
    );

    my $res = $service->handle_response($call_object, $response->{status}, $response->{content}, $response->{headers});
    if (not ref($res)){
      return $res;
    } elsif ($res->isa('Paws::Exception')) {
      $res->throw;
    } else {
      return $res;
    }
  }
}

1;
