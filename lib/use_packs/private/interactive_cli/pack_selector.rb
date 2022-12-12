# typed: strict

module UsePacks
  module Private
    module InteractiveCli
      class PackSelector
        extend T::Sig

        sig { params(prompt: TTY::Prompt, question_text: String).returns(ParsePackwerk::Package) }
        def self.single_pack_select(prompt, question_text: 'Please use space to select a pack')
          packs = ParsePackwerk.all.to_h { |t| [t.name, t] }

          pack_selection = T.let(prompt.select(
            question_text,
            packs,
            filter: true,
            per_page: 10,
            show_help: :always
          ), T.nilable(ParsePackwerk::Package))

          while pack_selection.nil?
            prompt.error(
              'No packs were selected, please select a pack using the space key before pressing enter.'
            )

            pack_selection = single_pack_select(prompt, question_text: question_text)
          end

          pack_selection
        end

        sig { params(prompt: TTY::Prompt, question_text: String).returns(T::Array[ParsePackwerk::Package]) }
        def self.single_or_all_pack_multi_select(prompt, question_text: 'Please use space to select one or more packs')
          pack_selection = T.let(prompt.multi_select(
            question_text,
            ParsePackwerk.all.to_h { |t| [t.name, t] },
            filter: true,
            per_page: 10,
            show_help: :always
          ), T::Array[ParsePackwerk::Package])

          while pack_selection.empty?
            prompt.error(
              'No packs were selected, please select one or more packs using the space key before pressing enter.'
            )

            pack_selection = single_or_all_pack_multi_select(prompt, question_text: question_text)
          end

          pack_selection
        end
      end
    end
  end
end
