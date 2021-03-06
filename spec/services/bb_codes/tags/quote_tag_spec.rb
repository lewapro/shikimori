describe BbCodes::Tags::QuoteTag do
  let(:tag) { BbCodes::Tags::QuoteTag.instance }
  subject { tag.format text }

  context 'simple quote' do
    let(:text) { '[quote]test[/quote]' }
    it { is_expected.to eq '<div class="b-quote">test</div>' }

    context 'with text' do
      let(:text) { '[quote=zz]test[/quote]' }
      it do
        is_expected.to eq(
          '<div class="b-quote">'\
            '<div class="quoteable">[user]zz[/user]</div>'\
            'test</div>'
        )
      end
    end
  end

  context 'topic quote' do
    let(:text) { '[quote=t1;2;3]test[/quote]' }
    it do
      is_expected.to eq(
        '<div class="b-quote">'\
          '<div class="quoteable">[topic=1 quote]3[/topic]</div>'\
          'test</div>'
      )
    end
  end

  context 'message quote' do
    let(:text) { '[quote=m1;2;3]test[/quote]' }
    it do
      is_expected.to eq(
        '<div class="b-quote">'\
          '<div class="quoteable">[message=1 quote]3[/message]</div>'\
          'test</div>'
      )
    end
  end

  context 'comment quote' do
    let(:text) { '[quote=c1;2;3]test[/quote]' }
    it do
      is_expected.to eq(
        '<div class="b-quote">'\
          '<div class="quoteable">[comment=1 quote]3[/comment]</div>'\
          'test</div>'
      )
    end
  end

  context 'unbalanced quotes' do
    let(:text) { '[quote][quote]test[/quote]' }
    it { is_expected.to eq text }
  end
end
