
package Paws::SNS::CreateTopic {
  use Moose;
  has Name => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateTopic');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::SNS::CreateTopicResponse');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'CreateTopicResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SNS::CreateTopic - Arguments for method CreateTopic on Paws::SNS

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateTopic on the 
Amazon Simple Notification Service service. Use the attributes of this class
as arguments to method CreateTopic.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateTopic.

As an example:

  $service_obj->CreateTopic(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> Name => Str

  

The name of the topic you want to create.

Constraints: Topic names must be made up of only uppercase and
lowercase ASCII letters, numbers, underscores, and hyphens, and must be
between 1 and 256 characters long.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateTopic in L<Paws::SNS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

