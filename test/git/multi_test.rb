require 'test_helper'

module Git
  class MultiTest < Minitest::Test
    def test_that_it_has_a_name
      refute_nil ::Git::Multi::NAME
    end

    def test_that_it_has_a_version_number
      refute_nil ::Git::Multi::VERSION
    end

    def test_it_does_something_useful
      assert true # you better believe it!
    end
  end
end
