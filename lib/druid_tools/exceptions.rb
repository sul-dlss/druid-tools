# frozen_string_literal: true

module DruidTools
  class SameContentExistsError < RuntimeError; end
  class DifferentContentExistsError < RuntimeError; end
  class InvalidDruidError < RuntimeError; end
end
