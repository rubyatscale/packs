# typed: strict

require 'rainbow'

module Packs
  module Logging
    extend T::Sig

    sig { params(title: String, block: T.proc.void).void }
    def self.section(title, &block)
      print_divider
      out Rainbow(title).green.bold
      out "\n"
      yield
    end

    sig { params(text: String).void }
    def self.print_bold_green(text)
      out Rainbow(text).green.bold
    end

    sig { params(text: String).void }
    def self.print(text)
      out text
    end

    sig { void }
    def self.print_divider
      out '=' * 100
    end

    sig { params(str: String).void }
    def self.out(str)
      puts str
    end
  end
end
