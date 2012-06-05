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

  describe 'example scenario' do

    it 'should work as expected' do
      Client.active.should == [@client1, @client2]
      @client1.notes.should == [@client1_note1, @client1_note2] 
    end

  end

  describe 'scope methods' do

    it 'should return the registered scope' do
      @user.power.clients.all.should == [@client1, @client2]
    end

    it 'should allow to register scopes with arguments' do
      @user.power.client_notes(@client1).should == [@client1_note1, @client1_note2]
    end

  end

  describe 'scope_ids methods' do

    it 'should return record ids that match the registered scope' do
      @user.power.client_ids.should == [@client1.id, @client2.id]
    end

    it 'should cache scope ids' do
      @user.power.should_receive(:clients).once.and_return(double('scope', :construct_finder_sql => 'SELECT 1').as_null_object)
      2.times { @user.power.client_ids }
    end

    it 'should return ids when the scope joins another table (bugfix)' do
      expect { @user.power.note_ids }.to_not raise_error
    end

  end

  describe 'include?' do

    it 'should return true if a given record belongs to a scope' do
      @user.power.client?(@client1).should be_true
    end

    it 'should return false if a given record does not belong to a scope' do
      @user.power.client?(@deleted_client).should be_false
    end

    it 'should only trigger a single query for multiple checks on the same scope' do
      ActiveRecord::Base.connection.should_receive(:select_values).once.and_return([]) #.and_return(double('connection').as_null_object)
      @user.power.client?(@client1)
      @user.power.client?(@deleted_client)
    end

    it 'should return true when the queried power returns a scope (which might or might not match records)' do
      @user.power.clients?.should be_true
    end

    it 'should return true when the queried power is not a scope, but returns true' do
      @user.power.always_true?.should be_true
    end

    it 'should return false when the queried power is not a scope, but returns false' do
      @user.power.always_false?.should be_false
    end

    it 'should return false when the queried power is not a scope, but returns nil' do
      @user.power.always_nil?.should be_false
    end

  end

  describe 'include!' do

    it 'should raise Consul::Powerless when the given record belongs to a scope' do
      expect { @user.power.client!(@deleted_client) }.to raise_error(Consul::Powerless)
    end

    it 'should not raise Consul::Powerless when the given record does not belong to a scope' do
      expect { @user.power.client!(@client1) }.to_not raise_error
    end

    it 'should not raise Consul::Powerless when the queried power returns a scope (which might or might not match records)' do
      expect { @user.power.clients! }.to_not raise_error
    end

    it 'should not raise Consul::Powerless when the queried power is not a scope, but returns true' do
      expect { @user.power.always_true! }.to_not raise_error
    end

    it 'should raise Consul::Powerless when the queried power is not a scope, but returns false' do
      expect { @user.power.always_false! }.to raise_error(Consul::Powerless)
    end

    it 'should raise Consul::Powerless when the queried power is not a scope, but returns nil' do
      expect { @user.power.always_nil! }.to raise_error(Consul::Powerless)
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

end
