
package Paws::DS::DescribeDirectories {
  use Moose;
  has DirectoryIds => (is => 'ro', isa => 'ArrayRef[Str]');
  has Limit => (is => 'ro', isa => 'Int');
  has NextToken => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeDirectories');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::DS::DescribeDirectoriesResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::DS::DescribeDirectories - Arguments for method DescribeDirectories on Paws::DS

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeDirectories on the 
AWS Directory Service service. Use the attributes of this class
as arguments to method DescribeDirectories.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeDirectories.

As an example:

  $service_obj->DescribeDirectories(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 DirectoryIds => ArrayRef[Str]

  

A list of identifiers of the directories to obtain the information for.
If this member is null, all directories that belong to the current
account are returned.

An empty list results in an C<InvalidParameterException> being thrown.










=head2 Limit => Int

  

The maximum number of items to return. If this value is zero, the
maximum number of items is specified by the limitations of the
operation.










=head2 NextToken => Str

  

The I<DescribeDirectoriesResult.NextToken> value from a previous call
to DescribeDirectories. Pass null if this is the first call.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeDirectories in L<Paws::DS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

