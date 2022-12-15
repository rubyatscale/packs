# typed: strict

module UsePacks
  module Private
    module InteractiveCli
      module UseCases
        class Rename
          extend T::Sig
          extend T::Helpers
          include Interface

          sig { override.returns(String) }
          def user_facing_name
            'Rename a pack'
          end

          sig { override.params(prompt: TTY::Prompt).void }
          def perform!(prompt)
            prompt.warn(<<~WARNING)
              We do not yet have an automated API for this.

              Follow these steps:
              1. Rename the `packs/your_pack` directory to the name of the new pack, `packs/new_pack_name
              2. Replace references to `- packs/your_pack` in `package.yml` files with `- packs/new_pack_name`
              3. Rerun `bin/packwerk update-todo` to update violations
              4. Run `bin/codeownership validate` to update ownership information
              5. Please let us know if anything is missing.
            WARNING
          end
        end
      end
    end
  end
end
