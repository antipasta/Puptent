package App::Bindle;
use 5.008005;
use strict;
use warnings;
use Moo;
use Object::Remote;
use IO::All;
use IO::File;
use File::Temp qw( tempdir );
use File::Path qw( make_path );
our $VERSION = "0.01";

has remote       => ( is => 'ro', lazy => 1, builder => '_build_remote' );
has host         => ( is => 'ro', lazy => 1, default => sub { 'localhost' } );
has remote_dir   => ( is => 'ro', lazy => 1, builder => '_build_remote_dir' );
has ssh_options  => ( is => 'ro', lazy => 1, default => sub { ['-A'] } );
has copied_files => ( is => 'ro', lazy => 1, default => sub { +{} } );
has local_dir   => ( is => 'ro');

sub _build_remote {
    my $self = shift;
    return Object::Remote->connect( $self->host,
        ssh_options => $self->ssh_options );
}

sub remote_write {
    my ( $self, $file ) = @_;
    return IO::File->new::on( $self->remote, $file, "w" );
}

sub create_remote_dir {
    my ($self,$dir) = @_;
    my $new_remote_path = $self->remote_dir . '/' . $dir;
    my $mkdir = File::Path->can::on( $self->remote, 'make_path');
    $mkdir->($new_remote_path);
}

sub _build_remote_dir {
    my ( $self, $file ) = @_;
    my $tempdir = File::Temp->can::on( $self->remote, 'tempdir' );
    my $tmp = $tempdir->( 'PUPXXXX', TMPDIR => 1, CLEANUP => 1 );
    return $tmp;
}

sub copy_to_remote_recursive {
    my ( $self, $rel_path ) = @_;
    my $source_dir = $self->local_dir;
    if ($rel_path) {
        $source_dir = $source_dir . '/' . $rel_path;
        $self->create_remote_dir($rel_path);
    }

    my @dir = io($source_dir)->all;
    for my $to_copy (@dir) {
        if ($to_copy->is_dir) {
            my $rel = $to_copy->abs2rel($self->local_dir);
            $self->copy_to_remote_recursive($rel);
        }
        else {
            $self->copy_to_remote( $to_copy, $to_copy->filename, $rel_path);
        }

    }
}

sub copy_to_remote {
    my ( $self, $source, $remote_filename, $remote_path ) = @_;

    my $file = io($source);
    my $c    = $file->slurp;

    my $copied = $self->write_remote_file( $remote_filename, $c, $remote_path );
    $self->copied_files->{ $file->filename } = $copied;

    return $copied;
}

sub write_remote_file {
    my ( $self, $name, $contents, $remote_path ) = @_;
    my $dir = $self->remote_dir;
    $dir = $dir . '/' . $remote_path if ($remote_path);
    $contents =~ s/__BINDLE__/$dir/g;
    my $remote_file = $dir . '/' . $name;
    my $rio         = $self->remote_write($remote_file);
    $rio->print($contents);
    $rio->close;
    return $remote_file;
}

1;
__END__

=encoding utf-8

=head1 NAME

App::Bindle - It's new $module

=head1 SYNOPSIS

    use App::Bindle;

=head1 DESCRIPTION

App::Bindle is ...

=head1 LICENSE

Copyright (C) Joe Papperello.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Joe Papperello E<lt>joe@socialflow.comE<gt>

=cut

