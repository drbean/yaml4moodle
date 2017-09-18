package YAML4Moodle::Command::xml;

use lib "lib";

use YAML4Moodle -command;
use strict;
use warnings;
use YAML qw/Dump LoadFile DumpFile/;
use IO::All;
use XML::DOM;


sub abstract { "Convert drbean's YAML quiz questions to Moodle xml format" }
sub description { "Convert drbean's YAML quiz questions to Moodle xml format" }

sub usage_desc { "yaml4moodle xml -c news -t people -s kiss -q jigsaw -f 0" }

sub opt_spec  {
        return (
                ["c=s", "course"]
                , ["t=s", "topic"]
                , ["s=s", "story"]
                , ["q=s", "quiz"]
                , ["f=s", "form"]
	);
}


sub execute {
	my ($self, $opt, $args) = @_;

	my ($course, $topic, $story, $quiz, $form) = @$opt{qw/c t s q f/};

	my $yaml = LoadFile "/home/drbean/curriculum/$opt->{c}/$opt->{t}/cards.yaml";

	my @story;
	if ( $story eq 'all' ) {
		delete $yaml->{genre};
		@story = keys %$yaml;
	}
	else { @story = $story; }
	my $xml = '<?xml version="1.0" encoding="UTF-8"?>';

	my $q = XML::DOM::Document->createElement("quiz");
	my $qn = XML::DOM::Document->createElement("question");
	$qn->setAttribute("type","category");
	my $cat = XML::DOM::Document->createElement("category");
	my $text = XML::DOM::Document->createElement("text");
	$text->addText("$topic/$story");
	$cat->appendChild($text);
	$qn->appendChild($cat);
	$q->appendChild($qn);

	my $Course = ucfirst $course;

	unless ( $quiz ) {
		my $story_content = $yaml->{$story};
		my @story_keys = keys %$story_content;
		$quiz = shift @story_keys;
	}
	for my $story ( @story ) {
		my @form;
		my $content = $yaml->{$story}->{$quiz};
		if ( $form eq 'all' ) {
			@form = keys %$content;
		}
		else { @form = $form }
		if ( $quiz eq "jigsaw" ) {
			for my $form ( @form ) {
				my $quiz = $content->{$form}->{quiz};

				my $n = "00";
				for my $item ( @$quiz ) {
					++$n;
					my $question = $item->{question};
					my $answer = $item->{answer};
					die "Not a jigsaw multiple choice. No question, answer."
						unless $question && $answer;
					my $prefix = substr $question, 0, 15;
					my $qn = XML::DOM::Document->createElement("question");
					my $name = XML::DOM::Document->createElement("name");
					my $text = XML::DOM::Document->createElement("text");
					$text->addText("$story $form  Qn $n: $prefix");
					$name->appendChild( $text);
					$qn->appendChild( $name);

					my $qntext = XML::DOM::Document->createElement("questiontext");
					$text = XML::DOM::Document->createElement("text");
					$text->addText($question);
					$qntext->appendChild($text);
					$qn->appendChild($qntext);

					if ( defined $item->{option} ) {
						my $option = $item->{option};
						if ( $#$option == 0 ) {
							$qn->setAttribute("type","shortanswer");
						}
						elsif ( $#$option > 0 ) {
							$qn->setAttribute("type","multichoice");
						}
						else { die "options malformed."}
						for my $alternative ( @$option ) {
							my $a = XML::DOM::Document->createElement("answer");
							if ( $answer eq $alternative ) {
								$a->setAttribute("fraction", "100");
							}
							else { $a->setAttribute("fraction", "50");
							}
							my $text = XML::DOM::Document->createElement("text");
							$text->addText($alternative);
							$a->appendChild($text);
							$qn->appendChild($a);
						}
					}
					else {
						$qn->setAttribute("type","truefalsegroup");
						my $a = XML::DOM::Document->createElement("answer");
						$a->setAttribute("fraction", "100");
						$text = XML::DOM::Document->createElement("text");
						$text->addText($answer);
						$a->appendChild($text);
						$qn->appendChild($a);
					}
					$q->appendChild($qn);
				}
				$xml .= $q->toString;
			}
		}
		elsif ( $quiz eq "match" ) {
			for my $form ( @form ) {
				my $pairs = $content->{$form}->{pair};
				die "Not a match. No pair."
					unless $pairs;
				my $n = "00";
				my $prefix = substr $pairs->[0]->[1], 0, 15;
				$xml .= "";
				my $qn = XML::DOM::Document->createElement("question");
				$qn->setAttribute("type","matching");
				my $name = XML::DOM::Document->createElement("name");
				my $text = XML::DOM::Document->createElement("text");
				$text->addText("$story $quiz $form  Qn $n: $prefix :: Match.");
				$name->appendChild( $text);
				$qn->appendChild( $name);

				my $qntext = XML::DOM::Document->createElement("questiontext");
				$text = XML::DOM::Document->createElement("text");
				$text->addText( "Match: ");
				$qntext->appendChild($text);
				$qn->appendChild($qntext);

				$qntext = XML::DOM::Document->createElement("shuffleanswers");
				$text = XML::DOM::Document->createElement("text");
				$text->addText( "false");
				$qntext->appendChild($text);
				$qn->appendChild($qntext);

				for my $pair ( @$pairs ) {
					++$n;
					my $prompt = $pair->[0];
					my $answer = $pair->[1];

					my $subqn = XML::DOM::Document->createElement("subquestion");
					my $text = XML::DOM::Document->createElement("text");
					$text->addText($prompt);
					$subqn->appendChild($text);
					my $a = XML::DOM::Document->createElement("answer");
					$text = XML::DOM::Document->createElement("text");
					$text->addText($answer);
					$a->appendChild($text);
					$subqn->appendChild($a);
					$qn->appendChild($subqn);
				}
				$q->appendChild($qn);
			}
			$xml .= $q->toString;
		}
		elsif ( $quiz eq "scramble" ) {
			for my $form ( @form ) {
				my $sentences = $content->{$form}->{sentence};
				die "Not a scramble. No sentence."
					unless $sentences;
				my $n = "00";
				for my $sentence ( @$sentences ) {
					++$n;
					my $prefix = substr $sentence, 0, 15;
					my $qn = XML::DOM::Document->createElement("question");
					$qn->setAttribute("type","matching");
					my $name = XML::DOM::Document->createElement("name");
					my $text = XML::DOM::Document->createElement("text");
					$text->addText("$story $form  Qn $n: $prefix scramble");
					$name->appendChild( $text);
					$qn->appendChild( $name);

					my $qntext = XML::DOM::Document->createElement("questiontext");
					$text = XML::DOM::Document->createElement("text");
					$text->addText( "Unscramble: ");
					$qntext->appendChild($text);
					$qn->appendChild($qntext);

					$qntext = XML::DOM::Document->createElement("shuffleanswers");
					$text = XML::DOM::Document->createElement("text");
					$text->addText( "false");
					$qntext->appendChild($text);
					$qn->appendChild($qntext);

					my @word = split '\s', $sentence;
					my $m = "00";
					for my $word ( @word ) {
						++$m;
						my $subqn = XML::DOM::Document->createElement("subquestion");
						my $text = XML::DOM::Document->createElement("text");
						$text->addText($m);
						$subqn->appendChild($text);
						my $a = XML::DOM::Document->createElement("answer");
						$text = XML::DOM::Document->createElement("text");
						$text->addText($word);
						$a->appendChild($text);
						$subqn->appendChild($a);
						$qn->appendChild($subqn);
					}
					$q->appendChild($qn);
				}
			}
			$xml .= $q->toString;
		}
		elsif ( $quiz eq "drag" ) {
			for my $form ( @form ) {
				my $sentences = $content->{$form}->{sentence};
				my $cloze = $content->{$form}->{clozed};
				my @word = split /(\s+|\.|,)/, $sentences;
				my @string = split /\|/, $cloze;
				$xml .= "// identifier: $content->{$form}->{identifier}\n";
				$xml .= "\n";
				my @question;
				my @answer;
				my $n = "0";
				my $match;
				$match = shift @string;
				for my $word ( @word ) {
					if ( $match eq $word ) {
						$n++;
						push @question, "[[$n]]";
						$match = shift @string;
						push @answer, $word;
					}
					else {
						push @question, $word;
					} 
				}
				my $question = join "", @question;
				my $answer = join "\t", @answer;
				$xml .= $question . "\n\n" . $answer;
			}
		}
	}
	$xml > io("-");

}

1;
