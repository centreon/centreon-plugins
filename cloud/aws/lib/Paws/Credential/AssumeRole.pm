package Paws::Credential::AssumeRole {
  use JSON;
  use Moose;
  use DateTime;
  use DateTime::Format::ISO8601;
  with 'Paws::Credential';

  has expiration => (
    is => 'rw',
    isa => 'DateTime',
    lazy => 1,
    default => sub {
      DateTime->from_epoch(epoch => 0); # need a better way to do this
    }
  );

  has actual_creds => (is => 'rw');

  sub access_key {
    my $self = shift;
    $self->_refresh;
    $self->actual_creds->AccessKeyId;
  }

  sub secret_key {
    my $self = shift;
    $self->_refresh;
    $self->actual_creds->SecretAccessKey;
  }

  sub session_token {
    my $self = shift;
    $self->_refresh;
    $self->actual_creds->SessionToken;
  }

  has sts => (is => 'ro', isa => 'Paws::STS', default => sub {
    Paws->service('STS');
  });

  has DurationSeconds => (is => 'rw', isa => 'Maybe[Int]');
  has Policy => (is => 'rw', isa => 'Maybe[Str]');

  has ExternalId => (is => 'rw', isa => 'Maybe[Str]');
  has RoleArn => (is => 'rw', isa => 'Str', required => 1);
  has RoleSessionName => (is => 'rw', isa => 'Str', required => 1);
  
  sub _refresh {
    my $self = shift;

    return if (($self->expiration - DateTime->now())->is_positive);

    my $result = $self->sts->AssumeRole(
      RoleSessionName => $self->RoleSessionName,
      RoleArn => $self->RoleArn,
      (defined $self->ExternalId) ? (ExternalId => $self->ExternalId) : (),
      (defined $self->DurationSeconds) ? (DurationSeconds => $self->DurationSeconds) : (),
      (defined $self->Policy) ? (Policy => $self->Policy) : (),
    );

    my $creds = $self->actual_creds($result->Credentials);
    $self->expiration(DateTime::Format::ISO8601->parse_datetime($result->Credentials->Expiration));
  }

  no Moose;
}

1;
