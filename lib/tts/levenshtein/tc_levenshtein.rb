require_relative "levenshtein"
require "test/unit"


class TestLevenshteinDistance < Test::Unit::TestCase

  def setup
    @sentence = "Hello my name is John Doe".split(/\W+/)
  end

  def test_dummy
    assert_equal(0, levenshtein(@sentence, @sentence))
  end

  def test_mutation
    sentence = "Hello my name is Jane Doe".split(/\W+/)
    assert_equal(1, levenshtein(@sentence, sentence))
  end

  def test_addition
    sentence = "Hello my full name is John Doe".split(/\W+/)
    assert_equal(1, levenshtein(@sentence, sentence))
  end

  def test_deletion
    sentence = "Hello name is John Doe".split(/\W+/)
    assert_equal(1, levenshtein(@sentence, sentence))
  end

  def test_complex
    sentence = "Hi my name is Karl".split(/\W+/)
    assert_equal(3, levenshtein(@sentence, sentence))
  end
end


class TestLevenshteinAligment < Test::Unit::TestCase

  def setup
    @sentence = "Hello my name is John Doe".split(/\W+/)
  end

  def test_dummy
    assert_equal([SAME] * 6, get_levenshtein_ops(@sentence, @sentence))
  end

  def test_mutation
    sentence = "Hello my name is Jane Doe".split(/\W+/)
    assert_equal([SAME, SAME, SAME, SAME, DIFF, SAME], get_levenshtein_ops(@sentence, sentence))
  end

  def test_addition
    sentence = "Hello my full name is John Doe".split(/\W+/)
    assert_equal([SAME, SAME, ADD, SAME, SAME, SAME, SAME], get_levenshtein_ops(@sentence, sentence))
  end

  def test_deletion
    sentence = "Hello name is John Doe".split(/\W+/)
    assert_equal([SAME, DEL, SAME, SAME, SAME, SAME], get_levenshtein_ops(@sentence, sentence))
  end

  def test_complex
    sentence = "Hi my name is Karl".split(/\W+/)
    assert_equal([DIFF, SAME, SAME, SAME, DEL, DIFF], get_levenshtein_ops(@sentence, sentence))
  end
end
