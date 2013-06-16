#!/usr/bin/env perl
use strict;
use warnings;
use App::PupTent;
my ( $host, $port ) = @ARGV;
$port ||= 22;
$host ||= 'localhost';
print "Getting $host ready for our arrival...\n";
my $pup =
  App::PupTent->new( host => $host, ssh_options => [ '-A', "-p $port" ] );

$pup->copy_to_remote_recursive('/home/joey/code/App-PupTent/conf/');
print "All set!\n";

if ( my $pid = fork() ) {
    waitpid( $pid, 0 );
    print "Cleaning up after ourselves on $host...\n";
}
else {
    my $cmd = sprintf( qq|ssh -A -p %s -t %s "/bin/bash --rcfile %s -i"|,
        $port, $pup->host, $pup->copied_files->{'bashrc.pup'} );
    exec($cmd);
}
