
package Paws::EC2::DeleteTags {
  use Moose;
  has DryRun => (is => 'ro', isa => 'Bool', traits => ['NameInRequest'], request_name => 'dryRun' );
  has Resources => (is => 'ro', isa => 'ArrayRef[Str]', traits => ['NameInRequest'], request_name => 'resourceId' , required => 1);
  has Tags => (is => 'ro', isa => 'ArrayRef[Paws::EC2::Tag]', traits => ['NameInRequest'], request_name => 'tag' );

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DeleteTags');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::DeleteTags - Arguments for method DeleteTags on Paws::EC2

=head1 DESCRIPTION

This class represents the parameters used for calling the method DeleteTags on the 
Amazon Elastic Compute Cloud service. Use the attributes of this class
as arguments to method DeleteTags.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DeleteTags.

As an example:

  $service_obj->DeleteTags(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 DryRun => Bool

  

Checks whether you have the required permissions for the action,
without actually making the request, and provides an error response. If
you have the required permissions, the error response is
C<DryRunOperation>. Otherwise, it is C<UnauthorizedOperation>.










=head2 B<REQUIRED> Resources => ArrayRef[Str]

  

The ID of the resource. For example, ami-1a2b3c4d. You can specify more
than one resource ID.










=head2 Tags => ArrayRef[Paws::EC2::Tag]

  

One or more tags to delete. If you omit the C<value> parameter, we
delete the tag regardless of its value. If you specify this parameter
with an empty string as the value, we delete the key only if its value
is an empty string.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DeleteTags in L<Paws::EC2>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

