/*
 * Copyright 2026–present, J Wayston
 * Distributed under the MIT License (http://opensource.org/licenses/MIT)
 */

module wrodle;
import std::io;
import std::math::random;
import engine;

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

	Game g;
    g.init(&alloc, 5);
    defer g.free();

	for (usz i = 0; i < GUESSES_MAX; i++) { @pool() 
    {
        String prompt = string::tformat("Guess %s: ", g.round);
		String input = engine::tuser_input(&prompt, g.word_len, g.word_len);

        g.set_guess(&input);
		if (g.tcheck_guess())
        {
            g.print_guess();
            io::printn("\nCorrect answer!");
            break;
        }

        g.print_guess();
	}; }

    io::printn("Press enter to quit. ");
    io::stdin().read_byte()!!;
	return 0;
}
