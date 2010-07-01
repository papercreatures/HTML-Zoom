package HTML::Zoom::StreamBase;

use strict;
use warnings FATAL => 'all';
use HTML::Zoom::TransformBuilder;

sub _zconfig { shift->{_zconfig} }

sub peek {
  my ($self) = @_;
  if (exists $self->{_peeked}) {
    return ($self->{_peeked});
  }
  if (my ($peeked) = $self->_next) {
    return ($self->{_peeked} = $peeked);
  }
  return;
}

sub next {
  my ($self) = @_;

  # peeked entry so return that

  if (exists $self->{_peeked}) {
    return (delete $self->{_peeked});
  }

  $self->_next;
}


sub flatten {
  my $self = shift;
  require HTML::Zoom::FlattenedStream;
  HTML::Zoom::FlattenedStream->new({
    source => $self,
    zconfig => $self->_zconfig
  });
}

sub map {
  my ($self, $mapper) = @_;
  require HTML::Zoom::MappedStream;
  HTML::Zoom::MappedStream->new({
    source => $self, mapper => $mapper, zconfig => $self->_zconfig
  });
}

sub with_filter {
  my ($self, $selector, $filter) = @_;
  my $match = $self->_parse_selector($selector);
  $self->_zconfig->stream_utils->wrap_with_filter($self, $match, $filter);
}

sub with_transform {
  my ($self, $transform) = @_;
  $transform->apply_to_stream($self);
}

sub select {
  my ($self, $selector) = @_;
  return HTML::Zoom::TransformBuilder->new({
    zconfig => $self->_zconfig,
    selector => $selector,
    filters => [],
    proto => $self,
  });
}

sub apply {
  my ($self, $code) = @_;
  local $_ = $self;
  $self->$code;
}

1;
