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
                , ["a=s", "activity_type"]
                , ["f=s", "form"]
	);
}


sub execute {
	my ($self, $opt, $args) = @_;

	my ($course, $topic, $story, $type, $form) = @$opt{qw/c t s a f/};
	die "course '$course'?" unless $course;
	die "topic '$topic'?" unless $topic;
	die "story '$story'?" unless $story;
	die "activity type '$type'?" unless $type;
	die "form '$form'?" unless defined $form;

	my $y = LoadFile "/home/$ENV{USER}/curriculum/$course/$topic/cards.yaml" or
		die "No cards.yaml in '$topic' dir in '$course'\n";
	my $io = io "-";
	my $intro = $y->{$story}->{$type}->{$form}->{rubric} or
		die "No '$type' rubric for '$story' story, '$form' form\n";
	$io->print( $intro );
	$io->autoflush;
}

1;
