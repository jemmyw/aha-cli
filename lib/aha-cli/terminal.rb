require "io/console"

module AhaCli
  module Terminal
    def ask(question, echo: true)
      $stdout.write question
      $stdout.write " "

      if echo
        STDIN.gets.chomp
      else
        answer = STDIN.noecho(&:gets).chomp
        $stdout.write "\n"
        answer.chomp
      end
    end
  end
end