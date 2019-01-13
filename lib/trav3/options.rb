module Trav3
  class Options
    def initialize(**args)
      build(**args)
    end

    def opts
      if @opts.empty?
        ''
      else
        "?#{@opts.join('&')}"
      end
    end

    def build(**args)
      @opts ||= []

      args.each do |(key, value)|
        remove(key)
        @opts.push("#{key}=#{value}")
      end

      self
    end

    def remove(key)
      @opts = @opts.keep_if do |item, _|
        !(/^#{key}=/.match? item.to_s)
      end
    end

    def +(other)
      raise ArgumentError, 'Invalid type provided.' unless other.is_a?(Options)

      @opts += other.instance_variable_get(:@opts)

      self
    end

    def to_s
      opts
    end

    def to_h
      @opts.map { |item| item.split('=') }.to_h
    end
  end
end
