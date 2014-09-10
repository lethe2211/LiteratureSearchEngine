# -*- coding: utf-8 -*-

=begin
頻度ベクトル({"word1" => freq1, "word2" => freq2}の形式で渡される)に対する類似度計算を行うクラス
=end

class SimilarityCalculator

  STOPWORDS = ["a", "about", "above", "above", "across", "after", "afterwards", "again", "against", "all", "almost", "alone", "along", "already", "also","although","always","am","among", "amongst", "amoungst", "amount",  "an", "and", "another", "any","anyhow","anyone","anything","anyway", "anywhere", "are", "around", "as",  "at", "back","be","became", "because","become","becomes", "becoming", "been", "before", "beforehand", "behind", "being", "below", "beside", "besides", "between", "beyond", "bill", "both", "bottom","but", "by", "call", "can", "cannot", "cant", "co", "con", "could", "couldnt", "cry", "de", "describe", "detail", "do", "done", "down", "due", "during", "each", "eg", "eight", "either", "eleven","else", "elsewhere", "empty", "enough", "etc", "even", "ever", "every", "everyone", "everything", "everywhere", "except", "few", "fifteen", "fify", "fill", "find", "fire", "first", "five", "for", "former", "formerly", "forty", "found", "four", "from", "front", "full", "further", "get", "give", "go", "had", "has", "hasnt", "have", "he", "hence", "her", "here", "hereafter", "hereby", "herein", "hereupon", "hers", "herself", "him", "himself", "his", "how", "however", "hundred", "ie", "if", "in", "inc", "indeed", "interest", "into", "is", "it", "its", "itself", "keep", "last", "latter", "latterly", "least", "less", "ltd", "made", "many", "may", "me", "meanwhile", "might", "mill", "mine", "more", "moreover", "most", "mostly", "move", "much", "must", "my", "myself", "name", "namely", "neither", "never", "nevertheless", "next", "nine", "no", "nobody", "none", "noone", "nor", "not", "nothing", "now", "nowhere", "of", "off", "often", "on", "once", "one", "only", "onto", "or", "other", "others", "otherwise", "our", "ours", "ourselves", "out", "over", "own","part", "per", "perhaps", "please", "put", "rather", "re", "same", "see", "seem", "seemed", "seeming", "seems", "serious", "several", "she", "should", "show", "side", "since", "sincere", "six", "sixty", "so", "some", "somehow", "someone", "something", "sometime", "sometimes", "somewhere", "still", "such", "system", "take", "ten", "than", "that", "the", "their", "them", "themselves", "then", "thence", "there", "thereafter", "thereby", "therefore", "therein", "thereupon", "these", "they", "thickv", "thin", "third", "this", "those", "though", "three", "through", "throughout", "thru", "thus", "to", "together", "too", "top", "toward", "towards", "twelve", "twenty", "two", "un", "under", "until", "up", "upon", "us", "very", "via", "was", "we", "well", "were", "what", "whatever", "when", "whence", "whenever", "where", "whereafter", "whereas", "whereby", "wherein", "whereupon", "wherever", "whether", "which", "while", "whither", "who", "whoever", "whole", "whom", "whose", "why", "will", "with", "within", "without", "would", "yet", "you", "yours", "yourself", "yourselves", "the"]

  # ストップワードを除く
  def self.remove_stopwords(vector)
    vector.each do |word, freq|
      if STOPWORDS.include?(word)
        vector.delete(word)
      end
    end
  end

  # 頻度ベクトルのL2ノルムを求める
  def self.l2norm(vector)
    square_sum = 0
    vector.each do |word, freq|
      square_sum += freq ** 2
    end
    norm = Math.sqrt(square_sum)
    return norm
  end

  # 頻度ベクトル間のコサイン類似度を求める
  def self.cosine_similarity(v1, v2)
    remove_stopwords(v1)
    remove_stopwords(v2)

    numerator = 0               # 分子

    v1.each do |word, freq|
      if v2.include?(word)
        numerator += v1[word] * v2[word]
      end
    end

    denominator = l2norm(v1) * l2norm(v2) # 分母

    if denominator == 0
      return 0
    else
      return numerator.quo(denominator)
    end

  end

end

if __FILE__ == $0
  puts 'コサイン類似度は' + SimilarityCalculator.cosine_similarity({'ライフハック' => 1, '骨折' => 2}, {'ライフハック' => 2, '仕事' => 1, '趣味' => 1}).to_s
end
