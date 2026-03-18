/*
 * Copyright 2026–present, J Wayston
 * Distributed under the MIT License (http://opensource.org/licenses/MIT)
 */

module engine;
import std::io;
import std::math::random;
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
    Check if the word is a valid word (only characters a-z). Also checks 
    that it is within length boundaries.

    @param word : "Word to be checked"
    @param len_min : "Minimum length allowed for the word"
    @param len_max : "Maximum length allowed for the word"
    @require len_min > 0, len_max >= len_min
    @return "true on valid, otherwise false"
*>
fn bool is_word_valid(String* word, usz len_min, usz len_max)
{
    if (word.len > len_max || word.len < len_min) return false;
    foreach(c : word) if (!c.is_alpha()) return false;
    return true;
}

<*
    Takes user input. On invalid input, repeats until valid is got. Validity
    is judged by the max and min lengths and that the word contains only
    characters a-z.

    @param prompt : "Prompt shown before user input"
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
        if (is_word_valid(&input, len_min, len_max)) return input;
		io::printf("Invalid input \x1b[1F\x1b[2K");
	}
}

<*
    Picks random word from a text file. Every word must be separated by newline.
    Only word that meets requirements is returned succesfully, otherwise
    INVALID_WORD~. Requirements are word_len and that the word consists of only
    characters a-z.

    @param filename : "File path"
    @param word_len : "Length that the word must be"
    @require word_len > 0
    @return "Word that meets the requirements"
*>
fn String? trandom_word_from_file(String* filename, usz word_len)
{
    char[]? file_data = file::load(tmem, *filename);
    if (catch err = file_data) return err~;

    // Split content to slices that represent lines in the file
    String file_content = (String)file_data;
    String[] file_content_lines = file_content.split(tmem, "\n");

    // Pick random line and return
    uint word_no = random::rand(file_content_lines.len - 1);
    String result = file_content_lines[word_no].copy(tmem);
    return is_word_valid(&result, word_len, word_len) ? result : INVALID_WORD~;
}

<*
    Init the game.

    @param alloc : "Allocator used outside of temporary allocations"
    @param word_len : "Word length that word lists and user inputs must obey"
    @return "err~ on any failures"
*>
fn void? Game.init(&self, Allocator* alloc, usz word_len)
{
    assert(word_len > 1, "Word length must be meaningful ( > 1 )");
    String word_file = "wordlist.txt";
    self.alloc = alloc;

    @pool()
    {
        String? word = trandom_word_from_file(&word_file, word_len);
        if (catch err = word) return err~;
        self.word = word.copy(*alloc);
    };
    self.hit_mask.init(*alloc, word_len);

    self.round = 1;
    mem::set(&self.used_chars, ' ', self.used_chars.len);
    self.word_len = word_len;
    self.word.convert_to_upper();

    io::printfn("%s W %s R %s O %s D %s L %s E %s\n",
                Color.GREEN.ansi, Color.GRAY.ansi, Color.GRAY.ansi,
                Color.YELLOW.ansi, Color.GRAY.ansi, Color.YELLOW.ansi,
                Color.RESET.ansi);
    io::printfn("Try to guess the %d-letter word. After each attempt, you will"
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
    used.free();
    return false;
}

<*
    Print characters that has been used in guesses so far and colorize them
    according to their state (HIT, MISS, WRONG)
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
    Print user guess and colorize the characters according to their state (HIT,
    MISS, WRONG)
*>
fn void Game.print_guess(&self)
{
    assert(self.hit_mask.is_initialized(), "self.hit_mask is not initialized()");
    assert(!self.hit_mask.is_empty(), "self.hit_mask must be set");
    assert(self.guess, "self.guess is not initialized");

	for (usz i = 0; i < self.word_len; i++)
	{
		io::printf("%s %c %s", self.hit_mask[i].color.ansi, self.guess[i], Color.RESET.ansi);
	}

    io::print("     ");
    self.print_used_chars();
}

<*
    Set and store guess

    @param guess : "Guess to be checked"
    @ensure guess.len == self.word_len
*>
fn void Game.tset_guess(&self, String* guess)
{
    guess.convert_to_upper();
	self.guess = guess.tcopy();
    self.round++;
}

<*
    Free non temporary allocations
*>
fn void Game.free(&self)
{
    self.word.free(*self.alloc);
    self.hit_mask.free();
}


