# typed: strict

require 'colorized_string'

module UsePackwerk
  module Logging
    extend T::Sig

    sig { params(title: String, block: T.proc.void).void }
    def self.section(title, &block)
      print_divider
      puts ColorizedString.new("#{title}").green.bold
      puts "\n"
      yield
    end

    sig { params(text: String).void }
    def self.print_bold_green(text)
      puts ColorizedString.new(text).green.bold
    end

    sig { params(text: String).void }
    def self.print(text)
      puts text
    end

    sig { void }
    def self.print_divider
      puts '=' * 100
    end
  end
end

