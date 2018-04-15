require_relative '../../../app/api'
require 'rack/test'

module ExpenseTracker
  RecordResult = Struct.new(:success?, :expense_id, :error_message)

  RSpec.describe API do
    include Rack::Test::Methods

    def app
      API.new(ledger: ledger)
    end

    def expect_parsed(matcher)
      parsed = JSON.parse(last_response.body)
      expect(parsed).to matcher
    end

    let(:ledger) { instance_double('ExpenseTracker::Ledger') }

    describe 'GET /expenses/:date' do
      let(:ok_date) { '2018-04-15' }
      let(:none_date) { '2018-04-16' }

      before do
        allow(ledger).to receive(:expenses_on)
          .with(ok_date)
          .and_return([417])
        allow(ledger).to receive(:expenses_on)
          .with(none_date)
          .and_return([])
      end

      context 'when expenses exist on the given date' do
        it 'returns the expense records as JSON' do
          get "/expenses/#{ok_date}"

          expect_parsed eq([417])
        end

        it 'responds with a 200 (OK)' do
          get "/expenses/#{ok_date}"
          expect(last_response.status).to eq(200)
        end
      end

      context 'when there are no expenses on the given date' do
        it 'returns an empty array as JSON' do
          get "/expenses/#{none_date}"

          expect_parsed be_empty
        end

        it 'responds with a 200 (OK)' do
          get "/expenses/#{none_date}"
          expect(last_response.status).to be(200)
        end
      end
    end

    describe 'POST /expenses' do
      context 'when the expense is successfully recorded' do
        let(:expense) { { 'some' => 'data' } }

        before do
          allow(ledger).to receive(:record)
            .with(expense)
            .and_return(RecordResult.new(true, 417, nil))
        end

        it 'returns the expense id' do
          post '/expenses', JSON.generate(expense)

          expect_parsed include('expense_id' => 417)
        end

        it 'responds with a 200 (OK)' do
          post '/expenses', JSON.generate(expense)
          expect(last_response.status).to eq(200)
        end
      end

      context 'when the expense fails validation' do
        let(:expense) { { 'some' => 'data' } }

        before do
          allow(ledger).to receive(:record)
            .with(expense)
            .and_return(RecordResult.new(false, 417, 'Expense incomplete'))
        end

        it 'returns an error message' do
          post '/expenses', JSON.generate(expense)

          expect_parsed include('error' => 'Expense incomplete')
        end

        it 'responds with a 422 (Unprocessable entity)' do
          post '/expenses', JSON.generate(expense)
          expect(last_response.status).to eq(422)
        end
      end
    end
  end
end
