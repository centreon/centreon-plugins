
package Paws::EC2::CreateTags {
  use Moose;
  has DryRun => (is => 'ro', isa => 'Bool', traits => ['NameInRequest'], request_name => 'dryRun' );
  has Resources => (is => 'ro', isa => 'ArrayRef[Str]', traits => ['NameInRequest'], request_name => 'ResourceId' , required => 1);
  has Tags => (is => 'ro', isa => 'ArrayRef[Paws::EC2::Tag]', traits => ['NameInRequest'], request_name => 'Tag' , required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateTags');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::CreateTags - Arguments for method CreateTags on Paws::EC2

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateTags on the 
Amazon Elastic Compute Cloud service. Use the attributes of this class
as arguments to method CreateTags.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateTags.

As an example:

  $service_obj->CreateTags(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 DryRun => Bool

  

Checks whether you have the required permissions for the action,
without actually making the request, and provides an error response. If
you have the required permissions, the error response is
C<DryRunOperation>. Otherwise, it is C<UnauthorizedOperation>.










=head2 B<REQUIRED> Resources => ArrayRef[Str]

  

The IDs of one or more resources to tag. For example, ami-1a2b3c4d.










=head2 B<REQUIRED> Tags => ArrayRef[Paws::EC2::Tag]

  

One or more tags. The C<value> parameter is required, but if you don't
want the tag to have a value, specify the parameter with no value, and
we set the value to an empty string.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateTags in L<Paws::EC2>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

