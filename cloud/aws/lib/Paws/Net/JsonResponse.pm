package Paws::Net::JsonResponse {
  use Moose::Role;
  use JSON;
  use Carp qw(croak);
  use Paws::Exception;
  
  sub unserialize_response {
    my ($self, $data) = @_;

    return {} if ($data eq '');

    my $json = from_json( $data );
    return $json;
  }

  sub error_to_exception {
    my ($self, $struct, $call_object, $http_status, $content, $headers) = @_;

    my ($message, $request_id);

    if (exists $struct->{message}){
      $message = $struct->{message};
    } elsif (exists $struct->{Message}){
      $message = $struct->{Message};
    } else {
      die "Unrecognized error message format";
    }

    my $code = $struct->{__type};
    if ($code =~ m/#/) {
      $code = (split /#/, $code)[1];
    }
    $request_id = $headers->{ 'x-amzn-requestid' };

    Paws::Exception->new(
      message => $message,
      code => $code,
      request_id => $request_id
    );
  }
}

1;
