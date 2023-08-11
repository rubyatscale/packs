# typed: false

RSpec.describe Packs::CLI do
  def expect_success
    expect(Packs.const_get(:Private)).to receive(:exit_with).with(true)
  end

  def expect_failure
    expect(Packs.const_get(:Private)).to receive(:exit_with).with(false)
  end

  before do
    allow(Packs.const_get(:Private)).to receive(:exit_with)
  end

  describe '#create' do
    it 'creates a pack' do
      expect_success
      expect(Packs).to receive(:create_pack!).with(pack_name: 'packs/your_pack')
      Packs::CLI.start(['create', 'packs/your_pack'])
    end
  end

  describe '#add_dependency' do
    it 'adds a dependency' do
      expect_success
      expect(Packs).to receive(:add_dependency!).with(
        pack_name: 'packs/from_pack',
        dependency_name: 'packs/to_pack'
      )
      described_class.start(['add_dependency', 'packs/from_pack', 'packs/to_pack'])
    end
  end

  describe '#list_top_dependency_violations' do
    it 'lists the top dependency violations' do
      expect(Packs).to receive(:list_top_dependency_violations).with(
        pack_name: 'packs/your_pack',
        limit: 10
      )
      described_class.start(['list_top_dependency_violations', 'packs/your_pack'])
    end
  end

  describe '#list_top_privacy_violations' do
    it 'lists the top privacy violations' do
      expect(Packs).to receive(:list_top_privacy_violations).with(
        pack_name: 'packs/your_pack',
        limit: 10
      )
      described_class.start(['list_top_privacy_violations', 'packs/your_pack'])
    end
  end

  describe '#check' do
    context 'packs check returns success true' do
      it 'exits successfully' do
        expect_success
        expect(Packs).to receive(:check).with(
          ['packs/your_pack']
        ).and_return(true)
        described_class.start(['check', 'packs/your_pack'])
      end
    end

    context 'packs check returns success false' do
      it 'exits unsuccessfully' do
        expect_failure
        expect(PacksRust).to receive(:check).with(
          ['packs/your_pack']
        ).and_return(false)
        described_class.start(['check', 'packs/your_pack'])
      end
    end
  end

  describe '#validate' do
    context 'packs validate returns success true' do
      it 'exits successfully' do
        expect_success
        expect(PacksRust).to receive(:validate).and_return(true)
        described_class.start(['validate'])
      end
    end

    context 'packs validate returns success false' do
      it 'exits unsuccessfully' do
        expect_failure
        expect(PacksRust).to receive(:validate).and_return(false)
        described_class.start(['validate'])
      end
    end
  end
end
