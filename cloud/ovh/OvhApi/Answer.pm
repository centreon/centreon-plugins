package OvhApi::Answer;

use strict;
use warnings;

our $VERSION = 1.0;


use overload (
    bool        => \&isSuccess,
    '!'         => \&isFailure,
    fallback    => 0,
);

use Scalar::Util    'blessed';
use Carp            qw{ carp croak };
use JSON            ();



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Class variables

my $Json = JSON->new->allow_nonref;

# End - Class variables
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Class methods

sub new
{
    my ($class, %params) = @_;

    unless ($params{'response'})
    {
        croak 'Missing parameter: response';
    }

    unless (blessed $params{'response'} and $params{'response'}->isa('HTTP::Response'))
    {
        croak 'Invalid parameter: reponse';
    }

    bless { response => $params{'response'} }, $class;
}

# End - Class methods
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Instance methods

sub isSuccess
{
    my ($self) = @_;

    return $self->{'response'}->is_success;
}

sub isFailure
{
    my ($self) = @_;

    return not $self->isSuccess;
}


sub content
{
    my ($self) = @_;

    if ($self->isFailure)
    {
        carp 'Fetching content from a failed OvhApi::Response Object';
        return;
    }

    return $self->_generateContent;
}

sub error
{
    my ($self) = @_;

    return $self ? '' : $self->_generateContent->{'message'};
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
# private part

sub _generateContent
{
    my ($self) = @_;

    my $content;

    if ($self->{'response'}->header('Client-Warning') and $self->{'response'}->header('Client-Warning') eq 'Internal response')
    {
        return { message => 'Internal LWP::UserAgent error : ' . $self->{'response'}->content };
    }

    eval { $content = $Json->decode($self->{'response'}->content); 1; } or do { 
        carp 'Failed to parse JSON content from the answer: ', $self->{'response'}->content;
        return;
    };

    return $content;
}

# End - Instance methods
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


return 42;

__END__

=head1 NAME

OvhApi::Answer - Response to a request run with C<OvhApi>.

=head1 SYNOPSIS

    my $Answer = $Api->get(path => '/me');

    if ($Answer)
    {
        # Success: can fetch content and process
        my $content = $Answer->content;
    }
    else
    {
        # Request failed: stop here and retrieve the error
        my $error = $Answer->error;
    }

=head1 DESCRIPTION

This module represents a response to a query run with C<OvhApi>. It is build upon a C<HTTP::Request> object.

=head1 CLASS METHODS

=head2 Constructor

There is only one constructor: C<new>.

Its parameters are:

    Parameter           Mandatory                               Default                 Usage
    ------------        ------------                            ----------              --------
    response            Yes                                     -                       An HTTP::Response object return by LWP::UserAgent

=head1 INSTANCE METHODS

=head2 content

Returns the content of the answer. This method will C<carp> if the answer is an error.

It takes no parameter.

=head2 error

Returns the error message of the answer, or an empty string if the answer is a success.

It takes no parameter.

=head2 isSuccess

Forwards a call to C<HTTP::Response::is_error> in the inner C<HTTP::Response> of the answer. Returns true is the request was a success, false otherwise.

It takes no parameter.

This method is used for the C<bool> L<overload|overload>.

=head2 isFailure

Helper method which returns the boolean negation of L<isSuccess|/isSuccess>.

It takes no parameter.

=head1 SEE ALSO

The guts of module are using: C<JSON>.

=head1 COPYRIGHT

Copyright (c) 2013, OVH SAS.
All rights reserved.

This library is distributed under the terms of C<license.txt>.

=cut


