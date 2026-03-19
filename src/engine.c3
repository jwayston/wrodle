/*
 * Copyright 2026–present, J Wayston
 * Distributed under the MIT License (http://opensource.org/licenses/MIT)
 */

module engine;
import words;
import std::io;
import std::collections::list;

faultdef INVALID_WORD;

enum Color : (String ansi)
{
    GREEN  { "\x1b[30;42m" },
    YELLOW { "\x1b[30;43m" },
    RED    { "\x1b[37;41m" },
    GRAY   { "\x1b[30;100m" },
    RESET  { "\x1b[0m" },
}

enum GuessCharState : int (Color color)
{
	HIT   { Color.GREEN },
	MISS  { Color.YELLOW },
	WRONG { Color.GRAY },
}

struct Game
{
    Allocator* alloc;
    usz word_len;
    usz round;
    String word;
    String guess;
    List {GuessCharState} hit_mask;
    char[26] used_chars;
}

<*
    Takes user input. On invalid input repeats asking until valid. 

    @param [&in] prompt : "Prompt shown before user input"
    @param len_min : "Minimun length allowed for the user input"
    @param len_max : "Maximum length allowed for the user input"
    @require len_min > 0, len_max >= len_min

    @return "User input"
*>
fn String tuser_input(String* prompt, usz len_min, usz len_max)
{
	while (1)
	{
        io::printf("%s", *prompt);
		String input = io::treadline()!!;
        if (words::is_word_valid(&input)) return input;
		io::printf("Invalid input or word does not exist\x1b[1F\x1b[2K");
	}
}

<*
    Init the game.

    @param [&in] alloc : "Allocator used outside of temporary allocations"
    @param word_len : "Word length that word lists and user inputs must obey"
    @require word_len > 1 : "Must be meaningful word length"

    @return "err~ on any failures"
*>
fn void? Game.init(&self, Allocator* alloc, usz word_len)
{
    self.alloc = alloc;
    self.round = 1;

    mem::set(&self.used_chars, ' ', self.used_chars.len);
    self.word_len = word_len;
    self.word = words::random_word_from_list().copy(*alloc);
    self.word.convert_to_upper();

    io::printfn("%s W %s R %s O %s D %s L %s E %s\n",
                Color.GREEN.ansi, Color.GRAY.ansi, Color.GRAY.ansi,
                Color.YELLOW.ansi, Color.GRAY.ansi, Color.YELLOW.ansi,
                Color.RESET.ansi);
    io::printfn("Try to guess the %d-letter word. After each attempt, you will "
                "receive hints indicating how close you were.\n", self.word_len);
}

<*
    Check stored guess and set self.used_chars and self.hit_mask accordingly

    @return "True if self.guess == self.word (i.e. correct guess)"
*>
fn bool Game.tcheck_guess(&self)
{
    List {bool} used;
    used.tinit(self.word_len);
    self.hit_mask.tinit(self.word_len);
    usz hit_count = 0;

	// Find exact matches
	for (usz i = 0; i < self.word_len; i++)
	{
        used.insert_at(i, false);
		self.hit_mask.insert_at(i, WRONG);

		if (self.guess[i] != self.word[i]) continue;

        self.used_chars[self.guess[i] - 65] = 'H'; 
        self.hit_mask[i] = HIT;
        used.set_at(i, true);
        hit_count++;
	}

    if (hit_count == self.word_len) return true;

	// Find correct characters but in wrong places
	for (usz i = 0; i < self.word_len; i++)
	{
		if (self.hit_mask[i] == HIT) continue;

		for (usz j = 0; j < self.word_len; j++)
		{
            if (used[j]) continue;
            self.used_chars[self.guess[i] - 65] = 'W'; 
			if (self.guess[i] != self.word[j]) continue;

            self.used_chars[self.guess[i] - 65] = 'M'; 
            used[j] = true;
            self.hit_mask[i] = MISS;
            break;
		}
	}
    return false;
}

<*
    Print characters that has been used in guesses so far and colorize them
    according to their current state (HIT, MISS, WRONG)
*>
fn void Game.print_used_chars(&self)
{
    io::print("[");
    for (usz i = 0; i < self.used_chars.len; i++)
    {
        switch (self.used_chars[i])
        {
            case ' ':
                io::printf(" %c ", 65 + i);
            case 'H':
                io::printf("%s %c ", GuessCharState.HIT.color.ansi, 65 + i);
            case 'M':
                io::printf("%s %c ", GuessCharState.MISS.color.ansi, 65 + i);
            case 'W':
                io::printf("%s %c ", GuessCharState.WRONG.color.ansi, 65 + i);
        }
        io::printf("%s", Color.RESET.ansi);
    }
    io::printn("]");
}

<*
    Print user guess and colorize the characters according to their state
    (HIT, MISS, WRONG)

    @require self.hit_mask.is_initialized() : "hit_mask is not initialized"
    @require !self.hit_mask.is_empty() : "hit_mask must be set"
*>
fn void Game.print_guess(&self)
{
	for (usz i = 0; i < self.word_len; i++)
	{
		io::printf("%s %c %s", self.hit_mask[i].color.ansi, self.guess[i], Color.RESET.ansi);
	}

    io::print("     ");
    self.print_used_chars();
}

<*
    Set and store guess

    @param [&inout] guess : "Guess to be checked"
    @ensure guess.len == self.word_len
*>
fn void Game.set_guess(&self, String* guess)
{
    self.guess.free(*self.alloc);
    guess.convert_to_upper();
	self.guess = guess.copy(*self.alloc);
    self.round++;
}

<*
    Free non temporary allocations
*>
fn void Game.free(&self)
{
    self.guess.free(*self.alloc);
    self.word.free(*self.alloc);
}


