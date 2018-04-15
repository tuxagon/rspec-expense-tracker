require 'sinatra/base'
require 'json'

module ExpenseTracker
  class API < Sinatra::Base
    get '/expenses/:date' do
      JSON.generate([])
    end

    post '/expenses' do
      JSON.generate('expense_id' => 42)
    end
  end
end
