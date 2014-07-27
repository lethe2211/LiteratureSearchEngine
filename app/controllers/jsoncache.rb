# -*- coding: utf-8 -*-
require 'json'
require 'fileutils'

=begin
JSONファイルを用いたファイルキャッシュ   
=end
class JsonCache

  def initialize(dir: "cache/", prefix: "cache_", postfix: ".json")
    @abspath = File.dirname(__FILE__)
    @dir = dir
    @prefix = prefix
    @postfix = postfix

    FileUtils.mkdir_p("#{ @abspath }/#{ @dir }") unless File.exist?("#{ @abspath }/# { @dir }") # ディレクトリがなければ作る
  end

  # 保存したキャッシュファイルをオブジェクトの形で取り出す 
  def get(key, defValue: nil)
    relpath = "/#{ @dir }#{ @prefix }#{ key.to_s }#{ @postfix }"

    if not File.exists?(@abspath + relpath)
      return defValue
    end

    f = open(@abspath + relpath, "r")
    json = f.read
    result = JSON.parse(json)
    f.close

    return result
  end

  # RubyオブジェクトをJSONに変換し，ファイルに保存する
  def set(key, value)
    relpath = "/#{ @dir }#{ @prefix }#{ key.to_s }#{ @postfix }"
    open(@abspath + relpath, "w") do |io|
      JSON.dump(value, io)
    end
  end

end


