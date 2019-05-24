# frozen_string_literal: true

module DruidTools
  # Overrides the Druid#tree method
  class AccessDruid < Druid
    self.prefix = 'druid'

    def tree
      @druid.scan(self.class.pattern).flatten
    end

    # all content lives in the base druid directory
    def path(extra = nil, create = false)
      result = File.join(*[base, tree].compact)
      mkdir(extra) if create && !File.exist?(result)
      result
    end
  end

  PurlDruid = AccessDruid
  StacksDruid = AccessDruid
end
