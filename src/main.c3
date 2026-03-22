/*
 * Copyright 2026–present, J Wayston
 * Distributed under the MIT License (http://opensource.org/licenses/MIT)
 */

module wrodle;

import engine;
import words;
import std::io;

const usz GUESSES_MAX = 6;

fn void banner()
{
    io::printfn("%s W %s R %s O %s D %s L %s E %s\n",
                ChState.HIT.color, ChState.WRONG.color, ChState.WRONG.color,
                ChState.MISS.color, ChState.WRONG.color, ChState.MISS.color,
                Ansi.RESET);
    io::printfn("Try to guess the %d-letter word. After each attempt, you will "
                "receive hints indicating how close you were. You have %d "
                "guesses.\n", words::WORDLEN, GUESSES_MAX); 
}

fn int main(String[] args)
{
    // ┌──────────────────────────────────────────────────────────────────┐
    // │ UNCOMMENT BELOW TO ENABLE MEMORY TRACKING FOR DEBUGGING PURPOSES │
    // └──────────────────────────────────────────────────────────────────┘
    // mem::@report_heap_allocs_in_scope() 
    {
	Game game;
    game.init();
    defer game.free();

    Guess guess;
    guess.init();
    defer guess.free();

    banner();

    // Game loop
    while (game.round <= GUESSES_MAX) { @pool() 
    {
        String prompt = string::tformat("Guess %s: ", game.round);
		String input = engine::tuser_input(prompt, words::WORDLEN, words::WORDLEN);

        guess.set(input);
		if (guess.tcheck(game.word))
        {
            guess.print();
            io::printn("\nCorrect answer!");
            break;
        }

        guess.print();
        game.round++;
	}; }

    };
    io::printn("Press enter to quit. ");
    io::stdin().read_byte()!!;
	return 0;
}
