/*
 * Copyright 2026–present, J Wayston
 * Distributed under the MIT License (http://opensource.org/licenses/MIT)
 */

module engine;
import words;
import std::io;
import std::collections::list;

faultdef INVALID_WORD;

enum ChState : (String color)
{
	HIT   { Ansi.BG_GREEN +++ Ansi.BLACK +++ Ansi.BOLD },
	MISS  { Ansi.BG_YELLOW +++ Ansi.BLACK +++ Ansi.BOLD },
	WRONG { Ansi.BG_BRIGHT_BLACK +++ Ansi.BLACK +++ Ansi.BOLD },
}

struct Game
{
    String word;
    usz round;
}

struct Guess
{
    String word;
    List {ChState} hit_mask;
    char[26] used_chars;
}

<*
    Takes user input. On invalid input repeats asking until valid. 

    @param [in] prompt : "Prompt shown before user input"
    @param len_min : "Minimun length allowed for the user input"
    @param len_max : "Maximum length allowed for the user input"
    @require len_min > 0, len_max >= len_min

    @return "User input"
*>
fn String tuser_input(String prompt, usz len_min, usz len_max)
{
	while (1)
	{
        io::printf("%s", prompt);
		String input = io::treadline()!!;
        if (words::is_word_valid(input)) return input;
		io::printf("Invalid input or word does not exist\x1b[1F\x1b[2K");
	}
}

<*
    Init the game.
*>
fn void Game.init(&self)
{
    self.round = 1;

    self.word = words::random_word_from_list().copy(mem);
    self.word.convert_to_upper();

    io::printfn("%s W %s R %s O %s D %s L %s E %s\n",
                ChState.HIT.color, ChState.WRONG.color, ChState.WRONG.color,
                ChState.MISS.color, ChState.WRONG.color, ChState.MISS.color, Ansi.RESET);
    io::printfn("Try to guess the %d-letter word. After each attempt, you will "
                "receive hints indicating how close you were.\n", self.word.len);
}

fn void Guess.init(&self)
{
    mem::set(&self.used_chars, ' ', self.used_chars.len);
}

<*
    Set and store guess

    @param [in] guess : "Guess to be checked"
    @ensure guess.len == self.word.len
*>
fn void Guess.set(&self, String guess)
{
    if (self.word) self.word.free(mem);
    if (!self.hit_mask.is_initialized()) self.hit_mask.init(mem, guess.len);

	self.word = guess.copy(mem);
    self.word.convert_to_upper();
}

<*
    Check stored guess against given word and set self.used_chars and 
    self.hit_mask accordingly

    @param [in] against : "Word to check the guess against"
    @ensure against.len == self.word.len

    @return "True if correct guess"
*>
fn bool Guess.tcheck(&self, String against)
{

    List {bool} used;
    used.tinit(self.word.len);
    usz hit_count = 0;

	// Find exact matches
    foreach (i, c : self.word)
	{
        used.insert_at(i, false);
		self.hit_mask.insert_at(i, WRONG);

		if (self.word[i] != against[i]) continue;

        self.used_chars[self.word[i] - 65] = 'H'; 
        self.hit_mask[i] = HIT;
        used.set_at(i, true);
        hit_count++;
	}

    if (hit_count == self.word.len) return true;

	// Find correct characters but in wrong places
	for (usz i = 0; i < self.word.len; i++)
	{
		if (self.hit_mask[i] == HIT) continue;

		for (usz j = 0; j < self.word.len; j++)
		{
            if (used[j]) continue;
            self.used_chars[self.word[i] - 65] = 'W'; 
			if (self.word[i] != against[j]) continue;

            self.used_chars[self.word[i] - 65] = 'M'; 
            used[j] = true;
            self.hit_mask[i] = MISS;
            break;
		}
	}
    return false;
}

<*
    Print user guess and colorize the characters according to their state
    (HIT, MISS, WRONG)

    @require self.hit_mask.is_initialized() : "hit_mask is not initialized"
    @require !self.hit_mask.is_empty() : "hit_mask must be set"
*>
fn void Guess.print(&self)
{
	for (usz i = 0; i < self.word.len; i++)
	{
		io::printf("%s %c %s", self.hit_mask[i].color, self.word[i], Ansi.RESET);
	}

    io::print("     ");
    self.print_used_chars();
}

<*
    Print characters that has been used in guesses so far and colorize them
    according to their current state (HIT, MISS, WRONG)
*>
fn void Guess.print_used_chars(&self)
{
    io::print("[");
    for (usz i = 0; i < self.used_chars.len; i++)
    {
        switch (self.used_chars[i])
        {
            case ' ': io::printf(" %c ", 65 + i);
            case 'H': io::printf("%s %c ", ChState.HIT.color, 65 + i);
            case 'M': io::printf("%s %c ", ChState.MISS.color, 65 + i);
            case 'W': io::printf("%s %c ", ChState.WRONG.color, 65 + i);
        }
        io::printf("%s", Ansi.RESET);
    }
    io::printn("]");
}

<*
    Free object's allocations
*>
fn void Guess.free(&self)
{
    self.word.free(mem);
    self.hit_mask.free();
}

<*
    Free object's allocations
*>
fn void Game.free(&self)
{
    self.word.free(mem);
}


