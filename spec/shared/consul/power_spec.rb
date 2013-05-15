require 'spec_helper'

describe Consul::Power do

  before :each do
    @user = User.create!
    @deleted_client = Client.create!(:deleted => true)
    @client1 = Client.create!
    @client1_note1 = @client1.notes.create!
    @client1_note2 = @client1.notes.create!
    @client2 = Client.create!
    @client2_note1 = @client2.notes.create!
    @client2_note2 = @client2.notes.create!
  end

  describe 'integration scenario' do

    it 'should work with real records' do
      Client.active.should == [@client1, @client2]
      @client1.notes.should == [@client1_note1, @client1_note2] 
    end

  end

  context 'nil powers' do

    describe '#include?' do

      context 'when no record is given' do

        it 'should return false' do
          @user.role = 'guest'
          @user.power.clients.should be_nil
          @user.power.clients?.should be_false
        end

      end

      context 'with a given record' do

        it 'should return false' do
          client = Client.create!
          @user.role = 'guest'
          @user.power.clients.should be_nil
          @user.power.client?(client).should be_false
        end

      end

    end

    describe '#include!' do

      context 'when no record is given' do

        it 'should raise Consul::Powerless when the power returns nil' do
          @user.role = 'guest'
          @user.power.clients.should be_nil
          expect { @user.power.clients! }.to raise_error(Consul::Powerless)
        end

      end

      context 'with a given record' do

        it 'should raise Consul::Powerless when' do
          client = Client.create!
          @user.role = 'guest'
          @user.power.clients.should be_nil
          expect { @user.power.client!(client) }.to raise_error(Consul::Powerless)
        end

      end

    end

  end

  context 'scope powers' do

    it 'should return the registered scope' do
      @user.power.clients.all.should == [@client1, @client2]
    end

    it 'should allow to register scopes with arguments' do
      @user.power.client_notes(@client1).should == [@client1_note1, @client1_note2]
    end

    describe '#include?' do

      context 'when no record is given' do

        it 'should return true if the power returns a scope (which might or might not match records)' do
          @user.power.clients?.should be_true
        end

      end

      context 'with a given record' do

        it 'should return true if the record belongs to the scope' do
          @user.power.client?(@client1).should be_true
        end

        it 'should return false if the record does not belong to the scope' do
          @user.power.client?(@deleted_client).should be_false
        end

        it 'should work with scopes that have arguments'

        it 'should only trigger a single query for multiple checks on the same scope' do
          Consul::Power::Browser.should_receive(:database_touched).once
          @user.power.client?(@client1)
          @user.power.client?(@deleted_client)
        end

        it 'should trigger a query only if the scope defines a condition' do
          Consul::Power::Browser.should_receive(:database_touched).once
          @user.power.client?(@client1)
        end

        it 'should not trigger a query if the scope defines no conditions' do
          Consul::Power::Browser.should_not_receive(:database_touched)
          @user.power.all_client?(@client1)
        end

        it 'should always trigger a query if a returned model has a default scope, even if it defines no additional conditions' do
          Consul::Power::Browser.should_receive(:database_touched).once
          @user.power.song?(Song.new)
        end

        it 'should trigger query if a returned model has a default scope and defines additional conditions' do
          Consul::Power::Browser.should_receive(:database_touched).once
          @user.power.recent_song?(Song.new)
        end

      end

    end

    describe '#include!' do

      context 'when no record is given' do

        it 'should not raise Consul::Powerless when the power returns a scope (which might or might not match records)' do
          expect { @user.power.clients! }.to_not raise_error
        end

      end

      context 'with a given record' do

        it 'should raise Consul::Powerless when record belongs is inside the scope' do
          expect { @user.power.client!(@deleted_client) }.to raise_error(Consul::Powerless)
        end

        it 'should not raise Consul::Powerless when the record is outside a scope' do
          expect { @user.power.client!(@client1) }.to_not raise_error
        end

        it 'should work with scopes that have arguments'

      end

    end

    describe 'retrieving scope_ids' do

      it 'should return record ids that match the registered scope' do
        @user.power.client_ids.should == [@client1.id, @client2.id]
      end

      it 'should cache scope ids' do
        #@user.power.should_receive_chain(:browser, :retrieve_ids).once.and_return(double('scope', :construct_finder_sql => 'SELECT 1', :to_sql => 'SELECT 1').as_null_object)
        Consul::Power::Browser.should_receive(:database_touched).once
        2.times { @user.power.client_ids }
      end

      it 'should return ids when the scope joins another table (bugfix)' do
        expect { @user.power.note_ids }.to_not raise_error
      end

    end

  end

  context 'collection powers' do

    it 'should return the registered collection' do
      @user.power.key_figures.should == %w[amount working_costs]
    end

    describe '#include?' do

      context 'when no record is given' do

        it 'should return true if the returns an enumerable (which might or might not be empty)' do
          @user.power.key_figures?.should be_true
        end

        it 'should return false if the power returns nil' do
          @user.role = 'guest'
          @user.power.key_figures.should be_nil
          @user.power.key_figures?.should be_false
        end

      end

      context 'with a given record' do

        it 'should return true if the power contains the given record' do
          @user.power.key_figure?('amount').should be_true
        end

        it 'should return false if the power does not contain the given record' do
          @user.power.key_figure?('xyz').should be_false
        end

      end

    end

    describe '#include!' do

      context 'when no record is given' do

        it 'should not raise Consul::Powerless if the power returns an enumerable (which might or might not be empty)' do
          expect { @user.power.key_figures! }.to_not raise_error
        end

        it 'should raise Consul::Powerless if the power returns nil' do
          @user.role = 'guest'
          @user.power.key_figures.should be_nil
          expect { @user.power.key_figures! }.to raise_error(Consul::Powerless)
        end

      end

      context 'with a given record' do

        it 'should not raise Consul::Powerless if the power contains the given record' do
          expect { @user.power.key_figure?('amount') }.to_not raise_error
        end

        it 'should raise Consul::Powerless if the power does not contain the given record' do
          expect { @user.power.key_figure!('xyz') }.to raise_error(Consul::Powerless)
        end
      end

    end

  end

  context 'boolean powers' do

    it 'should return the registered value' do
      @user.power.always_true.should == true
      @user.power.always_false.should == false
    end

    describe '#include?' do

      context 'when no record is given' do

        it 'should return true when the queried power returns true' do
          @user.power.always_true?.should be_true
        end

        it 'should return false when the queried power returns false' do
          @user.power.always_false?.should be_false
        end

        it 'should return false when the queried power returns nil' do
          @user.power.always_nil?.should be_false
        end

      end

      context 'with a given record' do

        it 'should raise Consul::NoCollection' do
          expect { @user.power.always_true?('foo') }.to raise_error(Consul::NoCollection)
        end

      end

    end

    describe '#include!' do

      context 'when no record is given' do

        it 'should not raise Consul::Powerless when the power returns true' do
          expect { @user.power.always_true! }.to_not raise_error
        end

        it 'should raise Consul::Powerless when the power returns false' do
          expect { @user.power.always_false! }.to raise_error(Consul::Powerless)
        end

        it 'should raise Consul::Powerless when the power returns nil' do
          expect { @user.power.always_nil! }.to raise_error(Consul::Powerless)
        end

      end

      context 'with a given record' do

        it 'should raise Consul::NoCollection' do
          expect { @user.power.always_true!('foo') }.to raise_error(Consul::NoCollection)
        end
      end

    end


  end

  context 'powers of other types' do

    it 'should return the registered value' do
      @user.power.api_key.should == 'secret-api-key'
    end

    describe '#include?' do

      context 'when no record is given' do

        it 'should return true if the power is not nil' do
          @user.power.api_key?.should be_true
        end

        it 'should return false if the power is nil' do
          @user.role = 'guest'
          @user.power.api_key.should be_nil
          @user.power.api_key?.should be_false
        end

      end

      context 'with a given record' do

        it 'should raise Consul::NoCollection' do
          expect { @user.power.api_key?('foo') }.to raise_error(Consul::NoCollection)
        end

      end

    end

    describe '#include!' do

      context 'when no record is given' do

        it 'should not raise Consul::Powerless if the power is not nil' do
          expect { @user.power.api_key! }.to_not raise_error
        end

        it 'should raise Consul::powerless if the power is nil' do
          @user.role = 'guest'
          @user.power.api_key.should be_nil
          expect { @user.power.api_key! }.to raise_error(Consul::Powerless)
        end

      end

      context 'with a given record' do

        it 'should raise Consul::NoCollection' do
          expect { @user.power.api_key!('foo') }.to raise_error(Consul::NoCollection)
        end

      end

    end

  end

  describe '.power' do

    it 'should allow to define multiple powers at once' do
      @user.power.shorthand1.should == 'shorthand'
      @user.power.shorthand2.should == 'shorthand'
      @user.power.shorthand3.should == 'shorthand'
    end

  end

  describe '.current' do

    it 'should provide a class method to set and get the current Power' do
      Power.current = 'current power'
      Power.current.should == 'current power'
      Power.current = nil
      Power.current.should be_nil
    end

  end

  describe '.with_power' do

    it 'should provide the given power as current power for the duration of the block' do
      spy = double
      inner_power = Power.new('inner')
      Power.current = 'outer power'
      spy.should_receive(:observe).with(inner_power)
      Power.with_power(inner_power) do
        spy.observe(Power.current)
      end
      Power.current.should == 'outer power'
      Power.current = nil # clean up for subsequent specs -- too bad we can't use .with_power :)
    end

    it 'should restore an existing power even if the block raises an error' do
      begin
        inner_power = Power.new('inner')
        Power.current = 'outer power'
        Power.with_power(inner_power) do
          raise ZeroDivisionError
        end
      rescue ZeroDivisionError
        # do nothing
      end
      Power.current.should == 'outer power'
      Power.current = nil # clean up for subsequent specs -- too bad we can't use .with_power :)
    end

    it 'should call instantiate a new Power if the given argument is not already a power' do
      spy = double
      Power.should_receive(:new).with('argument').and_return('instantiated power')
      spy.should_receive(:observe).with('instantiated power')
      Power.with_power('argument') do
        spy.observe(Power.current)
      end
    end

  end

  describe '#for_model' do

    it 'should return the power corresponding to the given model' do
      @user.power.for_model(Deal).should == 'deals power'
    end

    it 'should return the correct power for a namespaced model' do
      @user.power.for_model(Deal::Item).should == 'deal_items power'
    end

    it 'should allow to prefix the power with an adjective' do
      @user.power.for_model(:updatable, Deal).should == 'updatable_deals power'
    end

  end

  describe '.for_model' do

    context 'when Power.current is present' do

      it 'should return the power corresponding to the given model' do
        Power.with_power(@user.power) do
          Power.for_model(Deal).should == 'deals power'
        end
      end

      it 'should allow to prefix the power with an adjective' do
        Power.with_power(@user.power) do
          Power.for_model(:updatable, Deal).should == 'updatable_deals power'
        end
      end

    end

    context 'when Power.current is nil' do

      it 'should return the given model' do
        Power.for_model(Deal).should == Deal
      end

      it 'should return the given model even if the model was prefixed with an adjective' do
        Power.for_model(:updatable, Deal).should == Deal
      end

    end

  end

  describe '#include_model?' do

    it 'should return if the given model corresponds to a non-nil power' do
      @user.role = 'guest'
      @user.power.include_model?(Client).should be_false
      @user.role = 'admin'
      @user.power.include_model?(Client).should be_true
    end

  end

  describe '.include_model?' do

    context 'when Power.current is present' do

      it 'should return whether the given model corresponds to a non-nil power' do
        Power.with_power(@user.power) do
          @user.role = 'guest'
          Power.include_model?(Deal).should be_false
          @user.role = 'admin'
          Power.include_model?(Deal).should be_true
        end
      end
    end

    context 'when Power.current is nil' do

      it 'should return true' do
        Power.include_model?(Deal).should be_true
      end

    end

  end

  describe '#for_record' do

    it 'should return the power corresponding to the class of the given record' do
      @user.power.for_record(Deal.new).should == 'deals power'
    end

  end

  describe '.for_record' do

    context 'when Power.current is present' do

      it 'should return the power corresponding to the class of the given record' do
        Power.with_power(@user.power) do
          Power.for_record(Deal.new).should == 'deals power'
        end
      end

      it 'should allow to prefix the power with an adjective' do
        Power.with_power(@user.power) do
          Power.for_record(:updatable, Deal.new).should == 'updatable_deals power'
        end
      end

    end

    context 'when Power.current is nil' do

      it 'should return true' do
        Power.for_record(Deal.new).should == Deal
      end

      it 'should return true even if the model was prefixed with an adjective' do
        Power.for_record(:updatable, Deal.new).should == Deal
      end

    end

  end

  describe '#include_record?' do

    it 'should return if the given record is included in the power corresponding to the class of the given record' do
      @user.power.include_record?(@deleted_client).should be_false
      @user.power.include_record?(@client1).should be_true
    end

  end

  describe '.include_record?' do

    context 'when Power.current is present' do

      it 'should return whether the given record is included in the the power corresponding to the class of the given record' do
        Power.with_power(@user.power) do
          Power.include_record?(@deleted_client).should be_false
          Power.include_record?(@client1).should be_true
        end
      end
    end

    context 'when Power.current is nil' do

      it 'should return true' do
        Power.include_record?(Deal.new).should be_true
      end

    end

  end


end
