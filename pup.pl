#!/usr/bin/env perl
use strict;
use warnings;
use App::PupTent;
use Time::HiRes qw(time);
my ( $host, $port ) = @ARGV;
$port ||= 22;
$host ||= 'localhost';
my $took = time();
print "Getting $host ready for our arrival... ";
my $pup =
  App::PupTent->new( host => $host, ssh_options => [ '-A', "-p $port" ] );
my $home = $ENV{HOME};
$pup->copy_to_remote_recursive("$home/.puptent/");
print "All set!\n";
$took = time() - $took;
warn "TOOK [$took] seconds";
if ( my $pid = fork() ) {
    waitpid( $pid, 0 );
    print "Cleaning up after ourselves on $host...\n";
}
else {
    my $cmd = sprintf( qq|ssh -A -p %s -t %s "/bin/bash --rcfile %s -i"|,
        $port, $pup->host, $pup->copied_files->{'bashrc.pup'} );
    exec($cmd);
}
