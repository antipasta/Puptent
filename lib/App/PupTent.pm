package App::PupTent;
use 5.008005;
use strict;
use warnings;
use Moo;
use Object::Remote;
use IO::All;
use File::Temp;
use IO::File;
our $VERSION = "0.01";

has remote => ( is => 'ro', lazy => 1, builder => '_build_remote');
has host => (is => 'ro', lazy => 1, default => sub { 'localhost'});

sub _build_remote {
    my $self = shift;
    return Object::Remote->connect($self->host); 
}
sub remote_io {
    my ($self,$file) = @_;
    return IO::All->new::on($self->remote,$file);
}
sub remote_temp {
    my ($self,$file) = @_;
    return File::Temp->new::on($self->remote, UNLINK => 0);
}

sub copy_to_remote {
    my ($self,$source,$dest) = @_;
    my $c = io($source)->slurp;
    #return $self->write_remote_file($dest,$c);
    return $self->write_remote_temp_file($c);
}

sub write_remote_temp_file {
    my ($self,$contents) = @_;
    my $rio = $self->remote_temp;
    $rio->print($contents);
    return $rio->filename;
}

sub write_remote_file {
    my ($self,$name,$contents) = @_;
    warn "WRITING REMOTE FILE $name";
    my $rio = $self->remote_io($name);
    $rio->print($contents);
    return $rio->name;
}
sub rm_remote {
    my ($self,$file) = @_;
    my $rio = $self->remote_io($file)->unlink;
}



1;
__END__

=encoding utf-8

=head1 NAME

App::PupTent - It's new $module

=head1 SYNOPSIS

    use App::PupTent;

=head1 DESCRIPTION

App::PupTent is ...

=head1 LICENSE

Copyright (C) Joe Papperello.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Joe Papperello E<lt>joe@socialflow.comE<gt>

=cut

