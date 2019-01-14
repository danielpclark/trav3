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
      return_value = nil

      @opts = @opts.keep_if do |item, value|
        if entry_match?(key, item)
          return_value = value
          false
        else
          true
        end
      end

      return_value
    end

    def reset!
      @opts = []
    end

    def +(other)
      raise TypeError, "Options type expected, #{other.class} given" unless other.is_a? Options

      @opts += other.instance_variable_get(:@opts)

      self
    end

    def to_s
      opts
    end

    def to_h
      @opts.map { |item| item.split('=') }.to_h
    end

    private

    def entry_match?(entry, item)
      (/^#{entry}=/.match? item.to_s)
    end
  end
end
