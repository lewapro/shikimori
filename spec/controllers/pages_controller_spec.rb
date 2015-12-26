describe PagesController do
  include_context :seeds
  let(:user) { create :user }

  describe 'ongoings' do
    let!(:ongoing) { create :anime, :ongoing }
    let!(:anons) { create :anime, :anons }
    let!(:topic) { create :topic, id: PagesController::ONGOINGS_TOPIC_ID }
    before { get :ongoings }

    it { expect(response).to have_http_status :success }
  end

  describe 'news' do
    context 'common' do
      let!(:topic_1) { create :topic, broadcast: true, forum: animanga_forum }
      let!(:topic_2) { create :topic, broadcast: true, forum: animanga_forum }
      before { get :news, kind: 'site', format: 'rss' }

      it do
        expect(assigns :topics).to have(2).items
        expect(response).to have_http_status :success
        expect(response.content_type).to eq 'application/rss+xml'
      end
    end

    context 'anime' do
      let!(:news_1) { create :anime_news, generated: false, forum: animanga_forum,
        linked: create(:anime), action: AnimeHistoryAction::Anons }
      let!(:news_2) { create :anime_news, generated: false, forum: animanga_forum,
        linked: create(:anime), action: AnimeHistoryAction::Anons }
      before { get :news, kind: 'anime', format: 'rss' }

      it do
        expect(assigns :topics).to have(2).items
        expect(response).to have_http_status :success
        expect(response.content_type).to eq 'application/rss+xml'
      end
    end
  end

  describe '#terms' do
    before { get :terms }
    it { expect(response).to have_http_status :success }
  end

  describe '#privacy' do
    before { get :privacy }
    it { expect(response).to have_http_status :success }
  end

  describe 'pages404' do
    before { get :page404 }
    it { should respond_with 404 }
  end

  describe 'pages503' do
    before { get :page503 }
    it { should respond_with 503 }
  end

  describe 'feedback' do
    before do
      create :user, id: 1
      create :user, id: User::GUEST_ID
      get :feedback
    end

    it { expect(response).to have_http_status :success }
  end

  describe 'admin_panel' do
    context 'guest' do
      before { get :admin_panel }
      it { should respond_with 403 }
    end

    context 'user' do
      include_context :authenticated, :user
      before { get :admin_panel }
      it { should respond_with 403 }
    end

    context 'admin' do
      include_context :authenticated, :admin

      before { allow_any_instance_of(PagesController).to receive(:`).and_return '' }
      before { allow($redis).to receive(:info).and_return('db0' => '=,') }
      before { get :admin_panel }

      it { expect(response).to have_http_status :success }
    end
  end

  describe 'about', :vcr do
    let!(:topic) { create :topic, id: PagesController::ABOUT_TOPIC_ID }
    before { Timecop.freeze '2015-11-02' }
    after { Timecop.return }

    before { get :about }

    it { expect(response).to have_http_status :success }
  end

  describe 'user_agent' do
    before { get :user_agent }
    it { expect(response).to have_http_status :success }
  end

  describe 'tableau' do
    before { get :tableau }

    it do
      expect(response.content_type).to eq 'application/json'
      expect(response).to have_http_status :success
    end
  end
end
