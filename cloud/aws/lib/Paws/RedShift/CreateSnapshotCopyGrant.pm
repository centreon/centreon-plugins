
package Paws::RedShift::CreateSnapshotCopyGrant {
  use Moose;
  has KmsKeyId => (is => 'ro', isa => 'Str');
  has SnapshotCopyGrantName => (is => 'ro', isa => 'Str', required => 1);
  has Tags => (is => 'ro', isa => 'ArrayRef[Paws::RedShift::Tag]');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateSnapshotCopyGrant');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::RedShift::CreateSnapshotCopyGrantResult');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'CreateSnapshotCopyGrantResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RedShift::CreateSnapshotCopyGrant - Arguments for method CreateSnapshotCopyGrant on Paws::RedShift

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateSnapshotCopyGrant on the 
Amazon Redshift service. Use the attributes of this class
as arguments to method CreateSnapshotCopyGrant.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateSnapshotCopyGrant.

As an example:

  $service_obj->CreateSnapshotCopyGrant(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 KmsKeyId => Str

  

The unique identifier of the customer master key (CMK) to which to
grant Amazon Redshift permission. If no key is specified, the default
key is used.










=head2 B<REQUIRED> SnapshotCopyGrantName => Str

  

The name of the snapshot copy grant. This name must be unique in the
region for the AWS account.

Constraints:

=over

=item * Must contain from 1 to 63 alphanumeric characters or hyphens.

=item * Alphabetic characters must be lowercase.

=item * First character must be a letter.

=item * Cannot end with a hyphen or contain two consecutive hyphens.

=item * Must be unique for all clusters within an AWS account.

=back










=head2 Tags => ArrayRef[Paws::RedShift::Tag]

  

A list of tag instances.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateSnapshotCopyGrant in L<Paws::RedShift>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

