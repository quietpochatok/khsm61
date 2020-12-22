# (c) goodprogrammer.ru

# Стандартный rspec-овский помощник для rails-проекта
require 'rails_helper'

# Наш собственный класс с вспомогательными методами
require 'support/my_spec_helper'

# Тестовый сценарий для модели Игры
#
# В идеале — все методы должны быть покрыты тестами, в этом классе содержится
# ключевая логика игры и значит работы сайта.
RSpec.describe Game, type: :model do
  # Пользователь для создания игр
  let(:user) { FactoryGirl.create(:user) }

  # Игра с прописанными игровыми вопросами
  let(:game_w_questions) do
    FactoryGirl.create(:game_with_questions, user: user)
  end

  # Группа тестов на работу фабрики создания новых игр
  context 'Game Factory' do
    it 'Game.create_game! new correct game' do
      # Генерим 60 вопросов с 4х запасом по полю level, чтобы проверить работу
      # RANDOM при создании игры.
      generate_questions(60)

      game = nil

      # Создaли игру, обернули в блок, на который накладываем проверки
      expect {
        game = Game.create_game_for_user!(user)
        # Проверка: Game.count изменился на 1 (создали в базе 1 игру)
      }.to change(Game, :count).by(1).and(
        # GameQuestion.count +15
        change(GameQuestion, :count).by(15).and(
          # Game.count не должен измениться
          change(Question, :count).by(0)
        )
      )

      # Проверяем статус и поля
      expect(game.user).to eq(user)
      expect(game.status).to eq(:in_progress)

      # Проверяем корректность массива игровых вопросов
      expect(game.game_questions.size).to eq(15)
      expect(game.game_questions.map(&:level)).to eq (0..14).to_a
    end
  end

  # Тесты на основную игровую логику
  context 'game mechanics' do
    # Правильный ответ должен продолжать игру
    it 'answer correct continues game' do
      # Текущий уровень игры и статус
      level = game_w_questions.current_level
      q = game_w_questions.current_game_question
      expect(game_w_questions.status).to eq(:in_progress)

      game_w_questions.answer_current_question!(q.correct_answer_key)

      # Перешли на след. уровень
      expect(game_w_questions.current_level).to eq(level + 1)

      # Ранее текущий вопрос стал предыдущим
      expect(game_w_questions.current_game_question).not_to eq(q)

      # Игра продолжается
      expect(game_w_questions.status).to eq(:in_progress)
      expect(game_w_questions.finished?).to be_falsey
    end

    it 'take_money! finished game' do
      # Метод current_game_question возвращает текущий, еще неотвеченный вопрос игры
      q = game_w_questions.current_game_question
      game_w_questions.answer_current_question!(q.correct_answer_key)
      game_w_questions.take_money!

      prize_after_take_money = game_w_questions.prize
      expect(prize_after_take_money).to be > 0

      expect(game_w_questions.status).to eq :money
      expect(game_w_questions.finished?).to be_truthy
      expect(user.balance).to eq prize_after_take_money
    end
  end

  # группа тестов на проверку статуса игры
  context '#status' do
    # перед каждым тестом "завершаем игру"
    before(:each) do
      game_w_questions.finished_at = Time.now
      expect(game_w_questions.finished?).to be_truthy
    end

    it 'user won' do
      game_w_questions.current_level = Question::QUESTION_LEVELS.max + 1
      expect(game_w_questions.status).to eq :won
    end

    it "user fail" do
      game_w_questions.is_failed = true
      expect(game_w_questions.status).to eq :fail
    end

    it "user timeout " do
      game_w_questions.created_at = 1.hour.ago
      game_w_questions.is_failed = true
      expect(game_w_questions.status).to eq :timeout
    end

    it 'user won' do
      expect(game_w_questions.status).to eq :money
    end
  end

  # тест на возвращение вопроса, что не отвечен.
  describe '#current_game_question' do
    it 'return question without answer' do
      expect(game_w_questions.current_game_question).
        to eq game_w_questions.game_questions.first
    end
  end

  # тест возвращает число, равное предыдущему уровню сложности.
  describe '#previous_level' do
    it 'return previous level game' do
      expect(game_w_questions.previous_level).to eq(-1)
    end
  end

  # группа тестов на метод answer_current_question,
  # где ответ правильный/неправильный/отдан после истечения времени.
  describe '#answer_current_question!' do
    let(:question_with_answers) { game_w_questions.current_game_question }
    let(:wrong_answer) { %w[a b c d].reject { |answer| answer == question_with_answers.correct_answer_key}.sample }

    context 'when the answer is correct' do
      it 'return true if answer is correct' do
        q = game_w_questions.current_game_question
        expect(game_w_questions.answer_current_question!(q.correct_answer_key)).to be true
        expect(game_w_questions.finished?).to be false
        expect(game_w_questions.status).to eq :in_progress
      end
    end

    context "when the answer is not correct" do
      it 'return false not correct answer' do
        q = game_w_questions.current_game_question
        expect(game_w_questions.answer_current_question!(wrong_answer)).to be false
        expect(game_w_questions.finished?).to be true
        expect(game_w_questions.status).to eq :fail
      end
    end

    context "when the answer is given after the time for answer" do
      it 'return false on  is timeout' do
        game_w_questions.created_at = 1.hour.ago
        q = game_w_questions.current_game_question
        expect(game_w_questions.answer_current_question!(q.correct_answer_key)).to be false
        expect(game_w_questions.finished?).to be true
        expect(game_w_questions.status).to eq :timeout
      end
    end
  end
end
