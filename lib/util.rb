# -*- coding: utf-8 -*-
class Util

  # Filepathと可変長引数を受け取り，シェルコマンドを実行
  def self.execute_command(filepath, *args)
    command = filepath 
    args.each_with_index do |arg, i|
      command += " "
      command += arg.to_s
    end
    out, err, status = Open3.capture3(command)

    return out
  end

end
