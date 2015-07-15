
package Paws::Kinesis::PutRecords {
  use Moose;
  has Records => (is => 'ro', isa => 'ArrayRef[Paws::Kinesis::PutRecordsRequestEntry]', required => 1);
  has StreamName => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'PutRecords');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::Kinesis::PutRecordsOutput');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Kinesis::PutRecords - Arguments for method PutRecords on Paws::Kinesis

=head1 DESCRIPTION

This class represents the parameters used for calling the method PutRecords on the 
Amazon Kinesis service. Use the attributes of this class
as arguments to method PutRecords.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to PutRecords.

As an example:

  $service_obj->PutRecords(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> Records => ArrayRef[Paws::Kinesis::PutRecordsRequestEntry]

  

The records associated with the request.










=head2 B<REQUIRED> StreamName => Str

  

The stream name associated with the request.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method PutRecords in L<Paws::Kinesis>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

