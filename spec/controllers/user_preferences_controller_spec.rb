describe UserPreferencesController do
  let(:user) { seed :user }

  describe '#update' do
    let(:make_request) { patch :update, profile_id: user.to_param,
      page: 'profile', user: user_params, user_preferences: preferences_params }
    let(:user_params) { nil }
    let(:preferences_params) {{ body_background: 'test2' }}

    context 'when invalid access' do
      it { expect{make_request}.to raise_error CanCan::AccessDenied }
    end

    context 'when valid access' do
      before { sign_in user }

      context 'post request' do
        before { make_request }
        it do
          expect(resource.preferences.body_background).to eq preferences_params[:body_background]
          expect(response).to redirect_to edit_profile_url(user, page: :profile)
        end
      end

      context 'xhr request' do
        before do
          xhr :put, :update, profile_id: user.to_param,
            user_preferences: { forums: ['vn'] }
        end

        it do
          expect(resource.preferences.forums).to eq ['vn']
          expect(response).to be_success
        end
      end

      context 'user changes' do
        let(:user_params) {{ about: 'zxc' }}
        before { make_request }

        it do
          expect(resource.about).to eq user_params[:about]
          expect(response).to redirect_to edit_profile_url(user, page: :profile)
        end
      end

      context 'invalid change' do
        let(:preferences_params) {{ body_width: 'x1201' }}
        before { make_request }

        it do
          expect(resource.preferences).to_not be_valid
          expect(response).to render_template :edit
        end
      end
    end
  end
end
