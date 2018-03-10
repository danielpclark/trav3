require "test_helper"

class Trav3Test < Minitest::Test
  def test_options_test
    opts = Trav3::Options.new()
    opts.build(a: :b, c: :d)
    assert_equal "?a=b&c=d", opts.to_s

    opts.remove(:a)
    assert_equal "?c=d", opts.to_s

    opts.build(a: :b)
    assert_equal "?c=d&a=b", opts.to_s
  end
end
