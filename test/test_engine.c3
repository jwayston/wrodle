module test_words;
import words;

fn void is_word_valid() @test
{
    String valid_word1 = "valid";
    String valid_word2 = "VaLiD";
    String invalid_word1 = "invalid";
    String invalid_word2 = "w0rdy";
    String invalid_word3 = "pöytä";

    assert(words::is_word_valid(valid_word1));
    assert(words::is_word_valid(valid_word2));
    assert(!words::is_word_valid(invalid_word1));
    assert(!words::is_word_valid(invalid_word2));
    assert(!words::is_word_valid(invalid_word3));
}
