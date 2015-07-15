
package Paws::RedShift::CreateTags {
  use Moose;
  has ResourceName => (is => 'ro', isa => 'Str', required => 1);
  has Tags => (is => 'ro', isa => 'ArrayRef[Paws::RedShift::Tag]', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateTags');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RedShift::CreateTags - Arguments for method CreateTags on Paws::RedShift

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateTags on the 
Amazon Redshift service. Use the attributes of this class
as arguments to method CreateTags.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateTags.

As an example:

  $service_obj->CreateTags(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> ResourceName => Str

  

The Amazon Resource Name (ARN) to which you want to add the tag or
tags. For example, C<arn:aws:redshift:us-east-1:123456789:cluster:t1>.










=head2 B<REQUIRED> Tags => ArrayRef[Paws::RedShift::Tag]

  

One or more name/value pairs to add as tags to the specified resource.
Each tag name is passed in with the parameter C<Key> and the
corresponding value is passed in with the parameter C<Value>. The
C<Key> and C<Value> parameters are separated by a comma (,). Separate
multiple tags with a space. For example, C<--tags
"Key"="owner","Value"="admin" "Key"="environment","Value"="test"
"Key"="version","Value"="1.0">.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateTags in L<Paws::RedShift>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

