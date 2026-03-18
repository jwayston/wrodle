module test_engine;
import engine;

fn void is_word_valid() @test
{
    String valid_word1 = "valid";
    String valid_word2 = "VaLiD";
    String invalid_word1 = "invalid";
    String invalid_word2 = "w0rdy";
    String invalid_word3 = "pöytä";

    assert( engine::is_word_valid(&valid_word1, 5, 5) );
    assert( engine::is_word_valid(&valid_word1, 4, 7) );
    assert( engine::is_word_valid(&valid_word2, 5, 5) );
    assert( !engine::is_word_valid(&invalid_word1, 5, 5) );
    assert( !engine::is_word_valid(&invalid_word2, 5, 5) );
    assert( !engine::is_word_valid(&invalid_word3, 5, 5) );
}
