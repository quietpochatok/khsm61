# Как и в любом тесте, подключаем помощник rspec-rails
require 'rails_helper'

RSpec.feature 'anon see profile users', type: :feature do
  # Готовим базу: создаём пользователя
  let(:user_another) { FactoryGirl.create :user }

  let(:user) { FactoryGirl.create(:user, name: 'Вадик', email: 'vadik10@mail.ru') }
  let!(:games) do
    [
      FactoryGirl.create(:game, user: user, id: 15, created_at: Time.zone.parse('2016.10.09, 13:00'),
                         finished_at: Time.zone.parse('2016.10.09, 13:20'), current_level: 10, prize: 1000),
      FactoryGirl.create(:game, user: user, id: 30, created_at: Time.zone.parse('2020.12.01, 12:00'),
                         finished_at: Time.zone.parse('2020.12.01, 12:30'), current_level: 12, prize: 10_000),
    ]
  end

  before(:each) do
    login_as user_another
  end

  scenario 'user visit page profile another user' do
    visit "/"
    click_link "Вадик"

    expect(page).to have_current_path "/users/#{user.id}"
    expect(page).to have_content('Вадик')

    expect(page).not_to have_button('Сменить имя и пароль')
    expect(page).to have_no_content('Сменить имя и пароль')

    expect(page).to have_content '15'
    expect(page).to have_content '09 окт., 13:00'
    expect(page).to have_content 'деньги'
    expect(page).to have_content '10'
    expect(page).to have_content '1 000 ₽'

    expect(page).to have_content '30'
    expect(page).to have_content '01 дек., 12:00'
    expect(page).to have_content 'деньги'
    expect(page).to have_content '12'
    expect(page).to have_content '10 000 ₽'

    save_and_open_page
  end
end