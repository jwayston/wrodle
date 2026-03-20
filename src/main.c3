/*
 * Copyright 2026–present, J Wayston
 * Distributed under the MIT License (http://opensource.org/licenses/MIT)
 */

module wrodle;
import engine;
import words;

import std::io;
import std::math::random;

const usz GUESSES_MAX = 6;

fn int main(String[] args)
{
    Allocator alloc = mem;
    // ┌──────────────────────────────────────────────────────────────────┐
    // │ UNCOMMENT BELOW TO ENABLE MEMORY TRACKING FOR DEBUGGING PURPOSES │
    // └──────────────────────────────────────────────────────────────────┘
    // TrackingAllocator tracker;
    // tracker.init(mem);
    // defer tracker.free();
    // defer tracker.print_report();
    // alloc = &tracker;

	Game game;
    game.init(alloc);
    defer game.free();

    Guess guess;
    guess.init(alloc);
    defer guess.free();

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

    io::printn("Press enter to quit. ");
    io::stdin().read_byte()!!;
	return 0;
}
