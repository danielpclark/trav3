module Trav3
  class Options
    def initialize(**args)
      build(**args)
    end

    def opts
      if @opts.empty?
        ""
      else
        "?#{@opts.join('&')}"
      end
    end

    def build(**args)
      @opts ||= []

      for (key, value) in args
        remove(key)
        @opts.push(pb[key, value])
      end
    end

    def remove(key)
      @opts = @opts.keep_if {|a, _| (eval ki)[a] }
    end

    def +(other)
      raise ArgumentError, "Invalid type provided." unless other.is_a?(Options)
      @opts += other.instance_variable_get(:@opts)
    end

    def to_s
      opts
    end

    def pb
      lambda {|param, arg| "#{param}=#{arg}" }
    end
    private :pb

    def ki
      'lambda {|item| !(/^#{key}=/ === "#{item}") }'
    end
    private :ki
  end
end
