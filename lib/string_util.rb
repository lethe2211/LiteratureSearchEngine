# -*- coding: utf-8 -*-

=begin
文字列に対してアレコレやるクラス
=end

class StringUtil

  def initialize
  end

  # 文字列を受け取り，含まれるホワイトスペース(タブ・全角スペースを含む)を"+"に変換して返す
  def self.space_to_plus(string)
    if string.strip! == ""
      return nil
    else
      return string.gsub(/(\s|　)+/, "+")
    end
  end

  # 区切り文字で文字列を分割し，頻度ベクトル({"word1" => freq1, "word2" => freq2}の形式)を返す
  def self.count_frequency(string, delimiter: /[[:space:]]+/)
    words = string.split(delimiter)
    freq = Hash.new(0)
    words.each do |w|
      freq[w] += 1
    end
    return freq
  end

end

if __FILE__ == $0
  puts StringUtil.count_frequency("hello \n hoge　fuga \rpiyohoge hoge")
end
