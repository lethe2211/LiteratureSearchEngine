require 'json'

class JsonCache
    
    def initialize(dir: "cache/")
        @abspath = File.dirname(__FILE__)
        @dir = dir
        @prefix = "cache_"
        @postfix = ".json"
    end

    def get(key, defValue: nil)
        filename = "/#{ @dir }#{ @prefix }#{ key.to_s }#{ @postfix }"

        if not File.exists?(@abspath + filename)
            return nil
        end

        f = open(@abspath + filename, "r")
        json = f.read
        result = JSON.parse(json)
        f.close

        return result
    end

    def set(key, value)
        filename = "/#{ @dir }#{ @prefix }#{ key.to_s }#{ @postfix }"
        open(@abspath + filename, "w") do |io|
            JSON.dump(value, io)
        end
    end

end


