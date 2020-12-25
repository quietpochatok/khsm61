# (c) goodprogrammer.ru

require 'rails_helper'

# Тестовый сценарий для модели игрового вопроса, в идеале весь наш функционал
# (все методы) должны быть протестированы.
RSpec.describe GameQuestion, type: :model do
  # Задаем локальную переменную game_question, доступную во всех тестах этого
  # сценария: она будет создана на фабрике заново для каждого блока it,
  # где она вызывается.
  let(:game_question) do
    FactoryGirl.create(:game_question, a: 2, b: 1, c: 4, d: 3)
  end

  # Группа тестов на игровое состояние объекта вопроса
  context 'game status' do
    # Тест на правильную генерацию хэша с вариантами
    it 'correct .variants' do
      expect(game_question.variants).to eq(
        'a' => game_question.question.answer2,
        'b' => game_question.question.answer1,
        'c' => game_question.question.answer4,
        'd' => game_question.question.answer3
      )
    end

    it 'correct .answer_correct?' do
      # Именно под буквой b в тесте мы спрятали указатель на верный ответ
      expect(game_question.answer_correct?('b')).to be_truthy
    end

    # тест на наличие методов делегатов level и text
    it 'correct .level & .text delegates' do
      expect(game_question.text).to eq game_question.question.text
      expect(game_question.level).to eq game_question.question.level
    end

    # тест на возвращение правильного ключа из метода
    describe '#correct_answer_key' do
      it 'return correct answer' do
        expect(game_question.correct_answer_key).to eq('b')
      end
    end
  end

  # help_hash у нас имеет такой формат:
  # {
  #   fifty_fifty: ['a', 'b'], # При использовании подсказски остались варианты a и b
  #   audience_help: {'a' => 42, 'c' => 37 ...}, # Распределение голосов по вариантам a, b, c, d
  #   friend_call: 'Василий Петрович считает, что правильный ответ A'
  # }

  context 'user helpers' do
    it 'correct audience_help' do
      expect(game_question.help_hash).not_to include(:audience_help)

      game_question.add_audience_help

      expect(game_question.help_hash).to include(:audience_help)

      audience_help_value = game_question.help_hash[:audience_help]
      expect(audience_help_value.keys).to contain_exactly('a', 'b', 'c', 'd')
    end

    it 'correct friend_call' do
      expect(game_question.help_hash).not_to include(:friend_call)

      # вызовем подсказку
      game_question.add_friend_call

      # проверим создание подсказки
      expect(game_question.help_hash).to include(:friend_call)
      friend_call_value = game_question.help_hash[:friend_call]

      # проверяем наличие текста, а также вариант ответа.
      #expect(friend_call_value).to include(GameHelpGenerator.friend_call(['a', 'b', 'c', 'd'], game_question.correct_answer_key))
      expect(friend_call_value).to include('считает, что это вариант')
      expect(friend_call_value).to match(/[ABCD]+/)
    end

    # проверяем работу подсказкки 50/50
    it 'correct fifty_fifty' do
      # сначала убедимся, в подсказках пока нет нужного ключа
      expect(game_question.help_hash).not_to include(:fifty_fifty)

      # вызовем подсказку
      game_question.add_fifty_fifty

      # проверим создание подсказки
      expect(game_question.help_hash).to include(:fifty_fifty)
      fifty_fifty_value = game_question.help_hash[:fifty_fifty]

      # должен быть и остаться правильный ответ
      # для наших тестов формально это b
      expect(fifty_fifty_value).to include('b')
      # всего должно остаться 2 варианта
      expect(fifty_fifty_value.size).to eq(2)
    end

    # it 'correct .help_hash' do
    #   # на фабрике у нас изначально хэш пустой
    #   expect(game_question.help_hash).to be({})
    #
    #   game_question.help_hash[:fifty_fifty] = %w[a b]
    #   expect(game_question.save).to be_truthy
    #   gq_check = GameQuestion.find(game_question.id)
    #   expect(gq_check.help_hash).to eq( { fifty_fifty: %w[a b] } )
    #  !
    #   !выкидывает забавный эксепшон при прогонке, спросить у менторов
    # !
    # end

    it 'correct .help_hash' do
      # на фабрике у нас изначально хэш пустой
      expect(game_question.help_hash).to eq({})

      # добавляем пару ключей
      game_question.help_hash[:some_key1] = 'blabla1'
      game_question.help_hash['some_key2'] = 'blabla2'

      # сохраняем модель и ожидаем сохранения хорошего
      expect(game_question.save).to be_truthy

      # загрузим этот же вопрос из базы для чистоты эксперимента
      gq = GameQuestion.find(game_question.id)

      # проверяем новые значение хэша
      expect(gq.help_hash).to eq({some_key1: 'blabla1', 'some_key2' => 'blabla2'})
    end
  end
end


