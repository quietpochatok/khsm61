require 'rails_helper'

# Тест на шаблон users/show.html.erb
RSpec.describe 'users/show', type: :view do
  let(:user) { create(:user, name: 'Вадик', balance: 5000) }
  let(:game) { build_stubbed(:game, id: 15, created_at: Time.now, current_level: 10, prize: 1000) }

  context 'user/anon see page another user' do
    before(:each) do
      # Подготовим объект user  для использования в тестах, где он понадобится
      # !build_stubbed! не создает объект в базе, будьте аккуратнее
      assign(:user, build_stubbed(:user, name: 'Вадик', balance: 5000))
      assign(:game, game)
      render
    end

    it 'user/anon not see change name and password' do
      expect(rendered).not_to match 'Сменить имя и пароль'
    end

    it 'user/anon player name' do
      expect(rendered).to match 'Вадик'
    end

    it 'render partial _game' do
      render_template(partial:'_game')
    end
  end

  context 'sing_in user see self page profile' do
    # перед каждым тестом в группе
    before(:each) do
      assign(:user, user)
      assign(:game, game)

      sign_in user
      render
    end

    it 'sing_in user see change name and password' do
      expect(rendered).to match 'Сменить имя и пароль'
    end

    it 'sing_in user player name' do
      expect(rendered).to match 'Вадик'
    end

    it 'sing_in user render partial _game' do
      render_template(partial:'_game')
    end
  end
end