class StatusJsonCache < JsonCache
  def initialize(dir: "cache/", prefix: "cache", postfix: ".json", statusmsg: "status", datamsg: "data", okmsg: "OK", ngmsg: "NG")
    super(dir, prefix, postfix)
    @statusmsg = statusmsg
    @okmsg = okmsg
    @ngmsg = ngmsg
  end

  def get(key, def_value: nil)
    relpath = "/#{ @dir }#{ @prefix }#{ key.to_s }#{ @postfix }"

    if not File.exists?(@abspath + relpath)
      return def_value
    else
      f = open(@abspath + relpath, "r")
      json = f.read
      result = JSON.parse(json)
      f.close

      if result[@statusmsg] == @okmsg
        return result[@datamsg]
      else
        return def_value
      end
    end
  end

  def set(key, value, status)
    if status
      result = {@statusmsg => @okmsg, @datamsg => value}
    else
      result = {@statusmsg => @ngmsg, @datamsg => {}}
    end

    relpath = "/#{ @dir }#{ @prefix }#{ key.to_s }#{ @postfix }"
    open(@abspath + relpath, "w") do |io|
      JSON.dump(result, io)
    end
  end
end

if __FILE__ == $0
  
end
