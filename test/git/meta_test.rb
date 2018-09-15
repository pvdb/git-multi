# frozen_string_literal: true
require 'test_helper'

module Git
  class MetaTest < Minitest::Test
    def test_that_it_has_a_version_number
      refute_nil ::Git::Meta::VERSION
    end

    def test_it_does_something_useful
      assert true # you better believe it!
    end
  end
end
