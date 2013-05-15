require 'spec_helper'

describe Consul::Power::Name do

  let :member_definition do
    Consul::Power::Name.new(:post?)
  end

  let :collection_definition do
    Consul::Power::Name.new(:posts)
  end

  describe '#member_name' do

    it 'should return the correct name for a member definition' do
      member_definition.member_name.should == 'post'
    end

    it 'should return the correct name for a collection definition' do
      collection_definition.member_name.should == 'post'
    end

  end

  describe '#collection_name' do

    it 'should return the correct name for a member definition' do
      member_definition.collection_name.should == 'posts'
    end

    it 'should return the correct name for a collection definition' do
      collection_definition.collection_name.should == 'posts'
    end

  end

  describe '#ids_name' do

    it 'should return the correct name for a member definition' do
      member_definition.ids_name.should == 'post_ids'
    end

    it 'should return the correct name for a collection definition' do
      collection_definition.ids_name.should == 'post_ids'
    end

  end

end
