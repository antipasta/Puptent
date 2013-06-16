package App::PupTent;
use 5.008005;
use strict;
use warnings;
use Moo;
use Object::Remote;
use IO::All;
use File::Temp qw( tempdir);
our $VERSION = "0.01";

has remote       => ( is => 'ro', lazy => 1, builder => '_build_remote' );
has host         => ( is => 'ro', lazy => 1, default => sub { 'localhost' } );
has remote_dir   => ( is => 'ro', lazy => 1, builder => '_build_remote_dir' );
has ssh_options  => ( is => 'ro', lazy => 1, default => sub { ['-A'] } );
has copied_files => ( is => 'ro', lazy => 1, default => sub { +{} } );

sub _build_remote {
    my $self = shift;
    return Object::Remote->connect( $self->host,
        ssh_options => $self->ssh_options );
}

sub remote_io {
    my ( $self, $file ) = @_;
    return IO::All->new::on( $self->remote, $file );
}

sub remote_temp {
    my ( $self, $file ) = @_;
    return File::Temp->new::on(
        $self->remote,
        UNLINK => 1,
        SUFFIX => '.pup',
        DIR    => $self->remote_dir
    );
}

sub _build_remote_dir {
    my ( $self, $file ) = @_;
    my $tempdir = File::Temp->can::on( $self->remote, 'tempdir' );
    my $tmp = $tempdir->( 'PUPXXXX', TMPDIR => 1, CLEANUP => 1 );
    return $tmp;
}

sub copy_to_remote_recursive {
    my ( $self, $source_dir ) = @_;
    my @dir = io($source_dir)->all;
    $self->copy_to_remote( $_->pathname, $_->filename ) for (@dir);
}

sub copy_to_remote {
    my ( $self, $source, $dest ) = @_;
    my $file = io($source);
    my $c    = $file->slurp;

    my $copied =
      ($dest)
      ? $self->write_remote_file( $dest, $c )
      : $self->write_remote_temp_file($c);
    $self->copied_files->{ $file->filename } =
      ($dest) ? $copied->pathname : $copied->filename;

    return $copied;
}

sub write_remote_temp_file {
    my ( $self, $contents ) = @_;
    my $dir = $self->remote_dir;
    $contents =~ s/__DIR__/$dir/g;
    my $rio = $self->remote_temp;
    $rio->print($contents);
    $rio->close;
    return $rio;
}

sub write_remote_file {
    my ( $self, $name, $contents ) = @_;
    my $dir = $self->remote_dir;
    $contents =~ s/__DIR__/$dir/g;
    my $rio = $self->remote_io( $dir . '/' . $name );
    $rio->print($contents);
    $rio->close;
    return $rio;
}

sub rm_remote {
    my ( $self, $file ) = @_;
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

