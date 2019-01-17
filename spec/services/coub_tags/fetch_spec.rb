describe CoubTags::Fetch do
  subject { described_class.call tags: tags, iterator: iterator }

  before do
    allow(CoubTags::CoubRequest)
      .to receive(:call)
      .with('zzz', 1)
      .and_return coubs_zzz_1

    allow(CoubTags::CoubRequest)
      .to receive(:call)
      .with('zzz', 2)
      .and_return coubs_zzz_2

    allow(CoubTags::CoubRequest)
      .to receive(:call)
      .with('zzz', 3)
      .and_return coubs_zzz_3

    allow(CoubTags::CoubRequest)
      .to receive(:call)
      .with('xxx', 1)
      .and_return coubs_xxx_1

    allow(CoubTags::CoubRequest)
      .to receive(:call)
      .with('xxx', 2)
      .and_return coubs_xxx_2

    stub_const 'CoubTags::Fetch::PER_PAGE', 2
    stub_const 'CoubTags::CoubRequest::PER_PAGE', 2
  end

  let(:coubs_zzz_1) { [] }
  let(:coubs_zzz_2) { [] }
  let(:coubs_zzz_3) { [] }

  let(:coubs_xxx_1) { [] }
  let(:coubs_xxx_2) { [] }

  let(:coub_anime_1) do
    Coub::Entry.new(
      player_url: 'coub_anime_1',
      image_url: 'coub_anime_1',
      categories: %w[anime],
      tags: %w[anime]
    )
  end
  let(:coub_anime_2) do
    Coub::Entry.new(
      player_url: 'coub_anime_2',
      image_url: 'coub_anime_2',
      categories: %w[anime],
      tags: %w[anime]
    )
  end
  let(:coub_anime_3) do
    Coub::Entry.new(
      player_url: 'coub_anime_3',
      image_url: 'coub_anime_3',
      categories: %w[anime],
      tags: %w[anime]
    )
  end
  let(:coub_not_anime_1) do
    Coub::Entry.new(
      player_url: 'coub_not_anime_1',
      image_url: 'coub_not_anime_1',
      categories: %w[gaming],
      tags: %w[]
    )
  end

  let(:iterator) { nil }

  context 'one tag' do
    let(:tags) { %w[zzz] }

    context 'no iterator' do
      context 'results from 1st coub request' do
        context 'no more results' do
          let(:coubs_zzz_1) { [coub_anime_1] }

          it do
            is_expected.to be_kind_of Coub::Results
            is_expected.to have_attributes(
              coubs: coubs_zzz_1,
              iterator: nil
            )
            expect(CoubTags::CoubRequest).to have_received(:call).once
          end
        end

        context 'has more results' do
          let(:coubs_zzz_1) { [coub_anime_1, coub_anime_2] }

          it do
            is_expected.to be_kind_of Coub::Results
            is_expected.to have_attributes(
              coubs: coubs_zzz_1,
              iterator: 'zzz:2:0'
            )
            expect(CoubTags::CoubRequest).to have_received(:call).once
          end
        end
      end

      context 'results from 2nd coub request' do
        let(:coubs_zzz_1) { [coub_anime_1, coub_not_anime_1] }
        let(:coubs_zzz_2) { [coub_anime_2] }

        context 'no more results' do
          it do
            is_expected.to be_kind_of Coub::Results
            is_expected.to have_attributes(
              coubs: [coub_anime_1, coub_anime_2],
              iterator: nil
            )
            expect(CoubTags::CoubRequest).to have_received(:call).twice
          end
        end

        context 'has more results' do
          let(:coubs_zzz_1) { [coub_anime_1, coub_not_anime_1] }
          let(:coubs_zzz_2) { [coub_anime_2, coub_anime_3] }

          it do
            is_expected.to be_kind_of Coub::Results
            is_expected.to have_attributes(
              coubs: [coub_anime_1, coub_anime_2],
              iterator: 'zzz:2:1'
            )
            expect(CoubTags::CoubRequest).to have_received(:call).twice
          end
        end
      end
    end

    describe 'has iterator' do
      context '2nd page w/o overfetched' do
        let(:iterator) { 'zzz:2:0' }

        context 'no more results' do
          let(:coubs_zzz_2) { [coub_anime_1] }

          it do
            is_expected.to be_kind_of Coub::Results
            is_expected.to have_attributes(
              coubs: coubs_zzz_2,
              iterator: nil
            )
            expect(CoubTags::CoubRequest).to have_received(:call).once
          end
        end

        context 'has more results' do
          let(:coubs_zzz_2) { [coub_anime_1, coub_anime_2] }

          it do
            is_expected.to be_kind_of Coub::Results
            is_expected.to have_attributes(
              coubs: coubs_zzz_2,
              iterator: 'zzz:3:0'
            )
            expect(CoubTags::CoubRequest).to have_received(:call).once
          end
        end
      end

      context '2nd page with overfetched' do
        let(:iterator) { 'zzz:2:1' }
        let(:coubs_zzz_2) { [coub_anime_1, coub_anime_2] }
        let(:coubs_zzz_3) { [coub_not_anime_1, coub_anime_3] }

        it do
          is_expected.to be_kind_of Coub::Results
          is_expected.to have_attributes(
            coubs: [coub_anime_2, coub_anime_3],
            iterator: 'zzz:4:0'
          )
          expect(CoubTags::CoubRequest).to have_received(:call).twice
        end
      end
    end
  end

  context 'multiple tags' do
    let(:tags) { %w[zzz xxx] }

    context 'no more results on 2nd tag' do
      let(:coubs_zzz_1) { [coub_anime_1] }
      let(:coubs_xxx_1) { [coub_anime_2] }

      it do
        is_expected.to be_kind_of Coub::Results
        is_expected.to have_attributes(
          coubs: [coub_anime_1, coub_anime_2],
          iterator: nil
        )
        expect(CoubTags::CoubRequest).to have_received(:call).twice
      end
    end

    context 'has more results on 2nd tag' do
      let(:coubs_zzz_1) { [coub_anime_1] }

      context 'overfetched' do
        let(:coubs_xxx_1) { [coub_anime_2, coub_anime_3] }

        it do
          is_expected.to be_kind_of Coub::Results
          is_expected.to have_attributes(
            coubs: [coub_anime_1, coub_anime_2],
            iterator: 'xxx:1:1'
          )
          expect(CoubTags::CoubRequest).to have_received(:call).twice
        end
      end

      context 'not overfetched' do
        let(:coubs_xxx_1) { [coub_anime_2, coub_not_anime_1] }

        it do
          is_expected.to be_kind_of Coub::Results
          is_expected.to have_attributes(
            coubs: [coub_anime_1, coub_anime_2],
            iterator: 'xxx:2:0'
          )
          expect(CoubTags::CoubRequest).to have_received(:call).twice
        end
      end
    end
  end
end