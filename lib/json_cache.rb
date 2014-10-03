# -*- coding: utf-8 -*-
require 'json'
require 'fileutils'

=begin
JSONファイルを用いたファイルキャッシュ   
=end
class JsonCache

  # dirはこのファイルからの相対パスで指定
  # TODO: ↑を呼び出し元からの相対パス指定に直したい
  def initialize(dir: "cache/", prefix: "cache_", postfix: ".json")
    @abspath = File.dirname(__FILE__)
    @dir = dir
    @prefix = prefix
    @postfix = postfix

    FileUtils.mkdir_p("#{ @abspath }/#{ @dir }") unless File.exist?("#{ @abspath }/# { @dir }") # ディレクトリがなければ作る
  end

  # 保存したキャッシュファイルをオブジェクトの形で取り出す 
  def get(key, def_value: nil, symbolize_names: false)
    relpath = "/#{ @dir }#{ @prefix }#{ key.to_s }#{ @postfix }"

    if not File.exists?(@abspath + relpath)
      return def_value
    end

    f = open(@abspath + relpath, "r")
    json = f.read
    if symbolize_names == true
      result = JSON.parse(json, symbolize_names: true)
    else
      result = JSON.parse(json)
    end
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


