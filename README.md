# NAME

yaml4moodle - "Convert drbean's YAML jigsaw quiz questions to Moodle formats" 

# VERSION

Version 0.01

# SYNOPSIS

	yaml4moodle <gift|xml> -c news -t people -s kiss -q jigsaw -f 0 > gift\_set.txt

# DESCRIPTION

Encoding YAML quiz section:

kiss:
  jigsaw:
    0:
      identifier: kiss 0
      A: You were arrested for creating a disturbance. The police let you go, and Mario tries to interview you, but he cannot find you. You escape the cameras.
      B: You create a disturbance by trying to kiss Mario as he is reporting the arrest of Shia for an earlier, different disturbance. You are not arrested.
      C: You are reporting the arrest of Shia. Erykah interrupts you by trying to kiss you. But you are able to avoid her and continue your report.
      quiz:
        - question: A
          option:
            - Erykah
            - Mario
            - Shia
          answer: Shia
        - question: B
          option:
            - Erykah
            - Mario
            - Shia
          answer: Erykah
        - question: C
          option:
            - Erykah
            - Mario
            - Shia
          answer: Mario
        - question: Shia is troublesome \\& is arrested.
          answer  : True
        - question: Shia gives Mario \\& Erykah trouble.
          answer  : False

becomes:

// Auto generated for the 'news' course, 'people' topic, 'kiss' story, '0' form
// identifier: kiss 0
::Jigsaw cards::
A: You were arrested for creating a disturbance. The police let you go, and Mario tries to interview you, but he cannot find you. You escape the cameras.
B: You create a disturbance by trying to kiss Mario as he is reporting the arrest of Shia for an earlier, different disturbance. You are not arrested.
C: You are reporting the arrest of Shia. Erykah interrupts you by trying to kiss you. But you are able to avoid her and continue your report.

    :: Question 1 :: A {
    ~ Erykah
    ~ Mario
    = Shia
    }
    
    :: Question 2 :: B {
    = Erykah
    ~ Mario
    ~ Shia
    }
    
    :: Question 3 :: C {
    ~ Erykah
    = Mario
    ~ Shia
    }
    
:: Question 4 :: Shia is troublesome \\& is arrested. {
TRUE
}

:: Question 5 :: Shia gives Mario \\& Erykah trouble. {
FALSE
}

# AUTHOR

Dr Bean `<drbean at cpan, then a dot, (.), and org>`

# COPYRIGHT & LICENSE

Copyright 2016 Dr Bean, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
