package HTML::Zoom::Transform;

use strict;
use warnings FATAL => 'all';
use base qw(HTML::Zoom::SubObject);

sub new {
  my ($class, $args) = @_;
  my $new = $class->SUPER::new($args);
  $new->{selector} = $args->{selector};
  $new->{filters} = $args->{filters}||[];
  $new;
}

sub selector { shift->{selector} }

sub filters { shift->{filters} }

sub with_filter {
  my ($self, $filter) = @_;
  (ref $self)->new({
    selector => $self->selector,
    filters => [ @{$self->filters}, $filter ]
  });
}

sub apply_to_stream {
  my ($self, $stream) = @_;
  HTML::Zoom::FilterStream->new({
    stream => $stream,
    match => $self->selector,
    filters => $self->filters,
    zconfig => $self->_zconfig,
  });
}
    

1;
