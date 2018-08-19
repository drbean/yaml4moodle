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

	$XML::DOM::Parser::KeepCDATA = 1;
	my $q = XML::DOM::Document->createElement("quiz");
	my $qn = XML::DOM::Document->createElement("question");
	$qn->setAttribute("type","category");
	my $cat = XML::DOM::Document->createElement("category");
	my $text = XML::DOM::Document->createElement("text");
	$text->addText("\$cat1\$/top/$topic/$story");
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
					$qntext->setAttribute("format","html");
					$text = XML::DOM::Document->createElement("text");
					my $cdata = XML::DOM::Document->createCDATASection( $question );
					$text->appendChild( $cdata );
					$qntext->appendChild( $text );
					$qn->appendChild( $qntext );

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
							die "no option?" unless $alternative;
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
					elsif ( ref $item->{answer} eq "ARRAY" ){
						$qn->setAttribute("type","regexp");
						my $generalfeedback = XML::DOM::Document->createElement("generalfeedback");
						$generalfeedback->setAttribute("format","html");
						$text = XML::DOM::Document->createElement("text");
						$generalfeedback->appendChild( $text );
						$qn->appendChild( $generalfeedback );
						my $defaultgrade = XML::DOM::Document->createElement("defaultgrade");
						$defaultgrade->addText("1");
						$qn->appendChild( $defaultgrade );
						my $penalty = XML::DOM::Document->createElement("penalty");
						$penalty->addText("0.1");
						$qn->appendChild( $penalty );
						my $usehint = XML::DOM::Document->createElement("usehint");
						$usehint->addText("0");
						$qn->appendChild( $usehint );
						my $usecase = XML::DOM::Document->createElement("usecase");
						$usecase->addText("0");
						$qn->appendChild( $usecase );
						my $studentshowalternate = XML::DOM::Document->createElement("studentshowalternate");
						$studentshowalternate->addText("0");
						$qn->appendChild( $studentshowalternate );

						my $matches = $item->{answer};
						for my $answer ( @$matches ) {
							my $a = XML::DOM::Document->createElement("answer");
							$a->setAttribute("fraction", "100");
							my $text = XML::DOM::Document->createElement("text");
							$text->addText($answer);
							$a->appendChild($text);
							my $feedback = XML::DOM::Document->createElement("feedback");
							$feedback->setAttribute("format","html");
							my $feedtext = XML::DOM::Document->createElement("text");
							$feedback->appendChild($feedtext);
							$a->appendChild($feedback);
							$qn->appendChild($a);
						}
						if ( $item->{incorrect} ) {
							my $matches = $item->{incorrect};
							for my $answer ( @$matches ) {
								my $a = XML::DOM::Document->createElement("answer");
								$a->setAttribute("fraction", "0");
								my $text = XML::DOM::Document->createElement("text");
								$text->addText($answer->{error});
								$a->appendChild($text);
								my $feedback = XML::DOM::Document->createElement("feedback");
								$feedback->setAttribute("format","html");
								my $feedtext = XML::DOM::Document->createElement("text");
								my $cdata = XML::DOM::Document->createCDATASection( $answer->{feedback} );
								$feedtext->appendChild( $cdata );
								$feedback->appendChild($feedtext);
								$a->appendChild($feedback);
								$qn->appendChild($a);
							}
						}
						my $a = XML::DOM::Document->createElement("answer");
						$a->setAttribute("fraction", "0");
						my $text = XML::DOM::Document->createElement("text");
						$text->addText( '^.*$' );
						$a->appendChild($text);
						my $feedback = XML::DOM::Document->createElement("feedback");
						$feedback->setAttribute("format","html");
						my $feedtext = XML::DOM::Document->createElement("text");
						my $cdata = XML::DOM::Document->createCDATASection( "Try again!" );
						$feedtext->appendChild( $cdata );
						$feedtext->addText( " " );
						$feedback->appendChild($feedtext);
						$a->appendChild($feedback);
						$qn->appendChild($a);

					}
					else {
						$qn->setAttribute("type","truefalse");
                                                my %opposite = ( True => "false", False => "true" );
						my $a = XML::DOM::Document->createElement("answer");
						$a->setAttribute("fraction", "100");
						$text = XML::DOM::Document->createElement("text");
						$text->addText(lc $answer);
						$a->appendChild($text);
						my $feedback = XML::DOM::Document->createElement("feedback");
						$feedback->setAttribute("format","html");
						my $feedtext = XML::DOM::Document->createElement("text");
						my $cdata = XML::DOM::Document->createCDATASection( "Correct!" );
						$feedtext->appendChild( $cdata );
						$feedtext->addText( " " );
						$feedback->appendChild($feedtext);
						$a->appendChild($feedback);
						$qn->appendChild($a);
						my $alternative = XML::DOM::Document->createElement("answer");
						$alternative->setAttribute("fraction", "0");
						$text = XML::DOM::Document->createElement("text");
						$text->addText( $opposite{$answer} );
						$alternative->appendChild($text);
						my $alt_feedback = XML::DOM::Document->createElement("feedback");
						$feedback->setAttribute("format","html");
						my $alt_feedtext = XML::DOM::Document->createElement("text");
						my $alt_cdata = XML::DOM::Document->createCDATASection( "Try again!" );
						$alt_feedtext->appendChild( $alt_cdata );
						$alt_feedtext->addText( " " );
						$alt_feedback->appendChild($alt_feedtext);
						$alternative->appendChild($alt_feedback);
						$qn->appendChild($alternative);
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
					my %dupe;
					$dupe{$_}++ for @word;
					my $m = "00";
					for my $word ( @word ) {
						++$m;
						my $subqn = XML::DOM::Document->createElement("subquestion");
						my $text = XML::DOM::Document->createElement("text");
						$text->addText($m);
						$subqn->appendChild($text);
						my $a = XML::DOM::Document->createElement("answer");
						$text = XML::DOM::Document->createElement("text");
						if ( $dupe{$word} > 1 ) {
							$word .= "_$m;"
						}
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
		elsif ( $quiz eq "description" ) {
			for my $form ( @form ) {
				my $description;
				if ( $content->{$form}->{questiontext} ) {
					$description = $content->{$form}->{questiontext};
				}
				else { die "Not a description. No questiontext." }
                                my $comment = XML::DOM::Document->createComment
                                        ("identifier: $content->{$form}->{identifier}");
                                $q->appendChild( $comment );

                                my $prefix = substr $description, 0, 15;
                                my $qn = XML::DOM::Document->createElement("question");
                                $qn->setAttribute("type","description");
                                my $name = XML::DOM::Document->createElement("name");
                                my $text = XML::DOM::Document->createElement("text");
                                $text->addText("$story $form: $prefix description");
                                $name->appendChild( $text);
                                $qn->appendChild( $name);

                                my $qntext = XML::DOM::Document->createElement("questiontext");
                                $text = XML::DOM::Document->createElement("text");
                                my $cdata_text = $description;
                                $XML::DOM::Parser::KeepCDATA = 1;
                                my $cdata = XML::DOM::Document->createCDATASection( $cdata_text );
                                $text->appendChild( $cdata );
                                $qntext->appendChild( $text );
                                $qn->appendChild( $qntext );
                                $q->appendChild($qn);

                        }
                        $xml .= $q->toString;
                }
		elsif ( $quiz eq "essay" ) {
			for my $form ( @form ) {
				my $rubric;
				if ( $content->{$form}->{rubric} ) {
					$rubric = $content->{$form}->{rubric};
				}
				else { die "Not an essay. No rubric text!!" }
                                my $comment = XML::DOM::Document->createComment
                                        ("identifier: $content->{$form}->{identifier}");
                                $q->appendChild( $comment );

                                my $prefix = substr $rubric, 0, 15;
                                my $qn = XML::DOM::Document->createElement("question");
                                $qn->setAttribute("type", "$quiz");
                                my $name = XML::DOM::Document->createElement("name");
                                my $text = XML::DOM::Document->createElement("text");
                                $text->addText("$story $form: $prefix $quiz");
                                $name->appendChild( $text);
                                $qn->appendChild( $name);

                                my $qntext = XML::DOM::Document->createElement("questiontext");
				$qntext->setAttribute("format","markdown");
                                $text = XML::DOM::Document->createElement("text");
                                my $cdata_text = $rubric;
                                $XML::DOM::Parser::KeepCDATA = 1;
                                my $cdata = XML::DOM::Document->createCDATASection( $cdata_text );
                                $text->appendChild( $cdata );
                                $qntext->appendChild( $text );
                                $qn->appendChild( $qntext );
                                $q->appendChild($qn);

				my $grade = XML::DOM::Document->createElement("defaultgrade");
				$grade->addText(9);
				$qn->appendChild($grade);

				my $penalty = XML::DOM::Document->createElement("penalty");
				$penalty->addText(0);
				$qn->appendChild($penalty);

                        }
                        $xml .= $q->toString;
                }
		elsif ( $quiz eq "drag" ) {
			for my $form ( @form ) {
				my $sentences;
				if ( $content->{$form}->{sentences} ) {
					$sentences = $content->{$form}->{sentences};
				}
				else { die "Not a drag. No sentences." }
				my $n = "00";
				for my $sentence ( @$sentences ) {
					my $words = $sentence->{sentence};
					my $cloze = $sentence->{clozed};
					my @word = split /(\s+|\.|,)/, $words;
					die "no words in $words\n" unless @word;
					my @string = split /\|/, $cloze;
					die "no clozed words in $cloze\n" unless @string;

					my $comment = XML::DOM::Document->createComment
						("identifier: $content->{$form}->{identifier}");
					$q->appendChild( $comment );

					my $prefix = substr $words, 0, 15;
					my $qn = XML::DOM::Document->createElement("question");
					$qn->setAttribute("type","ddwtos");
					my $name = XML::DOM::Document->createElement("name");
					my $text = XML::DOM::Document->createElement("text");
					$text->addText("$story $form: $prefix drag");
					$name->appendChild( $text);
					$qn->appendChild( $name);

					my $qntext = XML::DOM::Document->createElement("questiontext");
					$text = XML::DOM::Document->createElement("text");

					my $cdata_text;
					my $m = "00";
					my $n = "0";
					my @clozed;
					my %dupe;
					$dupe{$_}++ for @word;
					for my $word ( @word ) {
						++$m;
						if ( $string[0] eq $word ) {
							$n++;
							$cloze = shift @string;
							if ( $dupe{$word} > 1 ) {
								$cloze .= "_$n";
							}
							$cdata_text .= "[[$n]]";
							my $dragbox = XML::DOM::Document->createElement("dragbox");
							my $text = XML::DOM::Document->createElement("text");
							$text->addText( $cloze );
							$dragbox->appendChild( $text );
							push @clozed, $dragbox;
						}
						else { $cdata_text .= $word; }
					}
					$XML::DOM::Parser::KeepCDATA = 1;
					my $cdata = XML::DOM::Document->createCDATASection( $cdata_text );
					$text->appendChild( $cdata );
					$qntext->appendChild( $text );
					$qn->appendChild( $qntext );

					my $grade = XML::DOM::Document->createElement("defaultgrade");
					$grade->addText("3");
					$qn->appendChild($grade);

					my $shuffle = XML::DOM::Document->createElement("shuffleanswers");
					$shuffle->addText("1");
					$qn->appendChild($shuffle);

					for my $dragbox ( @clozed ) {
						$qn->appendChild( $dragbox );
					}
					$q->appendChild($qn);

				}
				$xml .= $q->toString;
			}
		}
		$xml > io("-");

	}
}

1;
