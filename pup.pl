#!/usr/bin/env perl
use strict;
use warnings;
use App::PupTent;
my ($host,$port) = @ARGV;
$port ||=22;
$host ||='localhost';
my $pup = App::PupTent->new(host => $host, ssh_options => ['-A', "-p $port"]);

my $rcfile =
  $pup->copy_to_remote( '/home/joey/code/App-PupTent/conf/bashrc.pup');
my $rcfilename = $rcfile->filename;
my $gitfile =
  $pup->copy_to_remote( '/home/joey/dotfiles/gitconfig', '.gitconfig');
my $tmux =
  $pup->copy_to_remote( '/home/joey/code/App-PupTent/conf/tmux.pup', 'tmux.pup');
my $vim =
  $pup->copy_to_remote( '/home/joey/code/App-PupTent/conf/vimrc.pup', 'vimrc.pup');

if ( my $pid = fork() ) {
    warn "File is $rcfilename";
    waitpid( $pid, 0 );
    warn "child is all done!";
}
else {
    my $cmd = sprintf(qq|ssh -A -p %s -t %s "/bin/bash --rcfile %s -i"|, $port, $pup->host, $rcfilename);
    #exec(qq|ssh -t tstuser\@localhost "/bin/bash --rcfile $rcfilename -i"|);
    exec($cmd);
}
