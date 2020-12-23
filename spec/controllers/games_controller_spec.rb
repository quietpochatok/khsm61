require 'rails_helper'
# Сразу подключим наш модуль с вспомогательными методами
require 'support/my_spec_helper'

RSpec.describe GamesController, type: :controller do
  # обычный пользователь
  let(:user) { FactoryGirl.create(:user) }
  # админ
  let(:admin) { FactoryGirl.create(:user, is_admin: true) }
  # игра с прописанными игровыми вопросами  и !юзером!
  let(:game_w_questions) { FactoryGirl.create(:game_with_questions, user: user) }

  # создаем новую игру, юзер не прописан, будет создан фабрикой новый
  let(:alien_game) { FactoryGirl.create(:game_with_questions) }

  context 'Anon try used action method cont-r Games' do
    # Аноним не может смотреть игру
    it 'kicks from #show' do
      # Вызываем экшен
      get :show, id: game_w_questions.id
      # Проверяем ответ
      # статус ответа не равен 200
      expect(response.status).not_to eq(200)
      # Devise должен отправить на логин
      expect(response).to redirect_to(new_user_session_path)
      # Во flash должно быть сообщение об ошибке
      expect(flash[:alert]).to be
    end

    # Аноним не может создать игру
    it 'kicks from #create' do
      # Создадим пачку вопросов
      generate_questions(15)

      # Вызываем экшен
      post :create

      # Вытаскиваем из контроллера поле @game
      game = assigns(:game)

      # Игра неt
      expect(game).to be_nil

      # Проверяем ответ
      # статус ответа не равен 200
      expect(response.status).not_to eq(200)
      # Devise должен отправить на логин
      expect(response).to redirect_to(new_user_session_path)
      # Во flash должно быть сообщение об ошибке
      expect(flash[:alert]).to be
    end

    # Аноним не может дать ответ
    it 'not #answers for anon' do
      # Дёргаем экшен answer, передаем параметр params[:letter]
      put :answer, id: game_w_questions.id, letter: game_w_questions.current_game_question.correct_answer_key

      # Вытаскиваем из контроллера поле @game
      game = assigns(:game)

      # Игра неt
      expect(game).to be_nil

      # Проверяем ответ
      # статус ответа не равен 200
      expect(response.status).not_to eq(200)
      # Редирект на страницу игры
      expect(response).to redirect_to(new_user_session_path)
      # Во flash должно быть сообщение об ошибке
      expect(flash[:alert]).to be
    end

    #Аноним не может забрать деньги
    it 'not #take_money for anon' do
      # Дёргаем экшен answer, передаем параметр params[:letter]
      put :take_money, id: game_w_questions.id

      # Вытаскиваем из контроллера поле @game
      game = assigns(:game)

      # Игра неt
      expect(game).to be_nil

      # Проверяем ответ
      # статус ответа не равен 200
      expect(response.status).not_to eq(200)
      # Редирект на страницу игры
      expect(response).to redirect_to(new_user_session_path)
      # Во flash должно быть сообщение об ошибке
      expect(flash[:alert]).to be
    end
  end

  # группа тестов на экшены контроллера, доступных залогиненным юзерам
  context 'Usual user' do
    # перед каждым тестом в группе
    before(:each) { sign_in user } # логиним юзера user с помощью спец. Devise метода sign_in

    it 'creates game' do
      # Создадим пачку вопросов
      generate_questions(15)

      # Экшен create у нас отвечает на запрос POST
      post :create

      # Вытаскиваем из контроллера поле @game
      game = assigns(:game)

      # Проверяем состояние этой игры: она не закончена
      # Юзер должен быть именно тот, которого залогинили
      expect(game.finished?).to be false
      # У игры назначен юзер
      expect(game.user).to eq(user)

      # Проверяем, есть ли редирект на страницу этой игры
      # И есть ли сообщение об этом
      expect(response).to redirect_to(game_path(game))
      expect(flash[:notice]).to be
    end

    it '#show game' do
      # Показываем по GET-запросу
      get :show, id: game_w_questions.id
      # Вытаскиваем из контроллера поле @game
      game = assigns(:game)
      # Игра не закончена
      expect(game.finished?).to be_falsey
      # Юзер именно тот, которого залогинили
      expect(game.user).to eq(user)

      # Проверяем статус ответа (200 ОК)
      expect(response.status).to eq(200)
      # Проверяем рендерится ли шаблон show (НЕ сам шаблон!)
      expect(response).to render_template('show')
    end

    # Тест проверяет поведение контроллера, если юзер ответил
    # на вопрос верно
    it 'answers correct' do
      # Дёргаем экшен answer, передаем параметр params[:letter]
      put :answer, id: game_w_questions.id, letter: game_w_questions.current_game_question.correct_answer_key
      # Вытаскиваем из контроллера поле @game
      game = assigns(:game)

      # Игра не закончена
      expect(game.finished?).to be_falsey
      # Уровень больше 0
      expect(game.current_level).to be > 0

      # Редирект на страницу игры
      expect(response).to redirect_to(game_path(game))
      # Флеш пустой
      expect(flash.empty?).to be_truthy # удачный ответ не заполняет flash
    end

    # юзер берет деньги
    it 'takes money' do
      # вручную поднимем уровень вопроса до выигрыша 200
      game_w_questions.update_attribute(:current_level, 2)

      put :take_money, id: game_w_questions.id
      game = assigns(:game)
      expect(game.finished?).to be_truthy
      expect(game.prize).to eq(200)

      # пользователь изменился в базе, надо в коде перезагрузить!
      user.reload
      expect(user.balance).to eq(200)

      expect(response).to redirect_to(user_path(user))
      expect(flash[:warning]).to be
    end

    # юзер пытается создать новую игру, не закончив старую
    it 'try to create second game' do
      # убедились что есть игра в работе
      expect(game_w_questions.finished?).to be false

      # отправляем запрос на создание, убеждаемся что новых Game не создалось
      expect { post :create }.to change(Game, :count).by(0)

      # вытаскиваем из контроллера поле @game
      game = assigns(:game)
      expect(game).to be_nil

      expect(response).to redirect_to(game_path(game_w_questions))
      expect(flash[:alert]).to be
    end

    # проверка, что пользовтеля посылают из чужой игры
    it '#show alien game' do
      # пробуем зайти на эту игру текущий залогиненным user
      get :show, id: alien_game.id

      expect(response.status).not_to eq(200) # статус не 200 ОК
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to be # во flash должен быть прописана ошибка
    end
  end
end