
package Paws::SimpleWorkflow::ListActivityTypes {
  use Moose;
  has domain => (is => 'ro', isa => 'Str', required => 1);
  has maximumPageSize => (is => 'ro', isa => 'Int');
  has name => (is => 'ro', isa => 'Str');
  has nextPageToken => (is => 'ro', isa => 'Str');
  has registrationStatus => (is => 'ro', isa => 'Str', required => 1);
  has reverseOrder => (is => 'ro', isa => 'Bool');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ListActivityTypes');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::SimpleWorkflow::ActivityTypeInfos');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SimpleWorkflow::ListActivityTypes - Arguments for method ListActivityTypes on Paws::SimpleWorkflow

=head1 DESCRIPTION

This class represents the parameters used for calling the method ListActivityTypes on the 
Amazon Simple Workflow Service service. Use the attributes of this class
as arguments to method ListActivityTypes.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ListActivityTypes.

As an example:

  $service_obj->ListActivityTypes(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> domain => Str

  

The name of the domain in which the activity types have been
registered.










=head2 maximumPageSize => Int

  

The maximum number of results that will be returned per call.
C<nextPageToken> can be used to obtain futher pages of results. The
default is 100, which is the maximum allowed page size. You can,
however, specify a page size I<smaller> than 100.

This is an upper limit only; the actual number of results returned per
call may be fewer than the specified maximum.










=head2 name => Str

  

If specified, only lists the activity types that have this name.










=head2 nextPageToken => Str

  

If a C<NextPageToken> was returned by a previous call, there are more
results available. To retrieve the next page of results, make the call
again using the returned token in C<nextPageToken>. Keep all other
arguments unchanged.

The configured C<maximumPageSize> determines how many results can be
returned in a single call.










=head2 B<REQUIRED> registrationStatus => Str

  

Specifies the registration status of the activity types to list.










=head2 reverseOrder => Bool

  

When set to C<true>, returns the results in reverse order. By default,
the results are returned in ascending alphabetical order by C<name> of
the activity types.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ListActivityTypes in L<Paws::SimpleWorkflow>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

