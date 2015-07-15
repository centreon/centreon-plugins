package Paws::Net::SigninCaller {
  use Moose::Role;
  use HTTP::Request::Common;
  use POSIX qw(strftime);
  use JSON;

  sub _is_internal_type {
    my ($self, $att_type) = @_;
    return ($att_type eq 'Str' or $att_type eq 'Int' or $att_type eq 'Bool' or $att_type eq 'Num');
  }

  sub prepare_request_for_call {
    my ($self, $call) = @_;

    my $request = Paws::Net::APIRequest->new();

    $request->url($self->_api_endpoint);
    $request->method('GET');

    if ($call->_api_call eq 'getSigninToken') {
      $request->parameters({ Action => $call->_api_call,
                             SessionType => 'json', 
                             Session => encode_json({
	                       sessionId    => $call->SessionId,
	                       sessionKey   => $call->SessionKey,
	                       sessionToken => $call->SessionToken
	                     })
                           });
    } elsif ($call->_api_call eq 'login') {
       $request->parameters({ Action => $call->_api_call,
                              Destination => $call->Destination,
                              Issuer => $call->Issuer,
                              SigninToken => $call->SigninToken
	                     });
    } else {
      die "Don't know how to call something that isn't getSiginToken";
    }

    $self->sign($request);

    return $request;
  }
}

1;
