package Paws::Net::RestJsonResponse {
  use Moose::Role;
  use JSON;
  use Carp qw(croak);
  use Paws::Exception;
  
  sub unserialize_response {
    my ($self, $data) = @_;
    my $json = from_json( $data );
    return $json;
  }

  sub error_to_exception {
    my ($self, $struct, $call_object, $http_status, $content, $headers) = @_;

    my ($message, $request_id, $code);

    if (exists $struct->{message}){
      $message = $struct->{message};
    } elsif (exists $struct->{Message}){
      $message = $struct->{Message};
    } else {
      die "Unrecognized error message format";
    }

    if (exists $headers->{'x-amzn-errortype'}){
      $code = (split /:/, $headers->{'x-amzn-errortype'})[0];
    } else {
      $code = (exists $struct->{Code}) ? $struct->{Code} : $struct->{ code };
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
