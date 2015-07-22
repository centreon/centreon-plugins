package Paws::Net::SigninCaller {
  use Moose::Role;
  use JSON;
  use URI::Template;

  sub _call_uri {
    my ($self, $call, $qparams) = @_;
    my $uri_template = $call->meta->name->_api_uri;
    my $t = URI::Template->new( $uri_template );

    my $uri = $t->process({});
    $uri->query_form(%$qparams);
    return $uri->as_string;
  }

  sub prepare_request_for_call {
    my ($self, $call) = @_;

    my $request = Paws::Net::APIRequest->new();

    $request->method('GET');
   
    my $qparams;
    if ($call->_api_call eq 'getSigninToken') {
      #Until we have a way to declare objects that get json-encoded to API calls, we
      #will have to "hand-encode" the Session Parameter
      $qparams = { Action => $call->_api_call,
                   SessionType => 'json',
                   Session => encode_json({
                     sessionId    => $call->SessionId,
                     sessionKey   => $call->SessionKey,
                     sessionToken => $call->SessionToken
                   }),
      };
    } elsif ($call->_api_call eq 'login') {
       $qparams = { Action => $call->_api_call,
                    Destination => $call->Destination,
                    Issuer => $call->Issuer,
                    SigninToken => $call->SigninToken
	          };
    } else {
      die "Don't know how to call " . $call->_api_call;
    }

    my $uri = $self->_call_uri($call, $qparams);
    $request->url($self->_api_endpoint . $uri);
    $request->uri($uri);

    $self->sign($request);

    return $request;
  }
}

1;
