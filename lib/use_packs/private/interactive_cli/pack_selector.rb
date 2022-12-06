# typed: strict

module UsePacks
  module Private
    module InteractiveCli
      class PackSelector
        extend T::Sig

        sig { params(prompt: TTY::Prompt, question_text: String).returns(ParsePackwerk::Package) }
        def self.single_pack_select(prompt, question_text: 'Please use space to select a pack')
          packs = ParsePackwerk.all.to_h { |t| [t.name, t] }
          prompt.select(
            question_text,
            packs,
            filter: true,
            per_page: 10,
            show_help: :always
          )
        end

        sig { params(prompt: TTY::Prompt, question_text: String).returns(T::Array[ParsePackwerk::Package]) }
        def self.single_or_all_pack_multi_select(prompt, question_text: 'Please use space to select one or more packs')
          prompt.multi_select(
            question_text,
            ParsePackwerk.all.to_h { |t| [t.name, t] },
            filter: true,
            per_page: 10,
            show_help: :always
          )
        end
      end
    end
  end
end
