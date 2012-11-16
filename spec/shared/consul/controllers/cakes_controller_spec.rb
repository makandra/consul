require 'spec_helper'

describe CakesController, :type => :controller do

  describe '#show' do
    it 'should get the power :cakes' do
      controller.should_receive(:observe_end_of_association_chain).with(:cakes)
      get :show, :id => 'id'
    end
  end

  describe '#index' do
    it 'should get the power :cakes' do
      controller.should_receive(:observe_end_of_association_chain).with(:cakes)
      get :index
    end
  end

  describe '#new' do
    it 'should get the power :creatable_cakes' do
      controller.should_receive(:observe_end_of_association_chain).with(:creatable_cakes)
      get :new
    end
  end

  describe '#creatable' do
    it 'should get the power :creatable_cakes' do
      controller.should_receive(:observe_end_of_association_chain).with(:creatable_cakes)
      post :create
    end
  end

  describe '#edit' do
    it 'should get the power :updatable_cakes' do
      controller.should_receive(:observe_end_of_association_chain).with(:updatable_cakes)
      get :edit, :id => 'id'
    end
  end

  describe '#update' do
    it 'should get the power :updatable_cakes' do
      controller.should_receive(:observe_end_of_association_chain).with(:updatable_cakes)
      put :update, :id => 'id'
    end
  end

  describe '#destroy' do
    it 'should get the power :destroyable_cakes' do
      controller.should_receive(:observe_end_of_association_chain).with(:destroyable_cakes)
      delete :destroy, :id => '1'
    end
  end

  describe '#custom_action' do
    it 'should get the power :cakes' do
      controller.should_receive(:observe_end_of_association_chain).with(:cakes)
      get :custom_action, :id => '1'
    end
  end

end