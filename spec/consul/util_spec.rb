require 'spec_helper'

describe Consul::Util do

  describe '.adjective_and_argument' do

    it 'should return [nil, argument] if given a single argument' do
      Consul::Util.adjective_and_argument(Deal).should == [nil, Deal]
    end

    it 'should return [adjective, argument] if given an adjective and an argument' do
      Consul::Util.adjective_and_argument('updatable', Deal).should == ['updatable', Deal]
    end

  end

end