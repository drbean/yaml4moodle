package YAML4Moodle::Command::intro;

use lib "lib";

use YAML4Moodle -command;
use strict;
use warnings;
use YAML qw/Dump LoadFile DumpFile/;
use IO::All;


sub abstract { "Create file for Moodle intro text from cards.yaml" }
sub description { "Frequent use transfering intro text from essay rubric in cards.yaml" }

sub usage_desc { 'yaml4moodle intro -t read -s vacation -f 0' }

sub opt_spec  {
        return (
                ["c=s", "course"]
                , ["t=s", "topic"]
                , ["s=s", "story"]
                , ["f=s", "form"]
	);
}


sub execute {
	my ($self, $opt, $args) = @_;

	my ($course, $topic, $story, $form) = @$opt{qw/c t s f/};
	die "description course '$course'?" unless $course;
	die "description topic '$topic'?" unless $topic;
	die "description story '$story'?" unless $story;
	die "description form '$form'?" unless defined $form;

	my $y = LoadFile "/home/drbean/curriculum/$course/$topic/cards.yaml";
	my $io = io "$topic/intro.txt";
	$io->print( $y->{$story}->{essay}->{$form}->{rubric}  );
	$io->autoflush;
}

1;
