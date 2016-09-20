package YAML2GIFT::Command::encode;

use lib "lib";

use YAML2GIFT -command;
use strict;
use warnings;
use YAML qw/Dump LoadFile DumpFile/;
use IO::All;

sub abstract { "Convert drbean's YAML quiz questions to Moodle GIFT format" }
sub description { "Convert drbean's YAML quiz questions to Moodle GIFT format" }

sub usage_desc { "yaml2gift encode -c news -t people -s kiss -f 0" }

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

	my $yaml = LoadFile "/home/drbean/class/$opt->{c}/$opt->{t}/cards.yaml";

	my $story = $yaml->{$opt->{s}}->{jigsaw}->{$opt->{f}};
	my $quiz = $story->{quiz};

	my $gift = "// Auto generated for the '$opt->{c}' course, '$opt->{t}' topic, '$opt->{s}' story, '$opt->{f}' form\n";
	$gift .= "// identifier: $story->{identifier}\n";
	# $gift .= "::Jigsaw cards::\n";
	# $gift .= "A: $story->{A}\n";
	# $gift .= "B: $story->{B}\n";
	# $gift .= "C: $story->{C}\n";
	$gift .= "\n";
	my $n = 0;
	for my $item ( @$quiz ) {
		$n++;
		my $question = $item->{question};
		my $answer = $item->{answer};
		$gift .= ":: $opt->{t} $opt->{s} $opt->{f} Question $n :: $question {\n";
		if ( defined $item->{option} ) {
			my $option = $item->{option};
				for my $alternative ( @$option ) {
				if ( $answer eq $alternative ) {
					$gift .= "= $alternative\n";
				}
				else { $gift .= "~ $alternative\n" }
			}
		}
		else { $gift .= uc $answer . "\n"}
		$gift .= "}\n\n";
	}

	io('-')->print( $gift );
}

1;
