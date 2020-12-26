require 'rails_helper'

RSpec.describe 'users/index', type: :view do
  before(:each) do
    # Перед каждым шагом мы пропишем в переменную @users пару пользователей,
    # имитируя действие контроллера, который эти данные будет брать из базы
    # Обратите внимание, что мы объекты в базу не кладем, т.к. пишем FactoryGirl.build_stubbed
    assign(:users, [
      FactoryGirl.build_stubbed(:user, name: 'Вадик', balance: 5000),
      FactoryGirl.build_stubbed(:user, name: 'Миша', balance: 3000),
    ])

    render
  end

  # Этот сценарий проверяет, что шаблон выводит имена игроков
  # rendered лежит то во что сложится отрисованная html страничка
  it 'renders player names' do
    expect(rendered).to match 'Вадик'
    expect(rendered).to match 'Миша'
  end

  # Этот сценарий проверяет, что шаблон выводит баланс
  it 'renders player balances' do
    expect(rendered).to match '5 000 ₽'
    expect(rendered).to match '3 000 ₽'
  end

  # Этот сценарий проверяет, что юзеры в нужном порядке
  # Проверяем, что шаблон выводит игроков в нужном порядке
  # (вообще говоря, тест избыточный, т.к. за порядок объектов в @users отвечает контроллер,
  # но чтобы показать, как тестировать порядок элементов на странице, полезно)
  it 'renders player names in right order' do
    expect(rendered).to match /Вадик.*Миша/m
  end
end