#!/usr/bin/env perl
use App::PupTent;
use IO::All;
my $pup = App::PupTent->new();

my $file = $pup->copy_to_remote( '/home/joey/code/App-PupTent/conf/bashrc.pup',
    '?' );

if ( my $pid = fork() ) {
    warn "FILE IS $file";
    waitpid( $pid, 0 );
    warn "child is all done!";
    $pup->rm_remote('/tmp/bashrc.pup');
    warn "File deleted from remote";
}
else {
    exec('ssh -t localhost "/bin/bash --rcfile /tmp/bashrc.pup -i"');
}
