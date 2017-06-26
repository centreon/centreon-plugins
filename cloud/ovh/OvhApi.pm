package OvhApi;

use strict;
use warnings;

our $VERSION = 1.0;


use OvhApi::Answer;

use Carp            qw{ carp croak };
use List::Util      'first';
use LWP::UserAgent  ();
use JSON            ();
use Digest::SHA    'sha1_hex';



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Class constants

use constant {
    OVH_API_EU => 'https://eu.api.ovh.com/1.0',
    OVH_API_CA => 'https://ca.api.ovh.com/1.0',
};

# End - Class constants
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Class variables

my $UserAgent = LWP::UserAgent->new(timeout => 10);
my $Json      = JSON->new->allow_nonref;

my @accessRuleMethods = qw{ GET POST PUT DELETE };

# End - Class variables
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Class methods

sub new
{
    my @keys = qw{ applicationKey applicationSecret consumerKey };

    my ($class, %params) = @_;

    if (my @missingParameters = grep { not $params{$_} } qw{ applicationKey applicationSecret })
    {
        local $" = ', ';
        croak "Missing parameter: @missingParameters";
    }

    unless ($params{'type'} and grep { $params{'type'} eq $_ } (OVH_API_EU, OVH_API_CA))
    {
        carp 'Missing or invalid type parameter: defaulting to OVH_API_EU';
    }

    my $self = {
        _type   => ($params{'type'} or OVH_API_EU),
    };

    @$self{@keys} = @params{@keys};

    bless $self, $class;
}

sub setRequestTimeout
{
    my ($class, %params) = @_;

    if ($params{'timeout'} =~ /^\d+$/)
    {
        $UserAgent->timeout($params{'timeout'});
    }
    elsif (exists $params{'timeout'})
    {
        carp "Invalid timeout: $params{'timeout'}";
    }
    else
    {
        carp 'Missing parameter: timeout';
    }
}

# End - Class methods
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Instance methods

sub rawCall
{
    my ($self, %params) = @_;

    my $method = lc $params{'method'};
    my $url    = $self->{'_type'} . (substr($params{'path'}, 0, 1) eq '/' ? '' : '/') . $params{'path'};

    my %httpHeaders;

    my $body = '';
    my %content;

    if ($method ne 'get' and $method ne 'delete')
    {
        $body = $Json->encode($params{'body'});

        $httpHeaders{'Content-type'} = 'application/json';
        $content{'Content'} = $body;
    }

    unless ($params{'noSignature'})
    {
        my $now    = $self->_timeDelta + time;

        $httpHeaders{'X-Ovh-Consumer'}      = $self->{'consumerKey'},
        $httpHeaders{'X-Ovh-Timestamp'}     = $now,
        $httpHeaders{'X-Ovh-Signature'}     = '$1$' . sha1_hex(join('+', (
            # Full signature is '$1$' followed by the hex digest of the SHA1 of all these data joined by a + sign
            $self->{'applicationSecret'},   # Application secret
            $self->{'consumerKey'},         # Consumer key
            uc $method,                     # HTTP method (uppercased)
            $url,                           # Full URL
            $body,                          # Full body
            $now,                           # Curent OVH server time
        )));
    }

    $httpHeaders{'X-Ovh-Application'}   = $self->{'applicationKey'},

    return OvhApi::Answer->new(response => $UserAgent->$method($url, %httpHeaders, %content));
}

sub requestCredentials
{
    my ($self, %params) = @_;

    croak 'Missing parameter: accessRules' unless $params{'accessRules'};
    croak 'Invalid parameter: accessRules' if ref $params{'accessRules'} ne 'ARRAY';

    my @rules = map {
        croak 'Invalid access rule: must be HASH ref' if ref ne 'HASH';

        my %rule = %$_;

        $rule{'method'} = uc $rule{'method'};

        croak 'Access rule must have method and path keys' unless $rule{'method'} and $rule{'path'};
        croak 'Invalid access rule method'                 unless first { $_ eq $rule{'method'} } (@accessRuleMethods, 'ALL');

        if ($rule{'method'} eq 'ALL')
        {
            map { path => $rule{'path'}, method => $_ }, @accessRuleMethods;
        }
        else
        {
            \%rule
        }
    } @{ $params{'accessRules'} };

    return $self->post(path => '/auth/credential/', noSignature => 1, body => { accessRules => \@rules });
}

# Generation of helper subs: simple wrappers to rawCall
# Generate: get(), post(), put(), delete()
{
    no strict 'refs';

    for my $method (qw{ get post put delete })
    {
        *$method = sub { rawCall(@_, 'method', $method ) };
    }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
# Private part

sub _timeDelta
{
    my ($self, %params) = @_;

    unless (defined $self->{'_timeDelta'})
    {
        if (my $ServerTimeResponse = $self->get(path => 'auth/time', noSignature => 1))
        {
            $self->{'_timeDelta'} = ($ServerTimeResponse->content - time);
        }
        else
        {
            return 0;
        }
    }

    return $self->{'_timeDelta'};
}

# End - Instance methods
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


return 42;


__END__

=head1 NAME

OvhApi - Official OVH Perl wrapper upon the OVH RESTful API.

=head1 SYNOPSIS

  use OvhApi;

  my $Api    = OvhApi->new(type => OvhApi::OVH_API_EU, applicationKey => $AK, applicationSecret => $AS, consumerKey => $CK);
  my $Answer = $Api->get(path => '/me');

=head1 DESCRIPTION

This module is an official Perl wrapper that OVH provides in order to offer a simple way to use its RESTful API.
C<OvhApi> handles the authentication layer, and uses C<LWP::UserAgent> in order to run requests.

Answer are retured as instances of L<OvhApi::Answer|OvhApi::Answer>.

=head1 CLASS METHODS

=head2 Constructor

There is only one constructor: C<new>.

Its parameters are:

    Parameter           Mandatory                               Default                 Usage
    ------------        ------------                            ----------              --------
    type                Carp if missing                         OVH_API_EU()            Determine if you'll use european or canadian OVH API (possible values are OVH_API_EU and OVH_API_CA)
    timeout             No                                      10                      Set the timeout LWP::UserAgent will use
    applicationKey      Yes                                     -                       Your application key
    applicationSecret   Yes                                     -                       Your application secret
    consumerKey         Yes, unless for a credential request    -                       Your consumer key

=head2 OVH_API_EU

L<Constant|constant> that points to the root URL of OVH european API.

=head2 OVH_API_CA

L<Constant|constant> that points to the root URL of OVH canadian API.

=head2 setRequestTimeout

This method changes the timeout C<LWP::UserAgent> uses. You can set that in L<new|/Constructor> instead.

Its parameters are:

    Parameter           Mandatory
    ------------        ------------
    timeout             Yes

=head1 INSTANCE METHODS

=head2 rawCall

This is the main method of that wrapper. This method will take care of the signature, of the JSON conversion of your data, and of the effective run of the query.

Its parameters are:

    Parameter           Mandatory                               Default                 Usage
    ------------        ------------                            ----------              --------
    path                Yes                                     -                       The API URL you want to request
    method              Yes                                     -                       The HTTP method of the request (GET, POST, PUT, DELETE)
    body                No                                      ''                      The body to send in the query. Will be ignore on a GET
    noSignature         No                                      false                   If set to a true value, no signature will be send

=head2 get

Helper method that wraps a call to:

    rawCall(method => 'get");

All parameters are forwarded to L<rawCall|/rawCall>.

=head2 post

Helper method that wraps a call to:

    rawCall(method => 'post');

All parameters are forwarded to L<rawCall|/rawCall>.

=head2 put

Helper method that wraps a call to:

    rawCall(method => 'put');

All parameters are forwarded to L<rawCall|/rawCall>.

=head2 delete

Helper method that wraps a call to:

    rawCall(method => 'delete');

All parameters are forwarded to L<rawCall|/rawCall>.

=head2 requestCredentials

This method will request a Consumer Key to the API. That credential will need to be validated with the link returned in the answer.

Its parameters are:

    Parameter           Mandatory
    ------------        ------------
    accessRules         Yes

The C<accessRules> parameter is an ARRAY of HASHes. Each hash contains these keys:

=over

=item * method: an HTTP method among GET, POST, PUT and DELETE. ALL is a special values that includes all the methods;

=item * path: a string that represents the URLs the credential will have access to. C<*> can be used as a wildcard. C</*> will allow all URLs, for example.

=back

=head3 Example

    my $Api = OvhApi->new(type => OvhApi::OVH_API_EU, applicationKey => $AK, applicationSecret => $AS, consumerKey => $CK);
    my $Answer = $Api->requestCredentials(accessRules => [ { method => 'ALL', path => '/*' }]);

    if ($Answer)
    {
        my ($consumerKey, $validationUrl) = @{ $Answer->content}{qw{ consumerKey validationUrl }};

        # $consumerKey contains the newly created  Consumer Key
        # $validationUrl contains a link to OVH website in order to login an OVH account and link it to the credential
    }

=head1 SEE ALSO

The guts of module are using: C<LWP::UserAgent>, C<JSON>, C<Digest::SHA1>.

=head1 COPYRIGHT

Copyright (c) 2013, OVH SAS.
All rights reserved.

This library is distributed under the terms of C<license.txt>.

=cut

