# (c) goodprogrammer.ru
#
# Объявление фабрики для создания нужных в тестах объектов
#
# См. другие примеры на
#
# http://www.rubydoc.info/gems/factory_girl/file/GETTING_STARTED.md
FactoryGirl.define do
  # Фабрика, создающая юзеров
  factory :user do
    name { "Zhora_#{rand(789)}" }

    sequence(:email) { |n| "someguy#{n}@examle.com"}

    is_admin false

    balance 0

    after(:build) { |user| user.password_confirmation = user.password = "123456" }
  end
end
