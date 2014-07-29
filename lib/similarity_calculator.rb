# -*- coding: utf-8 -*-

=begin
頻度ベクトル({"word1" => freq1, "word2" => freq2}の形式で渡される)に対する類似度計算を行うクラス
=end

class SimCalculator
  
  # 頻度ベクトルのL2ノルムを求める
  def l2norm(vector)
    square_sum = 0
    vector.each do |word, freq|
      square_sum += freq ** 2
    end
    norm = Math.sqrt(square_sum)
    return norm
  end

  # 頻度ベクトル間のコサイン類似度を求める
  def cosine_similarity(v1, v2)
    numerator = 0

    v1.each do |word, freq|
      if v2.include?(word)
        numerator += v1[word] * v2[word]
      end
    end

    denominator = l2norm(v1) * l2norm(v2)

    if denominator == 0
      return 0
    else
      return numerator.quo(denominator)
    end

  end

end

if __FILE__ == $0
  sc = SimCalculator.new
  puts 'コサイン類似度は' + sc.cosine_similarity({'ライフハック' => 1, '骨折' => 2}, {'ライフハック' => 2, '仕事' => 1, '趣味' => 1}).to_s
end
