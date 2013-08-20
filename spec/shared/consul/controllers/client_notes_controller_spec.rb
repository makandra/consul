require 'spec_helper'

describe ClientNotesController, :type => :controller do

  it 'should map powers with context' do
    @client1 = Client.create!
    @client1_note1 = @client1.notes.create!
    @client2 = Client.create!
    @client2_note1 = @client2.notes.create!
    controller.stub(
      :current_power => Power.new,
      :client => @client1
    )
    controller.note_scope.to_a.should == [@client1_note1]
  end

  it 'should fail if a context is missing' do
    controller.stub(
      :current_power => Power.new,
      :client => nil
    )
    expect { controller.note_scope }.to raise_error(Consul::MissingContext)
  end

end
